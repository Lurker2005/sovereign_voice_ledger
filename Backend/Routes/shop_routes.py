
from flask import Blueprint, request, jsonify
from Backend.Services.shop_service import register_shop

shop_bp = Blueprint("shop", __name__)


@shop_bp.route("/register", methods=["POST"])
def register_shop_route():

    try:
        # Get JSON data from the frontend
        data = request.get_json()

        if not data:
            return jsonify({
                "error": "Request body must contain JSON data"
            }), 400

        # Call the Service layer
        result = register_shop(
            shop_name=data.get("shop_name"),
            owner_name=data.get("owner_name"),
            phone=data.get("phone"),
            email=data.get("email"),
            address=data.get("address")
        )

        return jsonify({
            "success": True,
            "shop_id": result["shop_id"],
            "message": result["message"]
        }), 201

    except ValueError as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 400

    except Exception as e:
        print("Shop Registration Error:", e)

        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500
