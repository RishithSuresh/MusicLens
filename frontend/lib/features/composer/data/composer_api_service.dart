import 'dart:convert';

import 'package:http/http.dart' as http;

import 'composition_models.dart';

/// Thin client for the FastAPI `/compose` endpoint.
class ComposerApiService {
  ComposerApiService({this.baseUrl = 'http://127.0.0.1:8000'});

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

    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('API error ${response.statusCode}: ${response.body}');
    }

    return CompositionResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
