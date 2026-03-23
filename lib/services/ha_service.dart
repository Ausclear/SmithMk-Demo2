import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class HAService {
  static const pwaBase = 'https://smarthome-eight-livid.vercel.app';
  static const haInternal = 'http://192.168.1.101:8123';
  static const haExternal = 'http://202.62.130.27:8123';
  static const haToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiIwOWI5OTlmY2JmMWY0OWQwYTFiYzBiMmM1M2NiZTgyMiIsImlhdCI6MTc3MzExOTk5OSwiZXhwIjoyMDg4NDc5OTk5fQ.0HfaVvG4_Ld5xuxzejS5sWxi5jRGREkNrPXN3s-uM0k';

  static Future<List<Map<String, dynamic>>> getStates() async {
    if (kIsWeb) {
      final resp = await http.get(Uri.parse('$pwaBase/api/ha/states')).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) return List<Map<String, dynamic>>.from(json.decode(resp.body));
      throw Exception('HA states via proxy failed: ${resp.statusCode}');
    } else {
      final url = await _resolveUrl();
      final resp = await http.get(Uri.parse('$url/api/states'),
        headers: {'Authorization': 'Bearer $haToken', 'Content-Type': 'application/json'}).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) return List<Map<String, dynamic>>.from(json.decode(resp.body));
      throw Exception('HA states direct failed: ${resp.statusCode}');
    }
  }

  static Future<List<Map<String, dynamic>>> getEntities(String domain) async {
    final all = await getStates();
    return all.where((e) => (e['entity_id'] as String).startsWith('$domain.')).toList();
  }

  static Future<void> callService(String domain, String service, Map<String, dynamic> data) async {
    if (kIsWeb) {
      final resp = await http.post(Uri.parse('$pwaBase/api/ha/service'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'domain': domain, 'service': service, 'data': data})).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) throw Exception('HA service via proxy failed: ${resp.statusCode}');
    } else {
      final url = await _resolveUrl();
      final resp = await http.post(Uri.parse('$url/api/services/$domain/$service'),
        headers: {'Authorization': 'Bearer $haToken', 'Content-Type': 'application/json'},
        body: json.encode(data)).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) throw Exception('HA service direct failed: ${resp.statusCode}');
    }
  }

  static Future<void> mediaPlayPause(String entityId) => callService('media_player', 'media_play_pause', {'entity_id': entityId});
  static Future<void> mediaNext(String entityId) => callService('media_player', 'media_next_track', {'entity_id': entityId});
  static Future<void> mediaPrev(String entityId) => callService('media_player', 'media_previous_track', {'entity_id': entityId});
  static Future<void> mediaStop(String entityId) => callService('media_player', 'media_stop', {'entity_id': entityId});
  static Future<void> mediaVolume(String entityId, double level) => callService('media_player', 'volume_set', {'entity_id': entityId, 'volume_level': level});

  static Future<void> playSpotify(String uri, String source) async {
    final resp = await http.post(Uri.parse('$pwaBase/api/ha/play-spotify'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'uri': uri, 'source': source})).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) throw Exception('play-spotify failed: ${resp.statusCode} ${resp.body}');
  }

  static String? _resolvedUrl;
  static Future<String> _resolveUrl() async {
    if (_resolvedUrl != null) return _resolvedUrl!;
    try {
      final r = await http.get(Uri.parse('$haInternal/api/'), headers: {'Authorization': 'Bearer $haToken'}).timeout(const Duration(seconds: 3));
      if (r.statusCode == 200) { _resolvedUrl = haInternal; return haInternal; }
    } catch (_) {}
    _resolvedUrl = haExternal;
    return haExternal;
  }
}
