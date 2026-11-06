
from Backend.Models.shop_model import create_shop


def register_shop(shop_name, owner_name, phone, email=None, address=None):

    # 1. Validate required fields
    if not shop_name or not shop_name.strip():
        raise ValueError("Shop name is required")

    if not owner_name or not owner_name.strip():
        raise ValueError("Owner name is required")

    if not phone or not phone.strip():
        raise ValueError("Phone number is required")

    # 2. Validate phone number
    phone = phone.strip()

    if not phone.isdigit() or len(phone) != 10:
        raise ValueError("Enter a valid 10-digit phone number")

    # 3. Clean optional fields
    email = email.strip() if email else None
    address = address.strip() if address else None

    # 4. Call Model to save shop details
    shop_id = create_shop(
        shop_name=shop_name.strip(),
        owner_name=owner_name.strip(),
        phone=phone,
        email=email,
        address=address
    )

    # 5. Return registration result
    return {
        "shop_id": shop_id,
        "message": "Shop registered successfully"
    }
