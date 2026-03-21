import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/smithmk_theme.dart';
import '../widgets/glass_card.dart';

class DashboardDemo extends StatefulWidget {
  const DashboardDemo({super.key});

  @override
  State<DashboardDemo> createState() => _DashboardDemoState();
}

class _DashboardDemoState extends State<DashboardDemo> with TickerProviderStateMixin {
  // Demo state
  double _temperature = 22.4;
  double _targetTemp = 22.0;
  bool _heatingOn = true;
  double _livingBrightness = 0.75;
  double _bedroomBrightness = 0.0;
  double _kitchenBrightness = 0.45;
  double _blindPosition = 0.65;
  bool _securityArmed = true;
  bool _frontDoorLocked = true;
  bool _garageLocked = true;
  String _currentScene = '';
  double _solarKw = 3.2;
  double _homeKw = 1.8;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _sceneFlashController;
  late Animation<double> _sceneFlashAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _sceneFlashController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _sceneFlashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sceneFlashController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sceneFlashController.dispose();
    super.dispose();
  }

  void _activateScene(String scene) {
    HapticFeedback.heavyImpact();
    setState(() {
      _currentScene = scene;
      switch (scene) {
        case 'Morning':
          _livingBrightness = 0.8;
          _kitchenBrightness = 1.0;
          _bedroomBrightness = 0.3;
          _blindPosition = 1.0;
          _targetTemp = 22.0;
          _heatingOn = true;
          break;
        case 'Movie':
          _livingBrightness = 0.15;
          _kitchenBrightness = 0.0;
          _bedroomBrightness = 0.0;
          _blindPosition = 0.0;
          break;
        case 'Good Night':
          _livingBrightness = 0.0;
          _kitchenBrightness = 0.0;
          _bedroomBrightness = 0.05;
          _blindPosition = 0.0;
          _targetTemp = 18.0;
          _securityArmed = true;
          _frontDoorLocked = true;
          _garageLocked = true;
          break;
        case 'Away':
          _livingBrightness = 0.0;
          _kitchenBrightness = 0.0;
          _bedroomBrightness = 0.0;
          _blindPosition = 0.0;
          _securityArmed = true;
          _frontDoorLocked = true;
          _garageLocked = true;
          _heatingOn = false;
          break;
      }
    });
    _sceneFlashController.forward(from: 0.0);
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.lightImpact();
    });
  }

  int get _activeLightCount {
    int count = 0;
    if (_livingBrightness > 0) count++;
    if (_bedroomBrightness > 0) count++;
    if (_kitchenBrightness > 0) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A0A14), Color(0xFF0F1020), Color(0xFF0A0F18)],
              ),
            ),
          ),
          // Scene flash overlay
          AnimatedBuilder(
            animation: _sceneFlashAnimation,
            builder: (context, child) {
              return IgnorePointer(
                child: Container(
                  color: SmithMkColors.accentPrimary.withValues(
                    alpha: _sceneFlashAnimation.value * 0.08 * (1 - _sceneFlashAnimation.value),
                  ),
                ),
              );
            },
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildStatusBar(),
                  const SizedBox(height: 24),
                  _buildSceneRow(),
                  const SizedBox(height: 28),
                  _buildSectionTitle('CLIMATE'),
                  const SizedBox(height: 12),
                  _buildThermostat(),
                  const SizedBox(height: 28),
                  _buildSectionTitle('LIGHTING'),
                  const SizedBox(height: 12),
                  _buildLightingControls(),
                  const SizedBox(height: 28),
                  _buildSectionTitle('BLINDS'),
                  const SizedBox(height: 12),
                  _buildBlindControl(),
                  const SizedBox(height: 28),
                  _buildSectionTitle('SECURITY'),
                  const SizedBox(height: 12),
                  _buildSecurityPanel(),
                  const SizedBox(height: 28),
                  _buildSectionTitle('ENERGY'),
                  const SizedBox(height: 12),
                  _buildEnergyPanel(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SmithMk', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: SmithMkColors.accentPrimary, letterSpacing: 1)),
            const SizedBox(height: 2),
            Text('Dashboard Demo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: SmithMkColors.textTertiary, letterSpacing: 0.5)),
          ],
        ),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          borderRadius: 12,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: SmithMkColors.success.withValues(alpha: _pulseAnimation.value),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: SmithMkColors.success.withValues(alpha: _pulseAnimation.value * 0.5), blurRadius: 6)],
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              const Text('Connected', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: SmithMkColors.success)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBar() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statusItem(PhosphorIcons.shieldCheck(PhosphorIconsStyle.light), _securityArmed ? 'Armed' : 'Disarmed', _securityArmed ? SmithMkColors.success : SmithMkColors.error),
          _divider(),
          _statusItem(PhosphorIcons.lockSimple(PhosphorIconsStyle.light), _frontDoorLocked ? 'Locked' : 'Unlocked', _frontDoorLocked ? SmithMkColors.success : SmithMkColors.warning),
          _divider(),
          _statusItem(PhosphorIcons.lightbulb(PhosphorIconsStyle.light), '$_activeLightCount On', _activeLightCount > 0 ? SmithMkColors.accentPrimary : SmithMkColors.textTertiary),
          _divider(),
          _statusItem(PhosphorIcons.sunDim(PhosphorIconsStyle.light), '${_solarKw}kW', SmithMkColors.accentPrimary),
        ],
      ),
    );
  }

  Widget _statusItem(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 28, color: SmithMkColors.glassBorder);

  Widget _buildSceneRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _sceneButton(PhosphorIcons.sun(PhosphorIconsStyle.light), 'Morning', SmithMkColors.accentPrimary),
          _sceneButton(PhosphorIcons.filmSlate(PhosphorIconsStyle.light), 'Movie', SmithMkColors.accentPurple),
          _sceneButton(PhosphorIcons.moonStars(PhosphorIconsStyle.light), 'Good Night', const Color(0xFF5C6BC0)),
          _sceneButton(PhosphorIcons.signOut(PhosphorIconsStyle.light), 'Away', SmithMkColors.error),
        ],
      ),
    );
  }

  Widget _sceneButton(IconData icon, String label, Color color) {
    final isActive = _currentScene == label;
    return GestureDetector(
      onTap: () => _activateScene(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.2) : SmithMkColors.glassOverlay,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? color.withValues(alpha: 0.5) : SmithMkColors.glassBorder,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 12)] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? color : SmithMkColors.textSecondary, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: isActive ? color : SmithMkColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SmithMkColors.textTertiary, letterSpacing: 1.5));
  }

  // ─── THERMOSTAT ───
  Widget _buildThermostat() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: CustomPaint(
              size: const Size(200, 200),
              painter: _ThermostatPainter(
                currentTemp: _temperature,
                targetTemp: _targetTemp,
                isHeating: _heatingOn,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_targetTemp.toStringAsFixed(1)}°',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w200, color: SmithMkColors.textPrimary),
                    ),
                    Text(
                      _heatingOn ? 'HEATING' : 'OFF',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5,
                        color: _heatingOn ? SmithMkColors.heatingActive : SmithMkColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Currently ${_temperature.toStringAsFixed(1)}°',
                      style: const TextStyle(fontSize: 12, color: SmithMkColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tempButton(PhosphorIcons.minus(PhosphorIconsStyle.bold), () {
                HapticFeedback.selectionClick();
                setState(() => _targetTemp = (_targetTemp - 0.5).clamp(16.0, 30.0));
              }),
              const SizedBox(width: 40),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _heatingOn = !_heatingOn);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: _heatingOn ? SmithMkColors.heatingActive.withValues(alpha: 0.2) : SmithMkColors.glassOverlay,
                    shape: BoxShape.circle,
                    border: Border.all(color: _heatingOn ? SmithMkColors.heatingActive.withValues(alpha: 0.5) : SmithMkColors.glassBorder),
                  ),
                  child: Icon(
                    PhosphorIcons.power(PhosphorIconsStyle.bold),
                    color: _heatingOn ? SmithMkColors.heatingActive : SmithMkColors.textTertiary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 40),
              _tempButton(PhosphorIcons.plus(PhosphorIconsStyle.bold), () {
                HapticFeedback.selectionClick();
                setState(() => _targetTemp = (_targetTemp + 0.5).clamp(16.0, 30.0));
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tempButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: SmithMkColors.glassOverlay,
          shape: BoxShape.circle,
          border: Border.all(color: SmithMkColors.glassBorder),
        ),
        child: Icon(icon, color: SmithMkColors.textPrimary, size: 18),
      ),
    );
  }

  // ─── LIGHTING ───
  Widget _buildLightingControls() {
    return Column(
      children: [
        _lightSlider('Living Room', PhosphorIcons.armchair(PhosphorIconsStyle.light), _livingBrightness, (v) => setState(() => _livingBrightness = v)),
        const SizedBox(height: 12),
        _lightSlider('Bedroom', PhosphorIcons.bed(PhosphorIconsStyle.light), _bedroomBrightness, (v) => setState(() => _bedroomBrightness = v)),
        const SizedBox(height: 12),
        _lightSlider('Kitchen', PhosphorIcons.cookingPot(PhosphorIconsStyle.light), _kitchenBrightness, (v) => setState(() => _kitchenBrightness = v)),
      ],
    );
  }

  Widget _lightSlider(String room, IconData icon, double value, ValueChanged<double> onChanged) {
    final isOn = value > 0;
    final color = isOn ? SmithMkColors.accentPrimary : SmithMkColors.textTertiary;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      glowColor: isOn ? SmithMkColors.accentPrimary : null,
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(room, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isOn ? SmithMkColors.textPrimary : SmithMkColors.textSecondary)),
                    Text('${(value * 100).round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    activeTrackColor: SmithMkColors.accentPrimary,
                    inactiveTrackColor: SmithMkColors.glassBorder,
                    thumbColor: SmithMkColors.accentPrimary,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayColor: SmithMkColors.accentPrimary.withValues(alpha: 0.1),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: value,
                    onChanged: (v) {
                      final oldStep = (value * 20).round();
                      final newStep = (v * 20).round();
                      if (oldStep != newStep) HapticFeedback.selectionClick();
                      onChanged(v);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── BLINDS ───
  Widget _buildBlindControl() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(PhosphorIcons.blinds(PhosphorIconsStyle.light), color: _blindPosition > 0 ? SmithMkColors.accentPurple : SmithMkColors.textTertiary, size: 22),
                  const SizedBox(width: 12),
                  Text('Living Room Blinds', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: SmithMkColors.textPrimary)),
                ],
              ),
              Text('${(_blindPosition * 100).round()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _blindPosition > 0 ? SmithMkColors.accentPurple : SmithMkColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 16),
          // Blind visual
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A24),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SmithMkColors.glassBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Stack(
                children: [
                  // Window / light
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF1a237e).withValues(alpha: 0.3),
                          const Color(0xFF0d47a1).withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                  ),
                  // Blind slats
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 120 * (1 - _blindPosition),
                    child: Container(
                      decoration: BoxDecoration(
                        color: SmithMkColors.cardSurface,
                      ),
                      child: Column(
                        children: List.generate(
                          max(1, (8 * (1 - _blindPosition)).round()),
                          (i) => Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: SmithMkColors.glassBorder, width: 0.5)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: SmithMkColors.accentPurple,
              inactiveTrackColor: SmithMkColors.glassBorder,
              thumbColor: SmithMkColors.accentPurple,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayColor: SmithMkColors.accentPurple.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: _blindPosition,
              onChanged: (v) {
                final oldStep = (_blindPosition * 10).round();
                final newStep = (v * 10).round();
                if (oldStep != newStep) HapticFeedback.selectionClick();
                setState(() => _blindPosition = v);
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _blindButton('Close', PhosphorIcons.arrowDown(PhosphorIconsStyle.light), () {
                HapticFeedback.mediumImpact();
                setState(() => _blindPosition = 0);
              }),
              _blindButton('Stop', PhosphorIcons.stop(PhosphorIconsStyle.fill), () {
                HapticFeedback.lightImpact();
              }),
              _blindButton('Open', PhosphorIcons.arrowUp(PhosphorIconsStyle.light), () {
                HapticFeedback.mediumImpact();
                setState(() => _blindPosition = 1.0);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _blindButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: SmithMkColors.glassOverlay,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SmithMkColors.glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: SmithMkColors.textSecondary, size: 16),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: SmithMkColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ─── SECURITY ───
  Widget _buildSecurityPanel() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      glowColor: _securityArmed ? SmithMkColors.success : null,
      child: Column(
        children: [
          // Shield
          GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact();
              setState(() => _securityArmed = !_securityArmed);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: (_securityArmed ? SmithMkColors.success : SmithMkColors.error).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: (_securityArmed ? SmithMkColors.success : SmithMkColors.error).withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Icon(
                _securityArmed
                    ? PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill)
                    : PhosphorIcons.shieldSlash(PhosphorIconsStyle.light),
                color: _securityArmed ? SmithMkColors.success : SmithMkColors.error,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _securityArmed ? 'System Armed' : 'System Disarmed',
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600,
              color: _securityArmed ? SmithMkColors.success : SmithMkColors.error,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _lockTile('Front Door', _frontDoorLocked, () {
                HapticFeedback.mediumImpact();
                setState(() => _frontDoorLocked = !_frontDoorLocked);
              })),
              const SizedBox(width: 12),
              Expanded(child: _lockTile('Garage', _garageLocked, () {
                HapticFeedback.mediumImpact();
                setState(() => _garageLocked = !_garageLocked);
              })),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lockTile(String label, bool locked, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: (locked ? SmithMkColors.success : SmithMkColors.warning).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: (locked ? SmithMkColors.success : SmithMkColors.warning).withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(
              locked ? PhosphorIcons.lockSimple(PhosphorIconsStyle.fill) : PhosphorIcons.lockSimpleOpen(PhosphorIconsStyle.light),
              color: locked ? SmithMkColors.success : SmithMkColors.warning,
              size: 20,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: SmithMkColors.textPrimary)),
                Text(locked ? 'Locked' : 'Unlocked', style: TextStyle(fontSize: 10, color: locked ? SmithMkColors.success : SmithMkColors.warning)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── ENERGY ───
  Widget _buildEnergyPanel() {
    final exporting = _solarKw > _homeKw;
    final netKw = (_solarKw - _homeKw).abs();

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _energyNode(PhosphorIcons.sunDim(PhosphorIconsStyle.light), 'Solar', '${_solarKw}kW', SmithMkColors.accentPrimary),
              Column(
                children: [
                  Icon(
                    exporting ? PhosphorIcons.arrowRight(PhosphorIconsStyle.bold) : PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                    color: SmithMkColors.textTertiary,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exporting ? 'Exporting' : 'Importing',
                    style: const TextStyle(fontSize: 9, color: SmithMkColors.textTertiary),
                  ),
                  Text(
                    '${netKw.toStringAsFixed(1)}kW',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: exporting ? SmithMkColors.success : SmithMkColors.warning),
                  ),
                ],
              ),
              _energyNode(PhosphorIcons.house(PhosphorIconsStyle.light), 'Home', '${_homeKw}kW', const Color(0xFF42A5F5)),
            ],
          ),
          const SizedBox(height: 20),
          // Solar slider for demo
          Row(
            children: [
              const Text('Solar', style: TextStyle(fontSize: 11, color: SmithMkColors.textTertiary)),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    activeTrackColor: SmithMkColors.accentPrimary,
                    inactiveTrackColor: SmithMkColors.glassBorder,
                    thumbColor: SmithMkColors.accentPrimary,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: _solarKw,
                    min: 0, max: 8,
                    onChanged: (v) => setState(() => _solarKw = double.parse(v.toStringAsFixed(1))),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text('Home', style: TextStyle(fontSize: 11, color: SmithMkColors.textTertiary)),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    activeTrackColor: const Color(0xFF42A5F5),
                    inactiveTrackColor: SmithMkColors.glassBorder,
                    thumbColor: const Color(0xFF42A5F5),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: _homeKw,
                    min: 0, max: 8,
                    onChanged: (v) => setState(() => _homeKw = double.parse(v.toStringAsFixed(1))),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _energyNode(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: SmithMkColors.textTertiary)),
      ],
    );
  }
}

// ─── THERMOSTAT PAINTER ───
class _ThermostatPainter extends CustomPainter {
  final double currentTemp;
  final double targetTemp;
  final bool isHeating;

  _ThermostatPainter({
    required this.currentTemp,
    required this.targetTemp,
    required this.isHeating,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;

    // Background arc
    final bgPaint = Paint()
      ..color = SmithMkColors.glassBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      (135 * pi / 180),
      (270 * pi / 180),
      false,
      bgPaint,
    );

    // Active arc
    final tempRange = 30.0 - 16.0;
    final tempFraction = (targetTemp - 16.0) / tempRange;
    final sweepAngle = tempFraction * (270 * pi / 180);

    final activeColor = isHeating ? SmithMkColors.heatingActive : SmithMkColors.textTertiary;

    final activePaint = Paint()
      ..shader = SweepGradient(
        startAngle: 135 * pi / 180,
        endAngle: 405 * pi / 180,
        colors: [
          SmithMkColors.coolingActive,
          SmithMkColors.accentPrimary,
          SmithMkColors.heatingActive,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      (135 * pi / 180),
      sweepAngle,
      false,
      activePaint,
    );

    // Thumb dot
    final thumbAngle = (135 * pi / 180) + sweepAngle;
    final thumbPos = Offset(
      center.dx + radius * cos(thumbAngle),
      center.dy + radius * sin(thumbAngle),
    );

    canvas.drawCircle(thumbPos, 8, Paint()..color = activeColor);
    canvas.drawCircle(thumbPos, 5, Paint()..color = SmithMkColors.textPrimary);
  }

  @override
  bool shouldRepaint(covariant _ThermostatPainter oldDelegate) {
    return oldDelegate.currentTemp != currentTemp ||
        oldDelegate.targetTemp != targetTemp ||
        oldDelegate.isHeating != isHeating;
  }
}
