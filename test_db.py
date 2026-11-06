from Backend.Services.shop_service import register_shop

try:
    result = register_shop(
        shop_name="Fresh Mart",
        owner_name="Test Owner",
        phone="9876543211",
        email="freshmart@gmail.com",
        address="Chennai"
    )

    print("Registration Successful!")
    print("Shop ID:", result["shop_id"])
    print("Message:", result["message"])

except Exception as e:
    print("Registration Failed:", e)