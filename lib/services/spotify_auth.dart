import 'dart:async';
import 'dart:html' as html;
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Spotify Implicit Grant flow — token returned directly in URL hash
/// No callbacks, no servers, no code exchange, one click login
class SpotifyAuth {
  static const clientId = '1bf984dbd8a84110bb6e1b29a589136c';
  static const _clientSecret = 'bc9a9b510e5a484b82285033297584f7';
  static const _scopes = 'user-modify-playback-state user-read-playback-state user-read-currently-playing';
  static const _redirectUri = 'https://example.com/callback';

  static String? _accessToken;
  static DateTime? _expiresAt;
  static String? _refreshToken;

  static bool get isAuthenticated => _accessToken != null && _expiresAt != null && DateTime.now().isBefore(_expiresAt!);

  static Future<String?> getToken() async {
    if (_accessToken != null && _expiresAt != null && DateTime.now().isBefore(_expiresAt!.subtract(const Duration(minutes: 2)))) {
      return _accessToken;
    }
    if (_refreshToken != null) return await _refresh();
    _loadFromStorage();
    if (_accessToken != null && _expiresAt != null && DateTime.now().isBefore(_expiresAt!)) return _accessToken;
    if (_refreshToken != null) return await _refresh();
    return null;
  }

  /// One-click login — opens popup, polls for token in URL hash
  static Future<bool> login() async {
    // Use Authorization Code flow but capture the redirect in the popup
    final authUrl = Uri.https('accounts.spotify.com', '/authorize', {
      'response_type': 'code',
      'client_id': clientId,
      'redirect_uri': _redirectUri,
      'scope': _scopes,
      'show_dialog': 'false',
    }).toString();

    final popup = html.window.open(authUrl, 'spotify_login', 'width=500,height=700');
    if (popup == null) return false;

    // Poll the popup URL every 500ms to detect redirect
    final completer = Completer<bool>();
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      try {
        if (popup.closed == true) {
          timer.cancel();
          if (!completer.isCompleted) completer.complete(false);
          return;
        }
        // Try to read the popup location — this will throw cross-origin error
        // until the redirect to example.com happens
        final href = (popup as dynamic).location.href as String?;
        if (href != null && href.contains('code=')) {
          timer.cancel();
          popup.close();
          // Extract code from URL
          final uri = Uri.parse(href);
          final code = uri.queryParameters['code'];
          if (code != null) {
            _exchangeCode(code).then((ok) {
              if (!completer.isCompleted) completer.complete(ok);
            });
          } else {
            if (!completer.isCompleted) completer.complete(false);
          }
        }
      } catch (_) {
        // Cross-origin — still on Spotify's domain, keep polling
      }
    });

    // Timeout after 3 minutes
    Timer(const Duration(minutes: 3), () {
      if (!completer.isCompleted) {
        try { popup.close(); } catch (_) {}
        completer.complete(false);
      }
    });

    return completer.future;
  }

  static Future<bool> _exchangeCode(String code) async {
    try {
      final resp = await http.post(Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'grant_type=authorization_code&code=${Uri.encodeComponent(code)}&redirect_uri=${Uri.encodeComponent(_redirectUri)}&client_id=$clientId&client_secret=$_clientSecret');
      if (resp.statusCode != 200) return false;
      final d = json.decode(resp.body);
      if (d['access_token'] == null) return false;
      _accessToken = d['access_token'];
      _refreshToken = d['refresh_token'];
      _expiresAt = DateTime.now().add(Duration(seconds: d['expires_in'] as int));
      _saveToStorage();
      return true;
    } catch (_) { return false; }
  }

  static Future<String?> _refresh() async {
    if (_refreshToken == null) return null;
    try {
      final resp = await http.post(Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'grant_type=refresh_token&refresh_token=$_refreshToken&client_id=$clientId&client_secret=$_clientSecret');
      if (resp.statusCode != 200) { _refreshToken = null; return null; }
      final d = json.decode(resp.body);
      _accessToken = d['access_token'];
      if (d['refresh_token'] != null) _refreshToken = d['refresh_token'];
      _expiresAt = DateTime.now().add(Duration(seconds: d['expires_in'] as int));
      _saveToStorage();
      return _accessToken;
    } catch (_) { return null; }
  }

  static void _saveToStorage() {
    html.window.localStorage['sp_at'] = _accessToken ?? '';
    html.window.localStorage['sp_rt'] = _refreshToken ?? '';
    html.window.localStorage['sp_exp'] = _expiresAt?.toIso8601String() ?? '';
  }

  static void _loadFromStorage() {
    _accessToken = html.window.localStorage['sp_at'];
    _refreshToken = html.window.localStorage['sp_rt'];
    final exp = html.window.localStorage['sp_exp'];
    _expiresAt = exp != null && exp.isNotEmpty ? DateTime.tryParse(exp) : null;
    if (_accessToken?.isEmpty == true) _accessToken = null;
    if (_refreshToken?.isEmpty == true) _refreshToken = null;
  }

  static void logout() {
    _accessToken = null; _refreshToken = null; _expiresAt = null;
    html.window.localStorage.remove('sp_at');
    html.window.localStorage.remove('sp_rt');
    html.window.localStorage.remove('sp_exp');
  }
}
