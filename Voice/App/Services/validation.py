def validate_transaction(data):

    missing_fields = []

    # 1. Validate customer name
    if not data.get("customer_name"):
        missing_fields.append("customer_name")

    # 2. Validate transaction type
    transaction_type = data.get("transaction_type")

    if transaction_type not in ["purchase", "repayment"]:
        # return {
        #     "valid": False,
        #     "missing_fields": ["transaction_type"],
        #     "error": "Invalid or unclear transaction type"
        # }
         missing_fields.append("transaction_type")

    # 3. Purchase validation
    if transaction_type == "purchase":

        items = data.get("items")

        if not items:
            missing_fields.append("items")

        else:
            for index, item in enumerate(items):

                if not item.get("product_name"):
                    missing_fields.append(f"items[{index}].product_name")

                quantity = item.get("quantity")

                if quantity is None:
                    missing_fields.append(f"items[{index}].quantity")

                elif isinstance(quantity, bool) or not isinstance(quantity, (int, float)) or quantity <= 0:
                    missing_fields.append(f"items[{index}].quantity")

                if not item.get("unit"):
                    missing_fields.append(f"items[{index}].unit")

                # if not isinstance(item.get("quantity"), (int, float)) or item["quantity"] <= 0 or isinstance(item.get("quantity"),(bool)):
                #     missing_fields.append(f"items[{index}].quantity")
        payment_mentioned = data.get("payment_mentioned")

        if payment_mentioned is True:
                amount_paid = data.get("amount_paid")

                if amount_paid is None:
                    missing_fields.append("amount_paid")

                elif isinstance(amount_paid, bool) or not isinstance(amount_paid, (int, float)) or amount_paid <= 0:
                    missing_fields.append("amount_paid")

        elif payment_mentioned is not False:
                missing_fields.append("payment_mentioned")

    # 4. Repayment validation
    elif transaction_type == "repayment":

        if data.get("amount_paid") is None:
            missing_fields.append("amount_paid")

        elif isinstance(data.get("amount_paid"), bool) or not isinstance(data.get("amount_paid"), (int, float)) or data["amount_paid"] <= 0:
            missing_fields.append("amount_paid")

    # 5. Final validation result
    if missing_fields:
        return {
            "valid": False,
            "missing_fields": missing_fields
        }

    return {
        "valid": True,
        "missing_fields": []
    }