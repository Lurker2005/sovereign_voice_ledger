
from flask import Flask
from Backend.Routes.shop_routes import shop_bp
from Backend.Routes.product_routes import product_bp
from Backend.Routes.customer_routes import customer_bp
from Backend.Routes.transaction_routes import transaction_bp
from Backend.Routes.voice_routes import voice_bp
from Backend.Routes.dashboard_routes import dashboard_bp

app = Flask(__name__)

# Register Shop Blueprint
app.register_blueprint(product_bp, url_prefix="/products")
app.register_blueprint(shop_bp, url_prefix="/shops")
app.register_blueprint(customer_bp, url_prefix="/customers")
app.register_blueprint(voice_bp, url_prefix="/voice")
app.register_blueprint(
    transaction_bp,
    url_prefix="/transactions"
)
app.register_blueprint(dashboard_bp, url_prefix="/dashboard")


@app.route("/")
def home():
    return {
        "message": "Sovereign Voice Ledger API is running"
    }


if __name__ == "__main__":
    # app.run(debug=True)
    app.run(
    host="0.0.0.0",
    port=5000,
    debug=True
)
