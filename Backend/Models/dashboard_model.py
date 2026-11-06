
from Backend.config.db import get_db_connection


def get_dashboard_data(shop_id):
    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        # 1. Dashboard summary
        # Only positive balances count as outstanding debt.
        summary_query = """
            SELECT
                (
                    SELECT COUNT(*)
                    FROM customers
                    WHERE shop_id = %s
                ) AS total_customers,

                (
                    SELECT COUNT(*)
                    FROM transactions
                    WHERE shop_id = %s
                      AND status = 'confirmed'
                ) AS total_transactions,

                (
                    SELECT COALESCE(
                        SUM(
                            CASE
                                WHEN current_balance > 0
                                THEN current_balance
                                ELSE 0
                            END
                        ),
                        0
                    )
                    FROM customer_accounts
                    WHERE shop_id = %s
                ) AS total_outstanding
        """

        cursor.execute(
            summary_query,
            (shop_id, shop_id, shop_id)
        )

        summary = cursor.fetchone()

        # 2. Today's confirmed purchase sales.
        sales_query = """
            SELECT COALESCE(SUM(total_amount), 0) AS daily_sales
            FROM transactions
            WHERE shop_id = %s
              AND status = 'confirmed'
              AND transaction_type = 'purchase'
              AND DATE(created_at) = CURDATE()
        """

        cursor.execute(sales_query, (shop_id,))
        sales_result = cursor.fetchone()

        # 3. Today's collections.
        # Includes payments received against purchases and repayments.
        collections_query = """
            SELECT COALESCE(SUM(p.amount), 0) AS daily_collections
            FROM payments p
            INNER JOIN transactions t
                ON p.transaction_id = t.transaction_id
            WHERE t.shop_id = %s
              AND t.status = 'confirmed'
              AND DATE(p.paid_at) = CURDATE()
        """

        cursor.execute(collections_query, (shop_id,))
        collections_result = cursor.fetchone()

        # 4. Recent confirmed transactions.
        recent_query = """
            SELECT
                t.transaction_id,
                t.customer_id,
                c.customer_name,
                t.transaction_type,
                t.total_amount,
                t.created_at
            FROM transactions t
            INNER JOIN customers c
                ON t.customer_id = c.customer_id
               AND t.shop_id = c.shop_id
            WHERE t.shop_id = %s
              AND t.status = 'confirmed'
            ORDER BY
                t.created_at DESC,
                t.transaction_id DESC
            LIMIT 5
        """

        cursor.execute(recent_query, (shop_id,))
        recent_transactions = cursor.fetchall()

        # 5. Convert database values into JSON-friendly values.
        for transaction in recent_transactions:
            transaction["total_amount"] = str(
                transaction["total_amount"]
            )

            if transaction["created_at"]:
                transaction["created_at"] = (
                    transaction["created_at"].isoformat()
                )

        return {
            "total_customers": summary["total_customers"],
            "total_transactions": summary["total_transactions"],
            "total_outstanding": str(
                summary["total_outstanding"]
            ),
            "daily_sales": str(sales_result["daily_sales"]),
            "daily_collections": str(
                collections_result["daily_collections"]
            ),
            "recent_transactions": recent_transactions
        }

    finally:
        if cursor:
            cursor.close()

        if connection and connection.is_connected():
            connection.close()
