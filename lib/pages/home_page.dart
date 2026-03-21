import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/smithmk_theme.dart';

const _kTileSize = 110.0;
const _kGap = 12.0;
const _kStep = _kTileSize + _kGap;

class _Section {
  final String id;
  final String label;
  final String icon;
  final String summary;
  const _Section(this.id, this.label, this.icon, this.summary);
}

const _sections = [
  _Section("lights",    "LIGHTS",    "assets/icons/lighting.png",     "4 on · 8 off"),
  _Section("security",  "SECURITY",  "assets/icons/security.png",     "Armed Home"),
  _Section("blinds",    "BLINDS",    "assets/icons/blinds.png",       "2 open · 3 closed"),
  _Section("solar",     "SOLAR",     "assets/icons/energy_solar.png", "3.2kW · 🔋85%"),
  _Section("climate",   "CLIMATE",   "assets/icons/climate.png",      "22°C · Heating"),
  _Section("media",     "MEDIA",     "assets/icons/media.png",        "Not playing"),
  _Section("rooms",     "ROOMS",     "assets/icons/rooms.png",        "3 of 7 active"),
  _Section("energy",    "ENERGY",    "assets/icons/energy.png",       "Exporting 1.4kW"),
  _Section("dashboard", "DASHBOARD", "assets/icons/dashboard.png",    "Overview"),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  double _offset = 0;
  double _velocity = 0;
  double _startX = 0;
  double _startOffset = 0;
  double _lastX = 0;
  double _lastT = 0;
  bool _isDragging = false;
  bool _didDrag = false;
  int _activeIdx = 0;
  late AnimationController _snapController;
  late Animation<double> _snapAnimation;
  String _time = "";
  String _date = "";

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _snapAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    );
    _snapController.addListener(() {
      setState(() => _offset = _snapAnimation.value);
    });
    _snapController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        final nearest = (_offset / _kStep).round() * _kStep;
        _offset = nearest;
        _activeIdx = ((nearest / _kStep).round() % _sections.length + _sections.length) % _sections.length;
      }
    });
    _updateClock();
  }

  void _updateClock() {
    final now = DateTime.now();
    _time = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final days = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];
    final months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
    _date = "${days[now.weekday - 1]} ${now.day} ${months[now.month - 1]}";
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) setState(_updateClock);
    });
  }

  void _snapToNearest(double currentOffset, double velocity) {
    final projected = currentOffset + velocity * 80;
    final nearest = (projected / _kStep).round() * _kStep;
    _snapAnimation = Tween<double>(begin: currentOffset, end: nearest).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    );
    _snapController
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeSec = _sections[_activeIdx];
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFF0a0a0a)),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF8a6a2a), Color(0xFFc4a96b), Color(0xFFf0d080), Color(0xFFc4a96b), Color(0xFF8a6a2a)],
                          ).createShader(bounds),
                          child: const Text(
                            "SMITHMK HOME",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 3, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(_date, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1, color: Color(0x4DFFFFFF))),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_time, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w100, color: Color(0xEBFFFFFF), letterSpacing: -1)),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("☀️", style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 4),
                            const Text("19°C", style: TextStyle(fontSize: 11, color: Color(0x73FFFFFF))),
                            const SizedBox(width: 4),
                            const Text("Sunny", style: TextStyle(fontSize: 10, color: Color(0x40FFFFFF))),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status pills
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(
                  children: [
                    _statusPill("HA", true),
                    const SizedBox(width: 6),
                    _statusPill("SUPABASE", true),
                    const SizedBox(width: 6),
                    _statusPill("SOLAR", true),
                  ],
                ),
              ),

              // Carousel
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onHorizontalDragStart: (d) {
                        _snapController.stop();
                        _isDragging = true;
                        _didDrag = false;
                        _startX = d.localPosition.dx;
                        _startOffset = _offset;
                        _lastX = d.localPosition.dx;
                        _lastT = DateTime.now().millisecondsSinceEpoch.toDouble();
                        _velocity = 0;
                      },
                      onHorizontalDragUpdate: (d) {
                        if (!_isDragging) return;
                        final dx = d.localPosition.dx - _startX;
                        if (dx.abs() > 4) _didDrag = true;
                        setState(() => _offset = _startOffset - dx);
                        final now = DateTime.now().millisecondsSinceEpoch.toDouble();
                        final dt = now - _lastT;
                        if (dt > 0) _velocity = (_lastX - d.localPosition.dx) / dt;
                        _lastX = d.localPosition.dx;
                        _lastT = now;
                      },
                      onHorizontalDragEnd: (d) {
                        _isDragging = false;
                        _snapToNearest(_offset, _velocity);
                        HapticFeedback.selectionClick();
                      },
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        // TODO: navigate to section
                      },
                      child: SizedBox(
                        height: 160,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: _buildTiles(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Active label
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 3, height: 14, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: const Color(0xFFC4A96B))),
                        const SizedBox(width: 8),
                        Text(activeSec.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 3, color: Color(0x99FFFFFF))),
                        const SizedBox(width: 8),
                        Container(width: 3, height: 14, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: const Color(0xFFC4A96B))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(activeSec.summary, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFFFB84D), letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    const Text("TAP TO OPEN", style: TextStyle(fontSize: 10, color: Color(0x26FFFFFF), letterSpacing: 1)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTiles() {
    final centreIdx = (_offset / _kStep).round();
    const visibleRange = 4;
    final tiles = <Widget>[];
    final screenW = MediaQuery.of(context).size.width;

    for (int i = centreIdx - visibleRange; i <= centreIdx + visibleRange; i++) {
      final realIdx = ((i % _sections.length) + _sections.length) % _sections.length;
      final sec = _sections[realIdx];
      final dist = (i - centreIdx).abs();
      final tileOffset = i * _kStep - _offset;
      final scale = max(0.62, 1.0 - dist * 0.12);
      final opacity = max(0.2, 1.0 - dist * 0.22);
      final isActive = dist == 0;

      tiles.add(
        Positioned(
          left: screenW / 2 - _kTileSize / 2 + tileOffset,
          top: (160 - 110 * scale) / 2,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: _buildTile(sec, isActive),
            ),
          ),
        ),
      );
    }
    return tiles;
  }

  Widget _buildTile(_Section sec, bool isActive) {
    return Container(
      width: _kTileSize,
      height: _kTileSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x1AFFFFFF), Color(0x08FFFFFF), Color(0x12FFFFFF)],
        ),
        border: Border.all(
          color: isActive ? const Color(0x60C4A96B) : const Color(0x1AFFFFFF),
          width: 1,
        ),
        boxShadow: [
          const BoxShadow(color: Color(0x99000000), blurRadius: 40, offset: Offset(0, 20)),
          const BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 4)),
          if (isActive) BoxShadow(color: const Color(0xFFC4A96B).withValues(alpha: 0.3), blurRadius: 30),
        ],
      ),
      child: Stack(
        children: [
          // Top highlight line
          Positioned(top: 0, left: 0, right: 0, child: Container(height: 1, color: const Color(0x38FFFFFF))),
          // Bottom shadow line
          Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 2, color: const Color(0x66000000))),
          // Breathe glow for active
          if (isActive) Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 2500),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.0,
                  colors: [const Color(0xFFC4A96B).withValues(alpha: 0.16), Colors.transparent],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  sec.icon,
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                  color: isActive ? null : const Color(0x66FFFFFF),
                  colorBlendMode: isActive ? null : BlendMode.modulate,
                ),
                const SizedBox(height: 6),
                Text(
                  sec.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: isActive ? const Color(0xFFC4A96B) : const Color(0x47FFFFFF),
                  ),
                ),
              ],
            ),
          ),
          // Active bottom indicator
          if (isActive) Positioned(
            bottom: 6,
            left: _kTileSize / 2 - 10,
            child: Container(
              width: 20,
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                color: const Color(0xFFC4A96B),
                boxShadow: const [BoxShadow(color: Color(0xFFC4A96B), blurRadius: 8)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String label, bool online) {
    final color = online ? const Color(0xFF4CAF50) : const Color(0xFFef4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0x0AFFFFFF),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color, blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1, color: Color(0x66FFFFFF))),
        ],
      ),
    );
  }
}
