
from decimal import Decimal, ROUND_HALF_UP

from Backend.config.db import get_db_connection


MONEY_PLACES = Decimal("0.01")


def create_transaction_atomic(
    shop_id,
    customer_id,
    transaction_type,
    items,
    amount_paid,
    payment_method=None
):
    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        # --------------------------------------------------
        # 1. Lock the customer's account.
        # Prevent simultaneous transactions from overwriting
        # each other's balance updates.
        # --------------------------------------------------

        account_query = """
            SELECT account_id, current_balance
            FROM customer_accounts
            WHERE shop_id = %s
              AND customer_id = %s
            FOR UPDATE
        """

        cursor.execute(account_query, (shop_id, customer_id))
        account = cursor.fetchone()

        if not account:
            raise ValueError("Customer account not found in this shop")

        account_id = account["account_id"]
        previous_balance = Decimal(str(account["current_balance"]))

        # --------------------------------------------------
        # 2. Prepare purchase items using database prices.
        # --------------------------------------------------

        prepared_items = []
        purchase_total = Decimal("0.00")

        if transaction_type == "purchase":

            if not items:
                raise ValueError("A purchase must contain at least one item")

            for item in items:

                product_name = item["product_name"]
                quantity = Decimal(str(item["quantity"]))
                requested_unit = item["unit"]

                product_query = """
                    SELECT product_id, product_name, unit, unit_price
                    FROM products
                    WHERE shop_id = %s
                      AND LOWER(TRIM(product_name)) =
                          LOWER(TRIM(%s))
                      AND is_active = TRUE
                    FOR UPDATE
                """

                cursor.execute(
                    product_query,
                    (shop_id, product_name)
                )

                product = cursor.fetchone()

                if not product:
                    raise ValueError(
                        f"Product '{product_name}' was not found or is inactive"
                    )

                if product["unit"].strip().lower() != requested_unit.strip().lower():
                    raise ValueError(
                        f"Unit mismatch for {product['product_name']}. "
                        f"Expected {product['unit']}"
                    )

                unit_price = Decimal(str(product["unit_price"]))

                subtotal = (quantity * unit_price).quantize(
                    MONEY_PLACES,
                    rounding=ROUND_HALF_UP
                )

                purchase_total += subtotal

                prepared_items.append({
                    "product_id": product["product_id"],
                    "product_name": product["product_name"],
                    "quantity": quantity,
                    "unit": product["unit"],
                    "unit_price": unit_price,
                    "subtotal": subtotal
                })

            purchase_total = purchase_total.quantize(MONEY_PLACES)

            if purchase_total <= 0:
                raise ValueError("Purchase total must be greater than zero")

        elif transaction_type == "repayment":

            if items:
                raise ValueError("Repayment transactions cannot contain products")

            if amount_paid <= 0:
                raise ValueError("Repayment amount must be greater than zero")

            purchase_total = amount_paid

        else:
            raise ValueError("Invalid transaction type")

        # --------------------------------------------------
        # 3. Calculate the new balance.
        # --------------------------------------------------

        if transaction_type == "purchase":

            new_balance = (
                previous_balance + purchase_total - amount_paid
            )

        else:

            new_balance = previous_balance - amount_paid

        new_balance = new_balance.quantize(MONEY_PLACES)

        # --------------------------------------------------
        # 4. Insert the transaction.
        # --------------------------------------------------

        transaction_query = """
            INSERT INTO transactions
            (shop_id, customer_id, transaction_type, total_amount, status)
            VALUES (%s, %s, %s, %s, 'confirmed')
        """

        cursor.execute(
            transaction_query,
            (
                shop_id,
                customer_id,
                transaction_type,
                purchase_total
            )
        )

        transaction_id = cursor.lastrowid

        # --------------------------------------------------
        # 5. Insert purchase items.
        # --------------------------------------------------

        if transaction_type == "purchase":

            item_query = """
                INSERT INTO transaction_items
                (
                    transaction_id,
                    product_id,
                    product_name,
                    quantity,
                    unit,
                    unit_price,
                    subtotal
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """

            for item in prepared_items:

                cursor.execute(
                    item_query,
                    (
                        transaction_id,
                        item["product_id"],
                        item["product_name"],
                        item["quantity"],
                        item["unit"],
                        item["unit_price"],
                        item["subtotal"]
                    )
                )

        # --------------------------------------------------
        # 6. Record payment, if any.
        # --------------------------------------------------

        payment_id = None

        if amount_paid > 0:

            payment_query = """
                INSERT INTO payments
                (transaction_id, customer_id, amount, payment_method)
                VALUES (%s, %s, %s, %s)
            """

            cursor.execute(
                payment_query,
                (
                    transaction_id,
                    customer_id,
                    amount_paid,
                    payment_method
                )
            )

            payment_id = cursor.lastrowid

        # --------------------------------------------------
        # 7. Insert ledger entries.
        # --------------------------------------------------

        ledger_query = """
            INSERT INTO account_ledger
            (
                account_id,
                transaction_id,
                payment_id,
                entry_type,
                debit,
                credit,
                balance_after
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """

        if transaction_type == "purchase":

            # Purchase increases the amount owed.
            balance_after_purchase = (
                previous_balance + purchase_total
            ).quantize(MONEY_PLACES)

            cursor.execute(
                ledger_query,
                (
                    account_id,
                    transaction_id,
                    None,
                    "purchase",
                    purchase_total,
                    Decimal("0.00"),
                    balance_after_purchase
                )
            )

            # Payment reduces the amount owed.
            if amount_paid > 0:

                cursor.execute(
                    ledger_query,
                    (
                        account_id,
                        transaction_id,
                        payment_id,
                        "payment",
                        Decimal("0.00"),
                        amount_paid,
                        new_balance
                    )
                )

        else:

            # Repayment reduces the amount owed.
            cursor.execute(
                ledger_query,
                (
                    account_id,
                    transaction_id,
                    payment_id,
                    "repayment",
                    Decimal("0.00"),
                    amount_paid,
                    new_balance
                )
            )

        # --------------------------------------------------
        # 8. Update customer account balance.
        # --------------------------------------------------

        update_query = """
            UPDATE customer_accounts
            SET current_balance = %s
            WHERE account_id = %s
        """

        cursor.execute(
            update_query,
            (new_balance, account_id)
        )

        # --------------------------------------------------
        # 9. Commit all operations together.
        # --------------------------------------------------

        connection.commit()

        return {
            "transaction_id": transaction_id,
            "customer_id": customer_id,
            "account_id": account_id,
            "transaction_type": transaction_type,
            "total_amount": str(purchase_total),
            "amount_paid": str(amount_paid),
            "previous_balance": str(previous_balance),
            "current_balance": str(new_balance),
            "payment_id": payment_id,
            "message": "Transaction recorded successfully"
        }

    except Exception:
        if connection:
            connection.rollback()
        raise

    finally:
        if cursor:
            cursor.close()

        if connection and connection.is_connected():
            connection.close()

