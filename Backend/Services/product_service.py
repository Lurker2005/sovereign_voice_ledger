
from decimal import Decimal, InvalidOperation

from Backend.Models.product_model import (
    create_product,
    get_products_by_shop,
    update_product,
    deactivate_product
)


def validate_product(shop_id, product_name, unit, unit_price):

    if isinstance(shop_id, bool) or not isinstance(shop_id, int) or shop_id <= 0:
        raise ValueError("Invalid shop ID")

    if not isinstance(product_name, str) or not product_name.strip():
        raise ValueError("Product name is required")

    if not isinstance(unit, str) or not unit.strip():
        raise ValueError("Product unit is required")

    try:
        price = Decimal(str(unit_price))
    except (InvalidOperation, TypeError, ValueError):
        raise ValueError("Invalid product price")

    if not price.is_finite() or price <= 0:
        raise ValueError("Product price must be greater than zero")

    if price.as_tuple().exponent < -2:
        raise ValueError("Product price cannot have more than 2 decimal places")

    return price


def add_product(shop_id, product_name, unit, unit_price):

    price = validate_product(
        shop_id, product_name, unit, unit_price
    )

    product_id = create_product(
        shop_id,
        product_name.strip(),
        unit.strip(),
        price
    )

    return {
        "product_id": product_id,
        "message": "Product added successfully"
    }


def view_products(shop_id):

    if isinstance(shop_id, bool) or not isinstance(shop_id, int) or shop_id <= 0:
        raise ValueError("Invalid shop ID")

    products = get_products_by_shop(shop_id)

    return products


def edit_product(shop_id, product_id, product_name, unit, unit_price):

    if isinstance(product_id, bool) or not isinstance(product_id, int) or product_id <= 0:
        raise ValueError("Invalid product ID")

    price = validate_product(
        shop_id, product_name, unit, unit_price
    )

    updated = update_product(
        shop_id,
        product_id,
        product_name.strip(),
        unit.strip(),
        price
    )

    if not updated:
        raise ValueError("Product not found or already inactive")

    return {
        "message": "Product updated successfully"
    }


def remove_product(shop_id, product_id):

    if isinstance(shop_id, bool) or not isinstance(shop_id, int) or shop_id <= 0:
        raise ValueError("Invalid shop ID")

    if isinstance(product_id, bool) or not isinstance(product_id, int) or product_id <= 0:
        raise ValueError("Invalid product ID")

    removed = deactivate_product(shop_id, product_id)

    if not removed:
        raise ValueError("Product not found or already inactive")

    return {
        "message": "Product deactivated successfully"
    }
