
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class VoiceService {
  String? _conversationId;

  Future<Map<String, dynamic>> sendAudio({
    required String audioPath,
    required String languageCode,
  }) async {
    // 1. Verify that the recorded audio file exists.
    final audioFile = File(audioPath);

    if (!await audioFile.exists()) {
      throw Exception('Recorded audio file does not exist.');
    }

    // 2. Retrieve the registered shop ID.
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getInt('shop_id');

    if (shopId == null || shopId <= 0) {
      throw Exception('Shop ID not found. Please register your shop.');
    }

    // 3. Prepare the Flask voice endpoint.
    final uri = Uri.parse('${ApiConfig.voiceUrl}/turn');

    final request = http.MultipartRequest('POST', uri);

    // 4. Add the required form fields.
    request.fields['shop_id'] = shopId.toString();
    request.fields['language_code'] = languageCode;

    // 5. Continue an existing voice conversation if available.
    if (_conversationId != null) {
      request.fields['conversation_id'] = _conversationId!;
    }

    // 6. Attach the recorded WAV audio.
    request.files.add(
      await http.MultipartFile.fromPath(
        'audio',
        audioPath,
        filename: 'voice_transaction.wav',
      ),
    );

    // 7. Send the request to Flask.
    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(
      streamedResponse,
    );

    // 8. Decode the backend response.
    final decodedResponse = jsonDecode(response.body);

    if (decodedResponse is! Map<String, dynamic>) {
      throw Exception('Invalid response received from server.');
    }

    final data = decodedResponse;

    // 9. Store the conversation ID for the next voice turn.
    final returnedConversationId = data['conversation_id'];

    if (returnedConversationId is String) {
      _conversationId = returnedConversationId;
    }

    // 10. End the local conversation after completion or cancellation.
    final status = data['status'];

    if (status == 'confirmed' || status == 'cancelled') {
      _conversationId = null;
    }

    // Return the backend response, including error responses.
    return data;
  }

  // Start a fresh conversation.
  void resetConversation() {
    _conversationId = null;
  }
}
