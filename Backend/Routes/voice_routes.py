
import base64
import uuid

from flask import Blueprint, request, jsonify

from Voice.App.Services.ai_pipeline import process_turn
from Backend.Services.transaction_service import record_confirmed_transaction
from Backend.Services.customer_service import DuplicateCustomerError


voice_bp = Blueprint("voice", __name__)

# Temporary in-memory tracking for the MVP.
conversation_shops = {}
completed_conversations = set()


@voice_bp.route("/turn", methods=["POST"])
def voice_turn():
    try:
        # 1. Receive audio and request details.
        audio_file = request.files.get("audio")

        if not audio_file:
            return jsonify({
                "status": "error",
                "message": "Audio file is required."
            }), 400

        if not audio_file.filename.lower().endswith(".wav"):
            return jsonify({
                "status": "error",
                "message": "Please upload a WAV audio file."
            }), 400

        shop_id = request.form.get("shop_id")
        language_code = request.form.get("language_code", "en-IN")
        conversation_id = request.form.get("conversation_id")

        # 2. Validate the request.
        try:
            shop_id = int(shop_id)
        except (TypeError, ValueError):
            return jsonify({
                "status": "error",
                "message": "A valid shop_id is required."
            }), 400

        if shop_id <= 0:
            return jsonify({
                "status": "error",
                "message": "shop_id must be positive."
            }), 400

        if language_code not in ("en-IN", "ta-IN"):
            return jsonify({
                "status": "error",
                "message": "Supported languages are en-IN and ta-IN."
            }), 400

        if not conversation_id:
            conversation_id = str(uuid.uuid4())

        if conversation_id in completed_conversations:
            return jsonify({
                "status": "error",
                "message": "This conversation has already been completed."
            }), 409

        # Ensure a conversation cannot switch between shops.
        existing_shop_id = conversation_shops.get(conversation_id)

        if existing_shop_id is not None and existing_shop_id != shop_id:
            return jsonify({
                "status": "error",
                "message": "This conversation belongs to another shop."
            }), 403

        conversation_shops[conversation_id] = shop_id

        # 3. Send audio to the voice AI pipeline.
        audio_bytes = audio_file.read()

        if not audio_bytes:
            return jsonify({
                "status": "error",
                "message": "The uploaded audio file is empty."
            }), 400

        result = process_turn(
            conversation_id,
            audio_bytes,
            language_code
        )

        if not isinstance(result, dict):
            return jsonify({
                "status": "error",
                "message": "The voice pipeline returned an invalid response."
            }), 500

        status = result.get("status")

        # 4. Handle errors and cancellation.
        if status == "error":
            return jsonify({
                "status": "error",
                "message": result.get("message", "Voice processing failed.")
            }), 502

        if status == "cancelled":
            conversation_shops.pop(conversation_id, None)

            return jsonify({
                "status": "cancelled",
                "message": result.get("message", "Transaction cancelled."),
                "conversation_id": conversation_id
            }), 200

        # 5. Persist only when the SERVER-SIDE pipeline confirms.
        # if status == "confirmed":
        #     transaction_data = result.get("transaction")

        #     if not isinstance(transaction_data, dict):
        #         return jsonify({
        #             "status": "error",
        #             "message": "Confirmed transaction data is missing."
        #         }), 500

        #     # The NLU may represent no payment as None.
        #     if (
        #         transaction_data.get("transaction_type") == "purchase"
        #         and transaction_data.get("payment_mentioned") is False
        #     ):
        #         transaction_data["amount_paid"] = 0

        #     saved_transaction = record_confirmed_transaction(
        #         shop_id=shop_id,
        #         transaction_data=transaction_data
        #     )

        #     completed_conversations.add(conversation_id)
        #     conversation_shops.pop(conversation_id, None)

        #     return jsonify({
        #         "status": "confirmed",
        #         "message": "Transaction saved successfully.",
        #         "conversation_id": conversation_id,
        #         "transaction": saved_transaction
        #     }), 200
                # 5. Persist only when the SERVER-SIDE pipeline confirms.
        if status == "confirmed":
            transaction_data = result.get("transaction")

            if not isinstance(transaction_data, dict):
                return jsonify({
                    "status": "error",
                    "message": "Confirmed transaction data is missing."
                }), 500

            # The NLU may represent no payment as None.
            if (
                transaction_data.get("transaction_type") == "purchase"
                and transaction_data.get("payment_mentioned") is False
            ):
                transaction_data["amount_paid"] = 0

            # Save the confirmed transaction in the database.
            saved_transaction = record_confirmed_transaction(
                shop_id=shop_id,
                transaction_data=transaction_data
            )

            # Mark the conversation as completed.
            completed_conversations.add(conversation_id)
            conversation_shops.pop(conversation_id, None)

            # Convert the AI-generated WAV response into Base64.
            response_audio = result.get("audio")
            audio_base64 = None

            if response_audio:
                audio_base64 = base64.b64encode(
                    response_audio
                ).decode("utf-8")

            # Return transaction details and audio to Flutter.
            return jsonify({
                "status": "confirmed",
                "message": "Transaction saved successfully.",
                "conversation_id": conversation_id,
                "transaction": saved_transaction,
                "audio_base64": audio_base64,
                "audio_content_type": (
                    "audio/wav" if audio_base64 else None
                )
            }), 200

        # 6. For missing information or confirmation, return AI response.
        response_audio = result.get("audio")

        audio_base64 = None

        if response_audio:
            audio_base64 = base64.b64encode(
                response_audio
            ).decode("utf-8")

        return jsonify({
            "status": status,
            "message": result.get("message"),
            "transcript": result.get("transcript"),
            "transaction": result.get("transaction"),
            "conversation_id": conversation_id,
            "audio_base64": audio_base64,
            "audio_content_type": "audio/wav" if audio_base64 else None
        }), 200

    except DuplicateCustomerError as error:
        return jsonify({
            "status": "needs_customer_clarification",
            "message": str(error),
            "candidates": error.candidates
        }), 409

    except ValueError as error:
        return jsonify({
            "status": "error",
            "message": str(error)
        }), 400

    except Exception:
        # Log the full exception on the server during development.
        import traceback
        traceback.print_exc()

        return jsonify({
            "status": "error",
            "message": "An unexpected error occurred while processing the voice request."
        }), 500
