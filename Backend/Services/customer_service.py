
from Backend.Models.customer_model import (
    find_customers_by_name,
    find_customer_by_phone,
    create_customer_and_account,
    get_customers_by_shop,
    get_customer_balance
)


class DuplicateCustomerError(Exception):

    def __init__(self, candidates):
        self.candidates = candidates

        super().__init__(
            "Multiple customers have this name. Please identify the correct customer."
        )


# --------------------------------------------------
# VALIDATION FUNCTIONS
# --------------------------------------------------

def validate_shop_id(shop_id):

    if (
        isinstance(shop_id, bool)
        or not isinstance(shop_id, int)
        or shop_id <= 0
    ):
        raise ValueError("Invalid shop ID")


def validate_customer_name(customer_name):

    if (
        not isinstance(customer_name, str)
        or not customer_name.strip()
    ):
        raise ValueError("Customer name is required")

    return customer_name.strip()


def validate_phone(phone):

    if phone is None or phone == "":
        return None

    if not isinstance(phone, str):
        phone = str(phone)

    phone = phone.strip()

    if not phone.isdigit() or len(phone) != 10:
        raise ValueError("Enter a valid 10-digit phone number")

    return phone


# --------------------------------------------------
# CREATE CUSTOMER
# --------------------------------------------------

def create_customer(shop_id, customer_name, phone=None, address=None):

    validate_shop_id(shop_id)

    customer_name = validate_customer_name(customer_name)
    phone = validate_phone(phone)

    if address is not None:

        if not isinstance(address, str):
            raise ValueError("Invalid customer address")

        address = address.strip() or None

    # Check whether the phone number already exists
    # within this shop.

    if phone:

        existing_customer = find_customer_by_phone(
            shop_id,
            phone
        )

        if existing_customer:
            raise ValueError(
                "A customer with this phone number already exists."
            )

    # Create customer and account together.

    created = create_customer_and_account(
        shop_id=shop_id,
        customer_name=customer_name,
        phone=phone,
        address=address
    )

    return {
        "customer_id": created["customer_id"],
        "account_id": created["account_id"],
        "customer_name": customer_name,
        "created": True,
        "message": "Customer and account created successfully"
    }


# --------------------------------------------------
# RESOLVE CUSTOMER
# --------------------------------------------------

def resolve_customer(shop_id, customer_name, phone=None, address=None):

    validate_shop_id(shop_id)

    customer_name = validate_customer_name(customer_name)
    phone = validate_phone(phone)

    if address is not None:

        if not isinstance(address, str):
            raise ValueError("Invalid customer address")

        address = address.strip() or None

    # Find customers with the same name in this shop.

    matches = find_customers_by_name(
        shop_id,
        customer_name
    )

    # CASE 1: Customer does not exist.
    # Automatically create customer and account.

    if not matches:

        return create_customer(
            shop_id=shop_id,
            customer_name=customer_name,
            phone=phone,
            address=address
        )

    # CASE 2: Multiple customers have the same name.

    if len(matches) > 1:

        if phone:

            phone_matches = [
                customer
                for customer in matches
                if customer["phone"] == phone
            ]

            if len(phone_matches) == 1:

                customer = phone_matches[0]

                return {
                    "customer_id": customer["customer_id"],
                    "customer_name": customer["customer_name"],
                    "created": False,
                    "message": "Existing customer identified by phone number"
                }

        # Do not select an arbitrary customer.

        raise DuplicateCustomerError(matches)

    # CASE 3: Exactly one customer matches.

    customer = matches[0]

    # Check whether the supplied phone conflicts
    # with the existing customer's phone.

    if phone and customer["phone"] and customer["phone"] != phone:

        raise ValueError(
            "The customer name matches, but the phone number does not. Please clarify."
        )

    return {
        "customer_id": customer["customer_id"],
        "customer_name": customer["customer_name"],
        "created": False,
        "message": "Existing customer found"
    }


# --------------------------------------------------
# VIEW CUSTOMERS
# --------------------------------------------------

def view_customers(shop_id):

    validate_shop_id(shop_id)

    return get_customers_by_shop(shop_id)


# --------------------------------------------------
# VIEW CUSTOMER BALANCE
# --------------------------------------------------

def view_customer_balance(shop_id, customer_id):

    validate_shop_id(shop_id)

    if (
        isinstance(customer_id, bool)
        or not isinstance(customer_id, int)
        or customer_id <= 0
    ):
        raise ValueError("Invalid customer ID")

    customer = get_customer_balance(
        shop_id,
        customer_id
    )

    if not customer:

        raise ValueError(
            "Customer not found in this shop"
        )

    return customer
