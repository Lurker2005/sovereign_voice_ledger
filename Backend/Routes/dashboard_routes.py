
from flask import Blueprint, jsonify

from Backend.Services.dashboard_service import get_dashboard_summary


dashboard_bp = Blueprint("dashboard", __name__)


@dashboard_bp.route("/<int:shop_id>", methods=["GET"])
def get_dashboard(shop_id):
    try:
        response = get_dashboard_summary(shop_id)
        return jsonify(response), 200

    except ValueError as error:
        return jsonify({
            "success": False,
            "message": str(error)
        }), 400

    except Exception as error:
        print(f"Dashboard error: {error}")

        return jsonify({
            "success": False,
            "message": "Unable to retrieve dashboard data"
        }), 500
