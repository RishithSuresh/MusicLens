import 'dart:convert';
import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import 'analysis_models.dart';

class AudioApiService {
  AudioApiService({this.baseUrl = AppConfig.apiBaseUrl});

  final String baseUrl;

  Future<AudioAnalysisResponse> analyzeAudio(PlatformFile file) async {
    final uri = Uri.parse('$baseUrl/analyze');
    final request = http.MultipartRequest('POST', uri);

    if (file.bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ),
      );
    } else if (file.path != null) {
      request.files.add(await http.MultipartFile.fromPath('file', file.path!));
    } else {
      throw StateError('Selected file has no readable bytes or path.');
    }

    late final http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw StateError('Request timed out. Please try again.');
    } on http.ClientException {
      throw StateError('Unable to reach the MusicLens API. Check backend URL/connectivity.');
    }
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw StateError(_buildApiError(streamed.statusCode, body));
    }

    return AudioAnalysisResponse.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  String _buildApiError(int statusCode, String body) {
    switch (statusCode) {
      case 400:
        return 'Invalid request: $body';
      case 413:
        return 'File is too large for analysis.';
      case 503:
        return 'Analysis service dependencies are not available on the server.';
      default:
        return 'API error $statusCode: $body';
    }
  }
}