def get_transactions_by_shop(shop_id):

    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        # 1. Fetch confirmed transactions and customer names.
        transaction_query = """
            SELECT
                t.transaction_id,
                t.shop_id,
                t.customer_id,
                c.customer_name,
                t.transaction_type,
                t.total_amount,
                t.status,
                t.created_at
            FROM transactions t
            INNER JOIN customers c
                ON t.customer_id = c.customer_id
               AND t.shop_id = c.shop_id
            WHERE t.shop_id = %s
              AND t.status = 'confirmed'
            ORDER BY t.created_at DESC, t.transaction_id DESC
        """

        cursor.execute(transaction_query, (shop_id,))
        transactions = cursor.fetchall()

        if not transactions:
            return []

        # 2. Collect transaction IDs.
        transaction_ids = [
            transaction["transaction_id"]
            for transaction in transactions
        ]

        placeholders = ", ".join(["%s"] * len(transaction_ids))

        # 3. Fetch purchase items for these transactions.
        items_query = f"""
            SELECT
                ti.transaction_id,
                ti.product_name,
                ti.quantity,
                ti.unit,
                ti.unit_price,
                ti.subtotal
            FROM transaction_items ti
            INNER JOIN transactions t
                ON ti.transaction_id = t.transaction_id
            WHERE t.shop_id = %s
              AND ti.transaction_id IN ({placeholders})
            ORDER BY ti.item_id ASC
        """

        cursor.execute(
            items_query,
            (shop_id, *transaction_ids)
        )

        items = cursor.fetchall()

        # 4. Fetch payments for these transactions.
        payments_query = f"""
            SELECT
                p.transaction_id,
                p.amount,
                p.payment_method,
                p.paid_at
            FROM payments p
            INNER JOIN transactions t
                ON p.transaction_id = t.transaction_id
            WHERE t.shop_id = %s
              AND p.transaction_id IN ({placeholders})
            ORDER BY p.payment_id ASC
        """

        cursor.execute(
            payments_query,
            (shop_id, *transaction_ids)
        )

        payments = cursor.fetchall()

        # 5. Group items by transaction ID.
        items_map = {}

        for item in items:
            transaction_id = item["transaction_id"]

            items_map.setdefault(transaction_id, []).append({
                "product_name": item["product_name"],
                "quantity": str(item["quantity"]),
                "unit": item["unit"],
                "unit_price": str(item["unit_price"]),
                "subtotal": str(item["subtotal"])
            })

        # 6. Group payments by transaction ID.
        payments_map = {}

        for payment in payments:
            transaction_id = payment["transaction_id"]

            payments_map.setdefault(transaction_id, []).append({
                "amount": str(payment["amount"]),
                "payment_method": payment["payment_method"],
                "paid_at": (
                    payment["paid_at"].isoformat()
                    if payment["paid_at"]
                    else None
                )
            })

        # 7. Combine everything into the final response.
        history = []

        for transaction in transactions:

            transaction_id = transaction["transaction_id"]

            created_at = transaction["created_at"]

            history.append({
                "transaction_id": transaction_id,
                "shop_id": transaction["shop_id"],
                "customer_id": transaction["customer_id"],
                "customer_name": transaction["customer_name"],
                "transaction_type": transaction["transaction_type"],
                "total_amount": str(transaction["total_amount"]),
                "status": transaction["status"],
                "created_at": (
                    created_at.isoformat()
                    if created_at
                    else None
                ),
                "items": items_map.get(transaction_id, []),
                "payments": payments_map.get(transaction_id, [])
            })

        return history

    finally:
        if cursor:
            cursor.close()

        if connection and connection.is_connected():
            connection.close()
