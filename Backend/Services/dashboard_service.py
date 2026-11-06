
from Backend.Models.dashboard_model import get_dashboard_data


def get_dashboard_summary(shop_id):
    """
    Validate the shop ID and retrieve dashboard information.
    """

    if not isinstance(shop_id, int) or shop_id <= 0:
        raise ValueError("Invalid shop ID")

    dashboard_data = get_dashboard_data(shop_id)

    if dashboard_data is None:
        raise ValueError("Unable to retrieve dashboard data")

    return {
        "success": True,
        "message": "Dashboard data retrieved successfully",
        "data": dashboard_data
    }
