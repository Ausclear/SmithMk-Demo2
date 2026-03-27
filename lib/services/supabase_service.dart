import 'dart:convert';
import 'package:http/http.dart' as http;

/// Direct Supabase REST API — no SDK, just HTTP.
/// Table: smarthome_customisations
/// Schema: id (text, PK), category (text), data (jsonb)
class SupabaseService {
  static const _url = 'https://qraxdkzmteogkbfatvir.supabase.co';
  static const _key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFyYXhka3ptdGVvZ2tiZmF0dmlyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MzU5OTkyMSwiZXhwIjoyMDc5MTc1OTIxfQ.0HUnGAWyU0donigxUOoJSpeQNJMUP2HzaR3cID6yBFs';

  static Map<String, String> get _headers => {
    'apikey': _key,
    'Authorization': 'Bearer $_key',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  /// Get a customisation by id
  static Future<Map<String, dynamic>?> get(String id) async {
    try {
      final resp = await http.get(
        Uri.parse('$_url/rest/v1/smarthome_customisations?id=eq.$id&select=*'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final list = json.decode(resp.body) as List;
        if (list.isNotEmpty) return list.first as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Upsert a customisation (insert or update)
  static Future<bool> upsert(String id, String category, Map<String, dynamic> data) async {
    try {
      final resp = await http.post(
        Uri.parse('$_url/rest/v1/smarthome_customisations'),
        headers: {..._headers, 'Prefer': 'return=representation,resolution=merge-duplicates'},
        body: json.encode({'id': id, 'category': category, 'data': data}),
      ).timeout(const Duration(seconds: 5));
      return resp.statusCode == 200 || resp.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Get all customisations for a category
  static Future<List<Map<String, dynamic>>> getByCategory(String category) async {
    try {
      final resp = await http.get(
        Uri.parse('$_url/rest/v1/smarthome_customisations?category=eq.$category&select=*'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(resp.body));
      }
    } catch (_) {}
    return [];
  }

  /// Delete a customisation
  static Future<bool> delete(String id) async {
    try {
      final resp = await http.delete(
        Uri.parse('$_url/rest/v1/smarthome_customisations?id=eq.$id'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));
      return resp.statusCode == 200 || resp.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // ─── Light name overrides ───

  static Map<String, String> _nameCache = {};

  /// Load all custom light names from Supabase
  static Future<Map<String, String>> loadLightNames() async {
    try {
      final resp = await http.get(
        Uri.parse('$_url/rest/v1/smarthome_customisations?id=like.light:*&select=id,label'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        _nameCache = {};
        final list = json.decode(resp.body) as List;
        for (final row in list) {
          final id = row['id'] as String;
          final label = row['label'] as String?;
          if (label != null && label.isNotEmpty) {
            // id format: light:hue:3 or light:tapo:192.168.1.141
            final lightId = id.replaceFirst('light:', '');
            _nameCache[lightId] = label;
          }
        }
      }
    } catch (_) {}
    return _nameCache;
  }

  /// Get cached custom name for a light (or null if no override)
  static String? getCustomName(String lightId) => _nameCache[lightId];

  /// Save a custom name for a light
  static Future<bool> setLightName(String lightId, String customName) async {
    _nameCache[lightId] = customName;
    try {
      final resp = await http.post(
        Uri.parse('$_url/rest/v1/smarthome_customisations'),
        headers: {..._headers, 'Prefer': 'return=representation,resolution=merge-duplicates'},
        body: json.encode({
          'id': 'light:$lightId',
          'label': customName,
          'hidden': false,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 5));
      return resp.statusCode == 200 || resp.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Remove a custom name (revert to default)
  static Future<bool> removeLightName(String lightId) async {
    _nameCache.remove(lightId);
    return delete('light:$lightId');
  }
}
