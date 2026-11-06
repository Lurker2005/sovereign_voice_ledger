# from App.Services.stt import transcribe_audio
# from App.Services.nlu import nlu, nlu_correction
# from App.Services.tts import tts
# from App.Services.validation import validate_transaction
from Voice.App.Services.stt import transcribe_audio
from Voice.App.Services.nlu import nlu, nlu_correction
from Voice.App.Services.tts import tts
from Voice.App.Services.validation import validate_transaction

conversations = {}

def start_conversation(conversation_id, language_code):

    conversations[conversation_id] = {
        "transaction": None,
        "phase": "collecting",
        "last_question": None,
        "language_code": language_code,
        "awaiting_field":None
    }

def get_conversation(conversation_id):
    return conversations.get(conversation_id, None)

def update_transaction(conversation_id,transaction):
    if(conversation_id in conversations):
        conversations[conversation_id]["transaction"] = transaction

def delete_conversation(conversation_id):
    if(conversation_id in conversations):
        conversations.pop(conversation_id)

def speak(text,language_code):
    audio=tts(text,language_code)
    return audio


def get_missing_questions(missing_fields, transaction, language_code):

    if not missing_fields:
        return None, None

    field = missing_fields[0]

    is_tamil = language_code.startswith("ta")

    if is_tamil:
        questions = {
            "customer_name": "வாடிக்கையாளரின் பெயர் என்ன?",
            "transaction_type": "இது பொருள் வாங்கியதா அல்லது பழைய கடனுக்கான பணம் செலுத்தியதா?",
            "items": "வாடிக்கையாளர் என்ன பொருள் வாங்கினார்?",
            "amount_paid": "இந்த வாங்குதலுக்கு வாடிக்கையாளர் எவ்வளவு பணம் கொடுத்தார்?"
        }
    else:
        questions = {
            "customer_name": "What is the customer's name?",
            "transaction_type": "Is this a purchase or a repayment?",
            "items": "Which product did the customer buy?",
            "amount_paid": "How much did the customer pay?"
        }
    if field == "amount_paid":

        if is_tamil:
            if transaction["transaction_type"] == "repayment":
                question = "வாடிக்கையாளர் எவ்வளவு பணம் செலுத்தினார்?"
            else:
                question = "இந்த வாங்குதலுக்கு வாடிக்கையாளர் எவ்வளவு பணம் கொடுத்தார்?"

        else:
            if transaction["transaction_type"] == "repayment":
                question = "How much did the customer pay towards the existing debt?"
            else:
                question = "How much did the customer pay for this purchase?"

        return question, field

    if field in questions:
        return questions[field], field

    import re

    match = re.match(r"items\[(\d+)\]\.(product_name|quantity|unit)", field)

    if match:
        index = int(match.group(1))
        field_name = match.group(2)

        product_name = transaction["items"][index].get("product_name")

        if is_tamil:
            if field_name == "product_name":
                question = f"வாடிக்கையாளர் வாங்கிய பொருளின் பெயர் என்ன?"

            elif field_name == "quantity":
                question = f"எவ்வளவு {product_name} வாங்கினார்?"

            else:
                question = f"{product_name} எந்த அளவில் வாங்கினார்?"

        else:
            if field_name == "product_name":
                question = f"What is the product name for item {index + 1}?"

            elif field_name == "quantity":
                question = f"How much {product_name} did the customer buy?"

            else:
                question = f"What is the unit for {product_name}?"

        return question, field

    if is_tamil:
        return "அந்த விவரத்தை மீண்டும் சொல்ல முடியுமா?", field

    return "Could you please repeat that information?", field


# def get_missing_questions(missing_fields, transaction):

#     if not missing_fields:
#         return None, None

#     field = missing_fields[0]

#     # General fields
#     questions = {
#         "customer_name": "What is the customer's name?",
#         "transaction_type": "Is this a purchase or a repayment?",
#         "items": "Which product did the customer buy?",
#         "amount_paid": "How much did the customer pay?"
#     }

