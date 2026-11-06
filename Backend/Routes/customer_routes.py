
from flask import Blueprint, request, jsonify

from Backend.Services.customer_service import (
    resolve_customer,
    view_customers,
    view_customer_balance,
    DuplicateCustomerError
)

customer_bp = Blueprint("customer", __name__)


@customer_bp.route("/resolve", methods=["POST"])
def resolve_customer_route():

    try:
        data = request.get_json()

        if not data:
            return jsonify({
                "success": False,
                "error": "JSON data required"
            }), 400

        result = resolve_customer(
            shop_id=data.get("shop_id"),
            customer_name=data.get("customer_name"),
            phone=data.get("phone"),
            address=data.get("address")
        )

        return jsonify({
            "success": True,
            **result
        }), 200 if not result["created"] else 201

    except DuplicateCustomerError as e:
        return jsonify({
            "success": False,
            "requires_clarification": True,
            "error": str(e),
            "candidates": e.candidates
        }), 409

    except ValueError as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 400

    except Exception as e:
        print("Customer Resolution Error:", e)

        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500


@customer_bp.route("/<int:shop_id>", methods=["GET"])
def view_customers_route(shop_id):

    try:
        customers = view_customers(shop_id)

        return jsonify({
            "success": True,
            "customers": customers
        }), 200

    except ValueError as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 400

    except Exception as e:
        print("View Customers Error:", e)

        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500


@customer_bp.route(
    "/<int:shop_id>/<int:customer_id>/balance",
    methods=["GET"]
)
def customer_balance_route(shop_id, customer_id):

    try:
        customer = view_customer_balance(shop_id, customer_id)

        return jsonify({
            "success": True,
            "customer": customer
        }), 200

    except ValueError as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 404

    except Exception as e:
        print("Customer Balance Error:", e)

        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500
