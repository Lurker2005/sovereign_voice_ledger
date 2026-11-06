
from flask import Blueprint, request, jsonify

from Backend.Services.product_service import (
    add_product,
    view_products,
    edit_product,
    remove_product
)

product_bp = Blueprint("product", __name__)


@product_bp.route("/add", methods=["POST"])
def add_product_route():

    try:
        data = request.get_json()

        if not data:
            return jsonify({"error": "JSON data required"}), 400

        result = add_product(
            shop_id=data.get("shop_id"),
            product_name=data.get("product_name"),
            unit=data.get("unit"),
            unit_price=data.get("unit_price")
        )

        return jsonify({
            "success": True,
            **result
        }), 201

    except ValueError as e:
        return jsonify({"success": False, "error": str(e)}), 400

    except Exception as e:
        print("Add Product Error:", e)
        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500


@product_bp.route("/<int:shop_id>", methods=["GET"])
def view_products_route(shop_id):

    try:
        products = view_products(shop_id)

        return jsonify({
            "success": True,
            "products": products
        }), 200

    except ValueError as e:
        return jsonify({"success": False, "error": str(e)}), 400

    except Exception as e:
        print("View Products Error:", e)
        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500


@product_bp.route("/update", methods=["PUT"])
def update_product_route():

    try:
        data = request.get_json()

        if not data:
            return jsonify({"error": "JSON data required"}), 400

        edit_product(
            shop_id=data.get("shop_id"),
            product_id=data.get("product_id"),
            product_name=data.get("product_name"),
            unit=data.get("unit"),
            unit_price=data.get("unit_price")
        )

        return jsonify({
            "success": True,
            "message": "Product updated successfully"
        }), 200

    except ValueError as e:
        return jsonify({"success": False, "error": str(e)}), 400

    except Exception as e:
        print("Update Product Error:", e)
        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500


@product_bp.route("/deactivate", methods=["PATCH"])
def deactivate_product_route():

    try:
        data = request.get_json()

        if not data:
            return jsonify({"error": "JSON data required"}), 400

        remove_product(
            shop_id=data.get("shop_id"),
            product_id=data.get("product_id")
        )

        return jsonify({
            "success": True,
            "message": "Product deactivated successfully"
        }), 200

    except ValueError as e:
        return jsonify({"success": False, "error": str(e)}), 400

    except Exception as e:
        print("Deactivate Product Error:", e)
        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500