#     if field in questions:
#         return questions[field], field

#     # Product-specific fields
#     import re

#     match = re.match(r"items\[(\d+)\]\.(product_name|quantity|unit)", field)

#     if match:
#         index = int(match.group(1))
#         field_name = match.group(2)

#         product_name = transaction["items"][index].get("product_name")

#         if field_name == "product_name":
#             question = f"What is the product name for item {index + 1}?"

#         elif field_name == "quantity":
#             question = f"How much {product_name} did the customer buy?"

#         else:
#             question = f"What is the unit for {product_name}?"

#         return question, field

#     return "Could you please repeat that information?", field

def ask_for_missing_information(conversation_id, missing_fields):

    conversation = get_conversation(conversation_id)

    if conversation is None:
        return None

    transaction = conversation["transaction"]

    question, field = get_missing_questions(
        missing_fields,
        transaction,
        conversation["language_code"]
    )

    conversation["last_question"] = question
    conversation["awaiting_field"] = field
    conversation["phase"] = "collecting"

    language_code = conversation["language_code"]

    audio = speak(question, language_code)

    return {
        "status": "needs_information",
        "message": question,
        "awaiting_field": field,
        "audio": audio
    }

def process_turn(conversation_id, audio, language_code):

    # 1. Convert audio to text
    transcript = transcribe_audio(audio, language_code)

    if isinstance(transcript, tuple):
        return {
            "status": "error",
            "message": str(transcript),
            "audio": None
        }

    # 2. Retrieve existing conversation
    conversation = get_conversation(conversation_id)

    # 3. New conversation
    if conversation is None:

        start_conversation(conversation_id, language_code)
        conversation = get_conversation(conversation_id)
        transaction = nlu(transcript)

        if not isinstance(transaction, dict):
            delete_conversation(conversation_id)

            return {
                "status": "error",
                "message": "Unable to understand the transaction. Please try again.",
                "audio": None
            }

        update_transaction(conversation_id, transaction)

        # transaction = nlu(transcript)

        # update_transaction(conversation_id, transaction)

    # 4. Existing conversation: process correction
    else:

        transaction = conversation["transaction"]
        awaiting_field = conversation["awaiting_field"]


        correction = nlu_correction(
            transcript,
            transaction,
            awaiting_field,
            phase=conversation["phase"]
        )

        correction_status = correction.get("status")

        if correction_status == "cancelled":
            delete_conversation(conversation_id)

            return {
                "status": "cancelled",
                "audio": None
            }

        if correction_status == "unclear":
            question = conversation["last_question"] or "Could you please repeat that?"

            audio_response = speak(
                question,
                conversation["language_code"]
            )

            return {
                "status": "unclear",
                "message": question,
                "audio": audio_response
            }
        if correction_status not in ["updated", "confirmed", "cancelled", "unclear"]:
            return {
                "status": "error",
                "message": "Unexpected correction status",
                "audio": None
            }

        if correction_status in ["updated", "confirmed"]:

            transaction = correction.get("transaction")

            if transaction is None:
                return {
                    "status": "error",
                    "message": "Invalid correction response",
                    "audio": None
                }

            update_transaction(conversation_id, transaction)

            if correction_status == "confirmed":

                if conversation["phase"] == "confirming":
                    conversation["phase"] = "confirmed"

                    return {
                        "status": "confirmed",
                        "transaction": transaction,
                        "audio": None
                    }

                return {
                    "status": "error",
                    "message": "Unexpected confirmation during information collection",
                    "audio": None
                }

    # 5. Validate updated transaction
    # Handle unclear transaction
    if transaction.get("transaction_type") == "unclear":

        if conversation["language_code"].startswith("ta"):
            question = "பரிவர்த்தனை எனக்குப் புரியவில்லை. தயவுசெய்து மீண்டும் சொல்ல முடியுமா?"
        else:
            question = "I couldn't understand the transaction. Could you please repeat it?"

        conversation = get_conversation(conversation_id)
        conversation["last_question"] = question
        conversation["awaiting_field"] = None
        conversation["phase"] = "collecting"

        audio_response = speak(question, conversation["language_code"])

        return {
            "status": "unclear",
            "message": question,
            "audio": audio_response
        }
    validation = validate_transaction(transaction)

    # 6. Ask for missing information
    if not validation["valid"]:
        return ask_for_missing_information(
            conversation_id,
            validation["missing_fields"]
        )

   # 7. All information is available
    conversation = get_conversation(conversation_id)

    confirmation_message = get_confirmation_message(
    transaction,
    conversation["language_code"]
)

    conversation["phase"] = "confirming"
    conversation["last_question"] = confirmation_message
    conversation["awaiting_field"] = None

    audio_response = speak(
        confirmation_message,
        conversation["language_code"]
    )

    return {
        "status": "ready_for_confirmation",
        "transaction": transaction,
        "message": confirmation_message,
        "audio": audio_response
    }
