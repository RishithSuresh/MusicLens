import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import 'composition_models.dart';

/// Thin client for the FastAPI `/compose` endpoint.
class ComposerApiService {
  ComposerApiService({this.baseUrl = AppConfig.apiBaseUrl});

  final String baseUrl;

  Future<CompositionResponse> compose({
    required String prompt,
    String? style,
    String? key,
    String? mode,
    int? tempoBpm,
    int? bars,
    bool useLlm = true,
  }) async {
    final uri = Uri.parse('$baseUrl/compose');
    final payload = <String, dynamic>{
      'prompt': prompt,
      'use_llm': useLlm,
      if (style != null && style.isNotEmpty) 'style': style,
      if (key != null && key.isNotEmpty) 'key': key,
      if (mode != null && mode.isNotEmpty) 'mode': mode,
      if (tempoBpm != null) 'tempo_bpm': tempoBpm,
      if (bars != null) 'bars': bars,
    };

    late final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw StateError('Request timed out. Please try again.');
    } on http.ClientException {
      throw StateError('Unable to reach the MusicLens API. Check backend URL/connectivity.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(_buildApiError(response.statusCode, response.body));
    }

    return CompositionResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<RandomPromptResponse> fetchRandomPrompt() async {
    final uri = Uri.parse('$baseUrl/random-prompt');
    late final http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw StateError('Random prompt request timed out.');
    } on http.ClientException {
      throw StateError('Unable to reach the MusicLens API. Check backend URL/connectivity.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(_buildApiError(response.statusCode, response.body));
    }

    return RandomPromptResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  String _buildApiError(int statusCode, String body) {
    switch (statusCode) {
      case 400:
      case 422:
        return 'Invalid compose request: $body';
      case 503:
        return 'Compose service dependencies are not available on the server.';
      default:
        return 'API error $statusCode: $body';
    }
  }
}
