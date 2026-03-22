import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../theme/smithmk_theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();
  double _targetTemp = 22.0;
  final double _currentTemp = 19.0;
  bool _heatingOn = true;
  int _activeScene = 1; // Day

  String get _greeting {
    final h = _now.hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _timeStr =>
      '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}';

  String get _dateStr {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${days[_now.weekday - 1]} ${_now.day} ${months[_now.month - 1]}';
  }

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmithMkColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(isWide ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  if (isWide)
                    _buildTwoColumnLayout()
                  else
                    _buildSingleColumnLayout(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── HEADER ───
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_greeting, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: SmithMkColors.gold)),
            const SizedBox(height: 2),
            Text(_dateStr, style: const TextStyle(fontSize: 12, color: SmithMkColors.textTertiary)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_timeStr, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w200, color: SmithMkColors.textPrimary, letterSpacing: -1, height: 1, fontFeatures: [FontFeature.tabularFigures()])),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('☀️ ', style: TextStyle(fontSize: 14)),
                Text('${_currentTemp.round()}°', style: const TextStyle(fontSize: 13, color: SmithMkColors.textSecondary)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ─── TWO COLUMN LAYOUT (tablet/desktop) ───
  Widget _buildTwoColumnLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column
        Expanded(
          child: Column(
            children: [
              _buildWeatherCard(),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildClimateCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildSecurityCard()),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildLightsCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildEVCard()),
              ]),
              const SizedBox(height: 12),
              _buildEnergyCard(),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Right column
        Expanded(
          child: Column(
            children: [
              _buildScenesCard(),
              const SizedBox(height: 12),
              _buildRoomsCard(),
              const SizedBox(height: 12),
              _buildActivityCard(),
            ],
          ),
        ),
      ],
    );
  }

  // ─── SINGLE COLUMN LAYOUT (phone) ───
  Widget _buildSingleColumnLayout() {
    return Column(
      children: [
        _buildWeatherCard(),
        const SizedBox(height: 12),
        _buildScenesCard(),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildClimateCard()),
          const SizedBox(width: 12),
          Expanded(child: _buildSecurityCard()),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildLightsCard()),
          const SizedBox(width: 12),
          Expanded(child: _buildEVCard()),
        ]),
        const SizedBox(height: 12),
        _buildEnergyCard(),
        const SizedBox(height: 12),
        _buildRoomsCard(),
        const SizedBox(height: 12),
        _buildActivityCard(),
      ],
    );
  }

  // ─── CARD WRAPPER ───
  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SmithMkColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SmithMkColors.glassBorder),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SmithMkColors.textTertiary, letterSpacing: 1.5));
  }

  // ─── WEATHER CARD ───
  Widget _buildWeatherCard() {
    final forecast = [
      _Forecast('Sun', '☀️', 29, 16),
      _Forecast('Mon', '🌤️', 30, 15),
      _Forecast('Tue', '🌙', 31, 18),
      _Forecast('Wed', '❄️', 23, 16),
      _Forecast('Thu', '☁️', 17, 14),
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('☀️', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_currentTemp.round()}° Clearsky', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: SmithMkColors.textPrimary)),
                  Text('Feels ${_currentTemp.round()}° · 💧 68% · 💨 6 km/h', style: const TextStyle(fontSize: 11, color: SmithMkColors.textTertiary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: forecast.map((f) => Column(
              children: [
                Text(f.day, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: SmithMkColors.textTertiary)),
                const SizedBox(height: 4),
                Text(f.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 4),
                Text('${f.high}°', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SmithMkColors.textPrimary)),
                Text('${f.low}°', style: const TextStyle(fontSize: 10, color: SmithMkColors.textTertiary)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  // ─── CLIMATE CARD ───
  Widget _buildClimateCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('CLIMATE'),
              const Text('🌡️', style: TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 8),
          Text('${_currentTemp}°', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: SmithMkColors.textPrimary)),
          Text(_heatingOn ? 'Heating to ${_targetTemp.round()}°' : '—', style: TextStyle(fontSize: 11, color: _heatingOn ? SmithMkColors.heatingMode : SmithMkColors.textTertiary)),
        ],
      ),
    );
  }

  // ─── SECURITY CARD ───
  Widget _buildSecurityCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('SECURITY'),
              const Text('🛡️', style: TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Disarmed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF4ADE80))),
          const Text('1 open · 10 zones', style: TextStyle(fontSize: 11, color: SmithMkColors.textTertiary)),
        ],
      ),
    );
  }

  // ─── LIGHTS CARD ───
  Widget _buildLightsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('LIGHTS'),
              const Text('💡', style: TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('0/4', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: SmithMkColors.textPrimary)),
          const Text('0 rooms active', style: TextStyle(fontSize: 11, color: SmithMkColors.textTertiary)),
        ],
      ),
    );
  }

  // ─── EV CARD ───
  Widget _buildEVCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('EV'),
              const Text('⚡', style: TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Disconnected', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: SmithMkColors.textPrimary)),
          const Text('No EV plugged in', style: TextStyle(fontSize: 11, color: SmithMkColors.textTertiary)),
        ],
      ),
    );
  }

  // ─── ENERGY CARD ───
  Widget _buildEnergyCard() {
    final items = [
      _EnergyItem('Solar', '0', 'W'),
      _EnergyItem('Battery', '0', '%'),
      _EnergyItem('Home', '0', 'W'),
      _EnergyItem('EV', '0', 'W'),
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('ENERGY'),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((e) => Column(
              children: [
                Text('${e.value}${e.unit}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: SmithMkColors.textPrimary)),
                const SizedBox(height: 4),
                Text(e.label, style: const TextStyle(fontSize: 10, color: SmithMkColors.textTertiary)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  // ─── SCENES CARD ───
  Widget _buildScenesCard() {
    final scenes = [
      _Scene('Morning', '🌅', 0),
      _Scene('Day', '☀️', 1),
      _Scene('Evening', '🏠', 2),
      _Scene('Night', '🌙', 3),
      _Scene('Away', '🏖️', 4),
      _Scene('Movie', '🎬', 5),
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('SCENES'),
              const Text('Tap to activate', style: TextStyle(fontSize: 10, color: SmithMkColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: scenes.map((s) {
                final isActive = _activeScene == s.index;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _activeScene = s.index);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? SmithMkColors.accent.withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive ? SmithMkColors.accent.withValues(alpha: 0.3) : SmithMkColors.glassBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(s.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(s.name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isActive ? SmithMkColors.accent : SmithMkColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ROOMS CARD ───
  Widget _buildRoomsCard() {
    final rooms = [
      _Room('Master Bedroom', '🛏️', 0, 2),
      _Room('Lounge', '🛋️', 0, 2),
      _Room('Office', '💻', 0, 0),
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('ROOMS'),
              const Text('All →', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SmithMkColors.accent)),
            ],
          ),
          const SizedBox(height: 10),
          ...rooms.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: SmithMkColors.cardSurfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(r.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(child: Text(r.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: SmithMkColors.textPrimary))),
                Text('${r.lightsOn}/${r.lightsTotal}', style: const TextStyle(fontSize: 12, color: SmithMkColors.textTertiary)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: SmithMkColors.inactive.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('OFF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SmithMkColors.textTertiary)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ─── ACTIVITY CARD ───
  Widget _buildActivityCard() {
    final events = [
      _ActivityEvent('💡', 'Entrance 2 → off', '11:28'),
      _ActivityEvent('💡', 'Alfresco → off', '11:19'),
      _ActivityEvent('💡', 'Entrance 2 → off', '11:16'),
      _ActivityEvent('💡', 'Entrance 1 → off', '11:16'),
      _ActivityEvent('💡', 'Alfresco → off', '11:14'),
      _ActivityEvent('💡', 'Entrance 1 → off', '11:13'),
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('ACTIVITY'),
          const SizedBox(height: 12),
          ...events.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                // Timeline dot
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: SmithMkColors.accent,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: SmithMkColors.accent.withValues(alpha: 0.3), blurRadius: 4)],
                  ),
                ),
                const SizedBox(width: 12),
                Text(e.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(child: Text(e.description, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: SmithMkColors.textPrimary))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: SmithMkColors.cardSurfaceAlt,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(e.time, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: SmithMkColors.textTertiary, fontFeatures: [FontFeature.tabularFigures()])),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ─── DATA MODELS ───
class _Forecast {
  final String day, emoji;
  final int high, low;
  const _Forecast(this.day, this.emoji, this.high, this.low);
}

class _EnergyItem {
  final String label, value, unit;
  const _EnergyItem(this.label, this.value, this.unit);
}

class _Scene {
  final String name, emoji;
  final int index;
  const _Scene(this.name, this.emoji, this.index);
}

class _Room {
  final String name, emoji;
  final int lightsOn, lightsTotal;
  const _Room(this.name, this.emoji, this.lightsOn, this.lightsTotal);
}

class _ActivityEvent {
  final String emoji, description, time;
  const _ActivityEvent(this.emoji, this.description, this.time);
}