# def get_confirmation_message(transaction):

#     customer_name = transaction["customer_name"]
#     transaction_type = transaction["transaction_type"]

#     if transaction_type == "purchase":

#         items = transaction["items"]

#         item_details = []

#         for item in items:
#             detail = f'{item["quantity"]} {item["unit"]} {item["product_name"]}'
#             item_details.append(detail)

#         items_text = ", ".join(item_details)

#         message = (
#             f"{customer_name} bought {items_text}. "
#             "Should I confirm this transaction?"
#         )

#     elif transaction_type == "repayment":

#         amount_paid = transaction["amount_paid"]

#         message = (
#             f"{customer_name} paid ₹{amount_paid} "
#             "towards the existing debt. "
#             "Should I confirm this repayment?"
#         )

#     return message


def get_confirmation_message(transaction, language_code):

    customer_name = transaction["customer_name"]
    transaction_type = transaction["transaction_type"]

    is_tamil = language_code.startswith("ta")

    if transaction_type == "purchase":

        items = transaction["items"]
        item_details = []

        for item in items:
            quantity = item["quantity"]
            unit = item["unit"]
            product_name = item["product_name"]

            if is_tamil:
                unit_map = {
                    "kg": "கிலோ",
                    "kilo": "கிலோ",
                    "g": "கிராம்",
                    "gram": "கிராம்",
                    "litre": "லிட்டர்",
                    "liter": "லிட்டர்",
                    "piece": "எண்ணிக்கை"
                }

                unit = unit_map.get(unit.lower(), unit)

            item_details.append(
                f"{quantity} {unit} {product_name}"
            )

        items_text = ", ".join(item_details)

        if is_tamil:
            message = f"{customer_name} {items_text} வாங்கியுள்ளார்."

            if transaction.get("payment_mentioned") is True:
                amount_paid = transaction["amount_paid"]
                message += f" ₹{amount_paid} செலுத்தியுள்ளார்."

            message += " இந்தப் பரிவர்த்தனையை உறுதிப்படுத்தலாமா?"

        else:
            message = f"{customer_name} bought {items_text}."

            if transaction.get("payment_mentioned") is True:
                amount_paid = transaction["amount_paid"]
                message += f" Paid ₹{amount_paid}."

            message += " Should I confirm this transaction?"

    elif transaction_type == "repayment":

        amount_paid = transaction["amount_paid"]

        if is_tamil:
            message = (
                f"{customer_name} ஏற்கனவே இருந்த கடனுக்காக "
                f"₹{amount_paid} செலுத்தியுள்ளார். "
                "இந்தத் திருப்பிச் செலுத்துதலை உறுதிப்படுத்தலாமா?"
            )

        else:
            message = (
                f"{customer_name} paid ₹{amount_paid} "
                "towards the existing debt. "
                "Should I confirm this repayment?"
            )

    return message
