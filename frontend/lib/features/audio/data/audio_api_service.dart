import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import 'analysis_models.dart';

class AudioApiService {
  AudioApiService({this.baseUrl = 'http://127.0.0.1:8000'});

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

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw StateError('API error ${streamed.statusCode}: $body');
    }

    return AudioAnalysisResponse.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }
}
