
from flask import Blueprint, request, jsonify

from Backend.Services.transaction_service import (
    record_confirmed_transaction,
    get_shop_transaction_history
)

from Backend.Services.customer_service import DuplicateCustomerError


transaction_bp = Blueprint("transaction", __name__)


@transaction_bp.route("/confirm", methods=["POST"])
def confirm_transaction_route():

    try:
        data = request.get_json(silent=True)

        if not isinstance(data, dict):
            return jsonify({
                "success": False,
                "error": "JSON request body required"
            }), 400

        # Only confirmed voice transactions may be recorded.
        if data.get("status") != "confirmed":
            return jsonify({
                "success": False,
                "error": "Transaction has not been confirmed"
            }), 400

        transaction_data = data.get("transaction")

        if not isinstance(transaction_data, dict):
            return jsonify({
                "success": False,
                "error": "Transaction data is required"
            }), 400

        result = record_confirmed_transaction(
            shop_id=data.get("shop_id"),
            transaction_data=transaction_data,
            customer_phone=data.get("customer_phone"),
            customer_address=data.get("customer_address")
        )

        return jsonify({
            "success": True,
            **result
        }), 201

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

        print("Transaction Error:", e)

        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500

@transaction_bp.route("/<int:shop_id>", methods=["GET"])
def transaction_history_route(shop_id):

    try:
        result = get_shop_transaction_history(shop_id)

        return jsonify({
            "success": True,
            **result
        }), 200

    except ValueError as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 400

    except Exception as e:
        print("Transaction History Error:", e)

        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500
