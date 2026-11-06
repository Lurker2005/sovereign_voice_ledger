
from decimal import Decimal, InvalidOperation

# from Backend.Models.transaction_model import create_transaction_atomic
from Backend.Models.transaction_model import (
    create_transaction_atomic,
    get_transactions_by_shop
)

from Backend.Services.customer_service import (
    resolve_customer,
    DuplicateCustomerError
)


def validate_shop_id(shop_id):

    if (
        isinstance(shop_id, bool)
        or not isinstance(shop_id, int)
        or shop_id <= 0
    ):
        raise ValueError("Invalid shop ID")


def validate_amount(value, field_name, allow_zero=True):

    try:
        amount = Decimal(str(value))
    except (InvalidOperation, TypeError, ValueError):
        raise ValueError(f"Invalid {field_name}")

    if not amount.is_finite():
        raise ValueError(f"Invalid {field_name}")

    if amount < 0 or (not allow_zero and amount == 0):
        raise ValueError(
            f"{field_name} must be {'zero or greater' if allow_zero else 'greater than zero'}"
        )

    if amount.as_tuple().exponent < -2:
        raise ValueError(f"{field_name} cannot have more than 2 decimal places")

    return amount


def validate_items(items):

    if not isinstance(items, list):
        raise ValueError("Transaction items must be a list")

    validated_items = []

    for item in items:

        if not isinstance(item, dict):
            raise ValueError("Invalid transaction item")

        product_name = item.get("product_name")
        unit = item.get("unit")
        quantity_value = item.get("quantity")

        if not isinstance(product_name, str) or not product_name.strip():
            raise ValueError("Product name is required")

        if not isinstance(unit, str) or not unit.strip():
            raise ValueError("Product unit is required")

        if isinstance(quantity_value, bool):
            raise ValueError("Invalid product quantity")

        try:
            quantity = Decimal(str(quantity_value))
        except (InvalidOperation, TypeError, ValueError):
            raise ValueError("Invalid product quantity")

        if not quantity.is_finite() or quantity <= 0:
            raise ValueError("Product quantity must be greater than zero")

        if quantity.as_tuple().exponent < -3:
            raise ValueError("Quantity cannot have more than 3 decimal places")

        validated_items.append({
            "product_name": product_name.strip(),
            "quantity": quantity,
            "unit": unit.strip()
        })

    return validated_items


def record_confirmed_transaction(
    shop_id,
    transaction_data,
    customer_phone=None,
    customer_address=None
):

    validate_shop_id(shop_id)

    if not isinstance(transaction_data, dict):
        raise ValueError("Invalid transaction data")

    # --------------------------------------------------
    # 1. Validate transaction type.
    # --------------------------------------------------

    transaction_type = transaction_data.get("transaction_type")

    if transaction_type not in ("purchase", "repayment"):
        raise ValueError("Transaction type must be purchase or repayment")

    # --------------------------------------------------
    # 2. Validate customer name.
    # --------------------------------------------------

    customer_name = transaction_data.get("customer_name")

    if (
        not isinstance(customer_name, str)
        or not customer_name.strip()
    ):
        raise ValueError("Customer name is required")

    customer_name = customer_name.strip()

    # --------------------------------------------------
    # 3. Validate items.
    # --------------------------------------------------

    items = transaction_data.get("items", [])

    if transaction_type == "purchase":

        items = validate_items(items)

        if not items:
            raise ValueError("Purchase must contain at least one item")

    else:

        if items:
            raise ValueError("Repayment cannot contain purchase items")

        items = []

    # --------------------------------------------------
    # 4. Validate payment amount.
    # --------------------------------------------------

    amount_paid = validate_amount(
        transaction_data.get("amount_paid", 0),
        "Payment amount",
        allow_zero=(transaction_type == "purchase")
    )

    if transaction_type == "repayment" and amount_paid <= 0:
        raise ValueError("Repayment amount must be greater than zero")

    # --------------------------------------------------
    # 5. Validate payment method.
    # --------------------------------------------------

    payment_method = transaction_data.get("payment_method")

    if payment_method is not None:

        if not isinstance(payment_method, str):
            raise ValueError("Invalid payment method")

        payment_method = payment_method.strip() or None

        if payment_method and len(payment_method) > 30:
            raise ValueError("Payment method is too long")

    # --------------------------------------------------
    # 6. Resolve customer.
    # Reuse an existing customer or create a new one.
    # Duplicate names trigger clarification.
    # --------------------------------------------------

    customer = resolve_customer(
        shop_id=shop_id,
        customer_name=customer_name,
        phone=customer_phone,
        address=customer_address
    )

    customer_id = customer["customer_id"]

    # --------------------------------------------------
    # 7. Save transaction and update account atomically.
    # --------------------------------------------------

    result = create_transaction_atomic(
        shop_id=shop_id,
        customer_id=customer_id,
        transaction_type=transaction_type,
        items=items,
        amount_paid=amount_paid,
        payment_method=payment_method
    )

    result["customer_name"] = customer_name
    result["customer_created"] = customer.get("created", False)

    return result

def get_shop_transaction_history(shop_id):

    validate_shop_id(shop_id)

    transactions = get_transactions_by_shop(shop_id)

    return {
        "transactions": transactions,
        "total_transactions": len(transactions)
    }
