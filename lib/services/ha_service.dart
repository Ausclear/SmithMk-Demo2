import 'dart:convert';
import 'package:http/http.dart' as http;

/// HA service — routes through the local PWA on the Ubuntu VM (no CORS issues)
class HAService {
  // Local PWA running on Ubuntu VM — same network, no CORS
  static const apiBase = 'http://192.168.1.47:3000';
  // Direct HA URL for image loading etc
  static const haUrl = 'http://192.168.1.101:8123';

  static Future<List<Map<String, dynamic>>> getStates() async {
    final resp = await http.get(Uri.parse('$apiBase/api/ha/states')).timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200) return List<Map<String, dynamic>>.from(json.decode(resp.body));
    throw Exception('HA states failed: ${resp.statusCode}');
  }

  static Future<List<Map<String, dynamic>>> getEntities(String domain) async {
    final all = await getStates();
    return all.where((e) => (e['entity_id'] as String).startsWith('$domain.')).toList();
  }

  static Future<void> callService(String domain, String service, Map<String, dynamic> data) async {
    final resp = await http.post(Uri.parse('$apiBase/api/ha/service'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'domain': domain, 'service': service, 'data': data})).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) throw Exception('HA $domain/$service failed: ${resp.statusCode}');
  }

  static Future<void> mediaPlayPause(String entityId) => callService('media_player', 'media_play_pause', {'entity_id': entityId});
  static Future<void> mediaNext(String entityId) => callService('media_player', 'media_next_track', {'entity_id': entityId});
  static Future<void> mediaPrev(String entityId) => callService('media_player', 'media_previous_track', {'entity_id': entityId});
  static Future<void> mediaStop(String entityId) => callService('media_player', 'media_stop', {'entity_id': entityId});
  static Future<void> mediaVolume(String entityId, double level) => callService('media_player', 'volume_set', {'entity_id': entityId, 'volume_level': level});

  static Future<void> playSpotify(String uri, String source) async {
    final resp = await http.post(Uri.parse('$apiBase/api/ha/play-spotify'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'uri': uri, 'source': source})).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) throw Exception('play-spotify failed: ${resp.statusCode}');
  }
}
