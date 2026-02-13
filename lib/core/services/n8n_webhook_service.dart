import 'dart:convert';
import 'package:http/http.dart' as http;

class N8nWebhookService {
  static const String _webhookUrl =
      'https://quantumforge.app.n8n.cloud/webhook-test/968c94a5-e2f5-4962-9832-f7e88afbef18';
  static const String _secret = 'rentr_9Qk7sL3mX2vT8yA4';

  static Future<void> sendEvent({
    required String event,
    required Map<String, dynamic> payload,
  }) async {
    final body = {
      'event': event,
      'payload': payload,
      'sentAt': DateTime.now().toUtc().toIso8601String(),
    };

    final response = await http.post(
      Uri.parse(_webhookUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-Webhook-Secret': _secret,
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'n8n webhook failed: ${response.statusCode} ${response.body}',
      );
    }
  }
}
