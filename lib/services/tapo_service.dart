import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Tapo device control via local proxy on VM at 192.168.1.47:4500
/// Proxy discovers devices via TP-Link cloud, controls locally.
/// Polls state every 10s. Re-discovers every 5 mins.
class TapoService {
  static const _proxyUrl = 'http://192.168.1.47:4500';
  static Timer? _pollTimer;
  static final _stateController = StreamController<Map<String, TapoDevice>>.broadcast();
  static Map<String, TapoDevice> _devices = {};

  /// Get all devices (cached)
  static Map<String, TapoDevice> get devices => _devices;

  /// Stream of device state updates
  static Stream<Map<String, TapoDevice>> get stateStream => _stateController.stream;

  /// Start polling the proxy for device state
  static void startPolling() {
    fetchDevices(); // immediate first fetch
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => fetchDevices());
  }

  static void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Fetch all devices from the proxy
  static Future<Map<String, TapoDevice>> fetchDevices() async {
    try {
      final resp = await http.get(Uri.parse('$_proxyUrl/api/tapo/devices'))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode != 200) return _devices;
      
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final newDevices = <String, TapoDevice>{};
      
      data.forEach((alias, info) {
        final type = (info['type'] as String?) ?? '';
        final model = (info['model'] as String?) ?? '';
        final isStrip = type.contains('BULB') || model.contains('L9') || model.contains('L5');
        
        newDevices[alias] = TapoDevice(
          alias: alias,
          nickname: (info['nickname'] as String?) ?? alias,
          ip: (info['ip'] as String?) ?? '',
          mac: (info['mac'] as String?) ?? '',
          type: type,
          model: model,
          isPlug: !isStrip,
          on: (info['deviceOn'] as bool?) ?? false,
          brightness: (info['brightness'] as num?)?.toInt() ?? 0,
          hue: (info['hue'] as num?)?.toInt() ?? 0,
          saturation: (info['saturation'] as num?)?.toInt() ?? 0,
          colorTemp: (info['colorTemp'] as num?)?.toInt() ?? 0,
          reachable: (info['reachable'] as bool?) ?? false,
        );
      });
      
      _devices = newDevices;
      _stateController.add(_devices);
      return _devices;
    } catch (_) {
      return _devices;
    }
  }

  /// Force proxy to re-discover devices (finds new ones)
  static Future<Map<String, TapoDevice>> discover() async {
    try {
      final resp = await http.post(Uri.parse('$_proxyUrl/api/tapo/discover'))
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        return fetchDevices();
      }
    } catch (_) {}
    return _devices;
  }

  static Future<void> turnOn(String ip) async {
    await http.post(Uri.parse('$_proxyUrl/api/tapo/on'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'ip': ip})).timeout(const Duration(seconds: 5));
  }

  static Future<void> turnOff(String ip) async {
    await http.post(Uri.parse('$_proxyUrl/api/tapo/off'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'ip': ip})).timeout(const Duration(seconds: 5));
  }

  static Future<void> setBrightness(String ip, int brightness) async {
    await http.post(Uri.parse('$_proxyUrl/api/tapo/brightness'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'ip': ip, 'brightness': brightness.clamp(1, 100)})).timeout(const Duration(seconds: 5));
  }

  static Future<void> setColour(String ip, int hue, int saturation, int brightness) async {
    await http.post(Uri.parse('$_proxyUrl/api/tapo/colour'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'ip': ip, 'hue': hue, 'saturation': saturation, 'brightness': brightness})).timeout(const Duration(seconds: 5));
  }
}

class TapoDevice {
  final String alias, nickname, ip, mac, type, model;
  final bool isPlug;
  bool on;
  int brightness, hue, saturation, colorTemp;
  bool reachable;

  TapoDevice({
    required this.alias, required this.nickname, required this.ip,
    required this.mac, required this.type, required this.model,
    required this.isPlug, this.on = false, this.brightness = 0,
    this.hue = 0, this.saturation = 0, this.colorTemp = 0,
    this.reachable = false,
  });
}
