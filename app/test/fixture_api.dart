import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:purnara/data/api_client.dart';
import 'package:purnara/data/models.dart';

/// Loads answers recorded from the real backend by `backend/scripts/record_app_fixtures.py`:
/// the sample project, in Indonesian ('id') or English ('en'), on 2026-10-05, without AI.
Json loadSampleFixture(String locale) => Json.from(jsonDecode(File('test/fixtures/sample_$locale.json').readAsStringSync()) as Map);

/// An [ApiClient] that replays recorded answers instead of calling a server.
///
/// Reads come straight from the recording. Writes get a plausible answer built from it
/// (a task update returns the task with the change applied, and so on). Every call is
/// logged; a request the recording cannot answer lands in [misses] and fails with 404,
/// so a test can prove that a screen only asked for what the API really offers.
class FixtureApiClient extends ApiClient {
  FixtureApiClient(Json fixture) : answers = Json.from(fixture['answers'] as Map), super('http://fixture');

  /// The recording, keyed "METHOD /path"; a test may change an answer before the app asks.
  final Json answers;

  /// Called on every request, before it is answered.
  void Function(String key)? onCall;

  /// Every request, as "METHOD /path".
  final calls = <String>[];

  /// Bodies of the writes, in order.
  final writes = <(String, Object?)>[];

  /// Requests the recording had no answer for.
  final misses = <String>[];

  /// Requests starting with one of these fail with a server error.
  final failing = <String>{};

  Object? _copy(Object? value) => value == null ? null : jsonDecode(jsonEncode(value));

  Json _json(String key) => Json.from(_copy(answers[key]) as Map);

  Future<T> _answer<T>(String method, String path, {Map<String, dynamic>? query, Object? data}) async {
    final params = {for (final e in (query ?? const <String, dynamic>{}).entries) e.key: '${e.value}'};
    final key = '$method $path${params.isEmpty ? '' : '?${Uri(queryParameters: params).query}'}';
    calls.add(key);
    if (method != 'GET') writes.add((key, data));
    onCall?.call(key);
    if (failing.any(key.startsWith)) throw const ApiException('unknown', status: 500);
    if (answers.containsKey(key)) return _copy(answers[key]) as T;
    final written = _write(method, path, data is Map ? Json.from(data) : const <String, dynamic>{});
    if (written != null) return written.$1 as T;
    misses.add(key);
    throw const ApiException('not_found', status: 404);
  }

  /// A believable answer to a write the recording did not make.
  (Object?,)? _write(String method, String path, Json data) {
    final parts = path.split('/');
    if (method == 'DELETE') return (null,);
    if (method == 'PATCH' && parts.length == 3 && parts[1] == 'tasks') return ({..._json('GET $path'), ...data},);
    if (method == 'PATCH' && path == '/me') return ({..._json('GET /me'), ...data},);
    if (method == 'PATCH' && parts.length == 3 && parts[1] == 'projects') {
      final projects = _copy(answers['GET /projects']) as List;
      final project = projects.cast<Map<String, dynamic>>().firstWhere((p) => p['id'] == parts[2]);
      return ({...project, ...data},);
    }
    if (method == 'POST' && parts.length == 4 && parts[1] == 'suggestions') {
      final status = parts[3] == 'apply' ? 'applied' : 'rejected';
      return ({..._json('GET /suggestions/${parts[2]}'), 'status': status},);
    }
    if (method == 'POST' && parts.length == 4 && parts[1] == 'notifications') return (null,);
    if (method == 'PUT' && parts.length == 4 && parts[3] == 'brief') {
      final brief = _json('GET /projects/${parts[2]}/brief');
      return ({...brief, 'content': data['content'], 'version': (brief['version'] as int) + 1},);
    }
    return null;
  }

  @override
  Future<T> get<T>(String path, {Map<String, dynamic>? query}) => _answer('GET', path, query: query);

  @override
  Future<T> post<T>(String path, {Object? data}) => _answer('POST', path, data: data);

  @override
  Future<T> put<T>(String path, {Object? data}) => _answer('PUT', path, data: data);

  @override
  Future<T> patch<T>(String path, {Object? data}) => _answer('PATCH', path, data: data);

  @override
  Future<void> delete(String path) => _answer<dynamic>('DELETE', path);

  @override
  Future<T> upload<T>(String path, {required String fileName, required Uint8List bytes}) => _answer('POST', path, data: {'file': fileName});
}
