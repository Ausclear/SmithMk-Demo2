import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/smithmk_theme.dart';
import '../widgets/status_bar.dart';

// ═══════════════════════════════════════════════════════════
// ROOMS PAGE — Approved demo built in Flutter
// ═══════════════════════════════════════════════════════════
// Empty canvas → Add Room (full page) → Carousel with dots
// Tap light → dimmer modal (EXACT dashboard copy)
// Tap blind → blind visual (ORIGINAL CustomPaint)
// Tap climate → temperature control
// Tap media → media controls
// Power → inline ON/OFF toggle
// NO NAV — AppShell handles navigation
// Mock devices — will pull from HA/API later
// ═══════════════════════════════════════════════════════════

class RoomsPage extends StatefulWidget {
  const RoomsPage({super.key});
  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> with TickerProviderStateMixin {
  final List<_Room> _rooms = [];
  late PageController _pageCtrl;
  int _currentRoom = 0;
  late AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _entryCtrl = AnimationController(duration: const Duration(milliseconds: 500), vsync: this)..forward();
  }

  @override
  void dispose() { _pageCtrl.dispose(); _entryCtrl.dispose(); super.dispose(); }

  // ─── MOCK HA DEVICES (replaced by real HA entities later) ───
  static final List<_HADevice> _allDevices = [
    _HADevice('light.master_bedroom', 'Master Bedroom', _DType.light),
    _HADevice('light.lounge_downlights', 'Lounge Downlights', _DType.light),
    _HADevice('light.kitchen_spots', 'Kitchen Spots', _DType.light),
    _HADevice('light.office_desk', 'Office Desk Lamp', _DType.light),
    _HADevice('light.hallway', 'Hallway', _DType.light),
    _HADevice('light.alfresco', 'Alfresco', _DType.light),
    _HADevice('light.garage', 'Garage', _DType.light),
    _HADevice('light.entrance_1', 'Entrance 1', _DType.light),
    _HADevice('light.entrance_2', 'Entrance 2', _DType.light),
    _HADevice('light.bathroom', 'Bathroom', _DType.light),
    _HADevice('light.laundry', 'Laundry', _DType.light),
    _HADevice('light.bedside_lamp', 'Bedside Lamp', _DType.light),
    _HADevice('cover.lounge_blinds', 'Lounge Blinds', _DType.blind),
    _HADevice('cover.bedroom_blinds', 'Bedroom Blinds', _DType.blind),
    _HADevice('cover.office_blinds', 'Office Blinds', _DType.blind),
    _HADevice('cover.kitchen_blinds', 'Kitchen Blinds', _DType.blind),
    _HADevice('climate.ducted_ac', 'Ducted Aircon', _DType.climate),
    _HADevice('climate.lounge_radiator', 'Lounge Radiator', _DType.climate),
    _HADevice('climate.bedroom_radiator', 'Bedroom Radiator', _DType.climate),
    _HADevice('switch.lounge_lamp', 'Lounge Lamp Plug', _DType.power),
    _HADevice('switch.office_monitor', 'Office Monitor', _DType.power),
    _HADevice('switch.bedroom_fan', 'Bedroom Fan', _DType.power),
    _HADevice('switch.christmas_lights', 'Christmas Lights', _DType.power),
    _HADevice('switch.garage_door', 'Garage Door', _DType.power),
    _HADevice('media_player.lounge_echo', 'Lounge Echo', _DType.media),
    _HADevice('media_player.bedroom_echo', 'Bedroom Echo', _DType.media),
    _HADevice('media_player.office_echo', 'Office Echo', _DType.media),
  ];

  void _openAddRoom({_Room? editRoom, int? editIdx}) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (ctx, a1, a2) => _AddRoomPage(
        allDevices: _allDevices,
        editRoom: editRoom,
        onSave: (room) {
          setState(() {
            if (editIdx != null) {
              _rooms[editIdx] = room;
            } else {
              _rooms.add(room);
              _currentRoom = _rooms.length - 1;
            }
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageCtrl.hasClients && editIdx == null) {
              _pageCtrl.animateToPage(_currentRoom,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubicEmphasized);
            }
          });
        },
      ),
      transitionsBuilder: (ctx, a1, a2, child) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: a1, curve: Curves.easeInOutCubicEmphasized)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  void _confirmDelete(int idx) {
    HapticFeedback.heavyImpact();
    showDialog(context: context, barrierColor: Colors.black54, builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment(-0.5, -0.5), end: Alignment(0.5, 0.5),
            colors: [Color(0xFA1E1E22), Color(0xFA141418)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Delete Room?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Remove "${_rooms[idx].name}" and all its devices?',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: SmithMkColors.textSecondary)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _modalBtn('Cancel', false, () => Navigator.pop(ctx))),
            const SizedBox(width: 12),
            Expanded(child: _modalBtn('Delete', true, () {
              Navigator.pop(ctx);
              setState(() {
                _rooms.removeAt(idx);
                if (_currentRoom >= _rooms.length) _currentRoom = max(0, _rooms.length - 1);
              });
            })),
          ]),
        ]),
      ),
    ));
  }

  Widget _modalBtn(String label, bool danger, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(height: 40,
      decoration: BoxDecoration(
        color: danger ? SmithMkColors.error.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: danger ? SmithMkColors.error.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.06)),
      ),
      child: Center(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
        color: danger ? SmithMkColors.error : SmithMkColors.textSecondary)))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmithMkColors.background,
      body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ROOMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SmithMkColors.textTertiary, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text(_rooms.isEmpty ? 'No Rooms' : _rooms[_currentRoom].name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: SmithMkColors.textPrimary)),
            ])),
            // + button only when rooms exist
            if (_rooms.isNotEmpty)
              GestureDetector(
                onTap: () { HapticFeedback.lightImpact(); _openAddRoom(); },
                child: Container(width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: SmithMkColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SmithMkColors.accent.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.add_rounded, size: 20, color: SmithMkColors.accent)),
              ),
          ]),
          const SizedBox(height: 10),
          const StatusBar(),
        ])),
        const SizedBox(height: 12),
        // Dot indicators
        if (_rooms.length > 1)
          Padding(padding: const EdgeInsets.only(bottom: 8), child: Center(child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_rooms.length, (i) {
              final active = i == _currentRoom;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubicEmphasized,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 20 : 6, height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: active ? SmithMkColors.accent : SmithMkColors.inactive,
                  boxShadow: active ? [BoxShadow(color: SmithMkColors.accent.withValues(alpha: 0.3), blurRadius: 6)] : null,
                ),
              );
            }),
          ))),
        // Content
        Expanded(child: _rooms.isEmpty
          ? _emptyState()
          : PageView.builder(
              controller: _pageCtrl,
              itemCount: _rooms.length,
              onPageChanged: (i) { HapticFeedback.selectionClick(); setState(() => _currentRoom = i); },
              physics: const BouncingScrollPhysics(),
              itemBuilder: (ctx, i) => _RoomView(
                room: _rooms[i],
                onChanged: () => setState(() {}),
                onEdit: () => _openAddRoom(editRoom: _rooms[i], editIdx: i),
                onDelete: () => _confirmDelete(i),
              ),
            ),
        ),
      ])),
    );
  }

  Widget _emptyState() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
      child: Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 100, height: 100,
            decoration: BoxDecoration(
              color: SmithMkColors.accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: SmithMkColors.accent.withValues(alpha: 0.1)),
            ),
            child: Icon(PhosphorIcons.door(PhosphorIconsStyle.light), size: 44,
              color: SmithMkColors.accent.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 24),
          const Text('No Rooms Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Create a room and assign your devices\nto organise your smart home.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: SmithMkColors.textSecondary, height: 1.5)),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () { HapticFeedback.mediumImpact(); _openAddRoom(); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [SmithMkColors.accent, SmithMkColors.accent.withValues(alpha: 0.85)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: SmithMkColors.accent.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, size: 18, color: SmithMkColors.background),
                SizedBox(width: 8),
                Text('Add Room', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: SmithMkColors.background)),
              ]),
            ),
          ),
        ],
      ))),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ROOM VIEW — single room in the carousel
// ═══════════════════════════════════════════════════════════
class _RoomView extends StatelessWidget {
  final _Room room;
  final VoidCallback onChanged, onEdit, onDelete;
  const _RoomView({required this.room, required this.onChanged, required this.onEdit, required this.onDelete});

  static const _typeOrder = [_DType.light, _DType.blind, _DType.climate, _DType.power, _DType.media];
  static const _typeLabels = {_DType.light: 'LIGHTS', _DType.blind: 'BLINDS', _DType.climate: 'CLIMATE', _DType.power: 'POWER', _DType.media: 'MEDIA'};

  @override
  Widget build(BuildContext context) {
    final grouped = <_DType, List<_RoomDevice>>{};
    for (final t in _typeOrder) grouped[t] = [];
    for (final d in room.devices) grouped[d.type]?.add(d);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        // Room header
        Row(children: [
          Text(room.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(room.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('${room.devices.length} device${room.devices.length == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 11, color: SmithMkColors.textTertiary)),
          ])),
          _miniBtn(PhosphorIcons.pencilSimple(PhosphorIconsStyle.light), onEdit),
          const SizedBox(width: 8),
          _miniBtn(PhosphorIcons.trash(PhosphorIconsStyle.light), onDelete, danger: true),
        ]),
        const SizedBox(height: 16),
        for (final type in _typeOrder) ...[
          if (grouped[type]!.isNotEmpty) ...[
            Text(_typeLabels[type]!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
              color: SmithMkColors.textTertiary, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            for (final d in grouped[type]!) _buildTile(context, d),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  Widget _buildTile(BuildContext context, _RoomDevice d) {
    switch (d.type) {
      case _DType.light: return _LightTile(dev: d, onChanged: onChanged);
      case _DType.blind: return _BlindTile(dev: d, onChanged: onChanged);
      case _DType.climate: return _ClimateTile(dev: d, onChanged: onChanged);
      case _DType.power: return _PowerTile(dev: d, onChanged: onChanged);
      case _DType.media: return _MediaTile(dev: d, onChanged: onChanged);
    }
  }

  Widget _miniBtn(IconData icon, VoidCallback onTap, {bool danger = false}) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(width: 32, height: 32,
        decoration: BoxDecoration(
          color: danger ? SmithMkColors.error.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: danger ? SmithMkColors.error.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.06)),
        ),
        child: Icon(icon, size: 15, color: danger ? SmithMkColors.error.withValues(alpha: 0.7) : SmithMkColors.textTertiary)),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DEVICE TILES
// ═══════════════════════════════════════════════════════════

// ─── Shared tile shell ───
Widget _tileShell({
  required Widget icon,
  required String name,
  required String value,
  required bool on,
  bool isCli = false,
  String? subtitle,
  Widget? trailing,
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: () { if (onTap != null) { HapticFeedback.selectionClick(); onTap(); } },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubicEmphasized,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SmithMkColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: on
          ? (isCli ? SmithMkColors.heatingMode : SmithMkColors.accent).withValues(alpha: 0.12)
          : SmithMkColors.glassBorder),
        boxShadow: on ? [BoxShadow(
          color: (isCli ? SmithMkColors.heatingMode : SmithMkColors.accent).withValues(alpha: 0.05),
          blurRadius: 12)] : null,
      ),
      child: Row(children: [
        icon,
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SmithMkColors.textPrimary)),
          if (subtitle != null) Text(subtitle, style: TextStyle(fontSize: 10,
            color: isCli ? SmithMkColors.textTertiary : SmithMkColors.accent)),
        ])),
        if (trailing != null) trailing!
        else ...[
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
            color: on ? (isCli ? SmithMkColors.heatingMode : SmithMkColors.accent) : SmithMkColors.inactive)),
          const SizedBox(width: 10),
          Icon(PhosphorIcons.caretRight(PhosphorIconsStyle.light), size: 14, color: SmithMkColors.textTertiary),
        ],
      ]),
    ),
  );
}

Widget _devIcon(bool on, IconData iconOff, IconData iconOn, {bool isCli = false}) {
  final col = on ? (isCli ? SmithMkColors.heatingMode : SmithMkColors.accent) : SmithMkColors.inactive;
  return AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    width: 38, height: 38,
    decoration: BoxDecoration(
      color: on ? (isCli ? SmithMkColors.heatingMode : SmithMkColors.accent).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(11),
      boxShadow: on ? [BoxShadow(color: (isCli ? SmithMkColors.heatingMode : SmithMkColors.accent).withValues(alpha: 0.08), blurRadius: 10)] : null,
    ),
    child: Icon(on ? iconOn : iconOff, color: col, size: 18),
  );
}

// ─── LIGHT TILE ───
class _LightTile extends StatelessWidget {
  final _RoomDevice dev;
  final VoidCallback onChanged;
  const _LightTile({required this.dev, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final on = dev.brightness > 0;
    return _tileShell(
      icon: _devIcon(on, PhosphorIcons.lightbulb(PhosphorIconsStyle.light), PhosphorIcons.lightbulb(PhosphorIconsStyle.fill)),
      name: dev.name, value: on ? '${(dev.brightness * 100).round()}%' : 'Off', on: on,
      onTap: () => _openDimmer(context),
    );
  }

  void _openDimmer(BuildContext context) {
    showDialog(context: context, barrierColor: Colors.black54, builder: (ctx) => _DimmerModal(
      name: dev.name, level: dev.brightness,
      onChanged: (v) { dev.brightness = v; onChanged(); },
      onToggle: () { dev.brightness = dev.brightness > 0 ? 0 : 0.75; onChanged(); },
    ));
  }
}

// ─── BLIND TILE ───
class _BlindTile extends StatelessWidget {
  final _RoomDevice dev;
  final VoidCallback onChanged;
  const _BlindTile({required this.dev, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final on = dev.blindPos > 0;
    return _tileShell(
      icon: _devIcon(on, PhosphorIcons.slidersHorizontal(PhosphorIconsStyle.light), PhosphorIcons.slidersHorizontal(PhosphorIconsStyle.fill)),
      name: dev.name, value: on ? '${(dev.blindPos * 100).round()}%' : 'Closed', on: on,
      onTap: () => showDialog(context: context, barrierColor: Colors.black54,
        builder: (ctx) => _BlindModal(name: dev.name, position: dev.blindPos,
          onChanged: (v) { dev.blindPos = v; onChanged(); })),
    );
  }
}

// ─── CLIMATE TILE ───
class _ClimateTile extends StatelessWidget {
  final _RoomDevice dev;
  final VoidCallback onChanged;
  const _ClimateTile({required this.dev, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _tileShell(
      icon: _devIcon(dev.climateOn, PhosphorIcons.thermometerSimple(PhosphorIconsStyle.light), PhosphorIcons.thermometerSimple(PhosphorIconsStyle.fill), isCli: true),
      name: dev.name, value: dev.climateOn ? '${dev.climateTarget.round()}°' : 'Off', on: dev.climateOn, isCli: true,
      subtitle: dev.climateOn ? '${dev.climateTarget.round()}°C target' : null,
      onTap: () => showDialog(context: context, barrierColor: Colors.black54,
        builder: (ctx) => _ClimateModal(name: dev.name, target: dev.climateTarget, isOn: dev.climateOn,
          onTargetChanged: (v) { dev.climateTarget = v; onChanged(); },
          onToggle: () { dev.climateOn = !dev.climateOn; onChanged(); })),
    );
  }
}

// ─── POWER TILE (inline toggle, no modal) ───
class _PowerTile extends StatelessWidget {
  final _RoomDevice dev;
  final VoidCallback onChanged;
  const _PowerTile({required this.dev, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _tileShell(
      icon: _devIcon(dev.powerOn, PhosphorIcons.plug(PhosphorIconsStyle.light), PhosphorIcons.plug(PhosphorIconsStyle.fill)),
      name: dev.name, value: dev.powerOn ? 'On' : 'Off', on: dev.powerOn,
      trailing: GestureDetector(
        onTap: () { HapticFeedback.lightImpact(); dev.powerOn = !dev.powerOn; onChanged(); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: dev.powerOn ? SmithMkColors.accent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(6),
            border: dev.powerOn ? Border.all(color: SmithMkColors.accent.withValues(alpha: 0.2)) : null,
          ),
          child: Text(dev.powerOn ? 'ON' : 'OFF',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
              color: dev.powerOn ? SmithMkColors.accent : SmithMkColors.textTertiary)),
        ),
      ),
    );
  }
}

// ─── MEDIA TILE ───
class _MediaTile extends StatelessWidget {
  final _RoomDevice dev;
  final VoidCallback onChanged;
  const _MediaTile({required this.dev, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _tileShell(
      icon: _devIcon(dev.mediaPlaying, PhosphorIcons.speakerHigh(PhosphorIconsStyle.light), PhosphorIcons.speakerHigh(PhosphorIconsStyle.fill)),
      name: dev.name, value: dev.mediaPlaying ? '${(dev.mediaVol * 100).round()}%' : 'Idle', on: dev.mediaPlaying,
      subtitle: dev.mediaPlaying ? 'Now playing' : null,
      onTap: () => showDialog(context: context, barrierColor: Colors.black54,
        builder: (ctx) => _MediaModal(name: dev.name, volume: dev.mediaVol, playing: dev.mediaPlaying,
          onVolumeChanged: (v) { dev.mediaVol = v; onChanged(); },
          onPlayPause: () { dev.mediaPlaying = !dev.mediaPlaying; onChanged(); })),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DIMMER MODAL — EXACT copy from dashboard_page.dart
// Same gradient, amber fill, thumb, grip line, haptic detents
// ═══════════════════════════════════════════════════════════
class _DimmerModal extends StatefulWidget {
  final String name;
  final double level;
  final ValueChanged<double> onChanged;
  final VoidCallback onToggle;
  const _DimmerModal({required this.name, required this.level, required this.onChanged, required this.onToggle});
  @override
  State<_DimmerModal> createState() => _DimmerModalState();
}

class _DimmerModalState extends State<_DimmerModal> {
  late double _lv;
  @override
  void initState() { super.initState(); _lv = widget.level; }

  void _setLevel(double v) {
    setState(() => _lv = v);
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final on = _lv > 0;
    final pct = (_lv * 100).round();
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment(-0.5, -0.5), end: Alignment(0.5, 0.5), colors: [Color(0xFA1E1E22), Color(0xFA141418)]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, offset: const Offset(0, 16))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Header
          Row(children: [
            Icon(PhosphorIcons.lightbulb(on ? PhosphorIconsStyle.fill : PhosphorIconsStyle.light),
              size: 22, color: on ? SmithMkColors.accent : SmithMkColors.textTertiary),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            GestureDetector(
              onTap: () { widget.onToggle(); setState(() => _lv = _lv > 0 ? 0 : 0.75); },
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: on ? SmithMkColors.accent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(6),
                  border: on ? Border.all(color: SmithMkColors.accent.withValues(alpha: 0.2)) : null),
                child: Text(on ? 'ON' : 'OFF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: on ? SmithMkColors.accent : SmithMkColors.textTertiary))),
            ),
            const SizedBox(width: 8),
            GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 28, height: 28,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
              child: const Center(child: Text('✕', style: TextStyle(fontSize: 13, color: SmithMkColors.textTertiary))))),
          ]),
          const SizedBox(height: 20),
          // Slider + info — exact match
          SizedBox(height: 200, child: Row(children: [
            GestureDetector(
              onVerticalDragStart: (d) => _drag(d.localPosition.dy, 200),
              onVerticalDragUpdate: (d) => _drag(d.localPosition.dy, 200),
              child: SizedBox(width: 50, height: 200, child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
                Container(width: 32, height: 200, decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)))),
                Positioned(bottom: 0, child: AnimatedContainer(duration: const Duration(milliseconds: 50), width: 32, height: (200 * _lv).clamp(0.0, 200.0),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [
                      SmithMkColors.accent.withValues(alpha: 0.15 + _lv * 0.15),
                      SmithMkColors.accent.withValues(alpha: 0.3 + _lv * 0.55)])))),
                Positioned(bottom: (_lv * 178).clamp(0.0, 178.0), child: Container(width: 42, height: 22,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(11),
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: on ? [const Color(0xFF4A3800), const Color(0xFF332600)] : [const Color(0xFF3A3A3A), const Color(0xFF222222)]),
                    border: Border.all(color: on ? SmithMkColors.accent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4, offset: const Offset(0, 2))]),
                  child: Center(child: Container(width: 14, height: 2, decoration: BoxDecoration(borderRadius: BorderRadius.circular(1), color: on ? SmithMkColors.accent.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.15)))))),
              ])),
            ),
            const SizedBox(width: 18),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('$pct%', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w600, color: on ? SmithMkColors.accent : SmithMkColors.textTertiary)),
              const Text('Brightness', style: TextStyle(fontSize: 10, color: SmithMkColors.textTertiary)),
              const Spacer(),
              Wrap(spacing: 6, runSpacing: 6, children: [25, 50, 75, 100].map((p) => GestureDetector(
                onTap: () { HapticFeedback.selectionClick(); _setLevel(p / 100); },
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: pct == p ? SmithMkColors.accent.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: pct == p ? SmithMkColors.accent.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.06))),
                  child: Text('$p%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pct == p ? SmithMkColors.accent : SmithMkColors.textTertiary))),
              )).toList()),
            ])),
          ])),
        ]),
      ),
    );
  }

  void _drag(double localY, double h) {
    final frac = (1 - localY / h).clamp(0.0, 1.0);
    final rounded = (frac * 100).round() / 100;
    if ((rounded * 4).round() != (_lv * 4).round()) {
      (rounded == 0 || rounded == 1) ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick();
    }
    _setLevel(rounded);
  }
}

// ═══════════════════════════════════════════════════════════
// BLIND MODAL — ORIGINAL CustomPaint design
// Animated fabric slats, headrail, pull cord, light glow
// ═══════════════════════════════════════════════════════════
class _BlindModal extends StatefulWidget {
  final String name;
  final double position;
  final ValueChanged<double> onChanged;
  const _BlindModal({required this.name, required this.position, required this.onChanged});
  @override
  State<_BlindModal> createState() => _BlindModalState();
}

class _BlindModalState extends State<_BlindModal> {
  late double _pos;
  @override
  void initState() { super.initState(); _pos = widget.position; }

  void _setPos(double v) { setState(() => _pos = v); widget.onChanged(v); }

  @override
  Widget build(BuildContext context) {
    final open = _pos > 0;
    final pct = (_pos * 100).round();
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 340, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment(-0.5, -0.5), end: Alignment(0.5, 0.5), colors: [Color(0xFA1E1E22), Color(0xFA141418)]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, offset: const Offset(0, 16))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Icon(PhosphorIcons.slidersHorizontal(open ? PhosphorIconsStyle.fill : PhosphorIconsStyle.light),
              size: 22, color: open ? SmithMkColors.accent : SmithMkColors.textTertiary),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 28, height: 28,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
              child: const Center(child: Text('✕', style: TextStyle(fontSize: 13, color: SmithMkColors.textTertiary))))),
          ]),
          const SizedBox(height: 20),
          // Blind visual — drag to adjust
          GestureDetector(
            onVerticalDragUpdate: (d) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              // Map drag within the 180px canvas area
              final localY = d.localPosition.dy - 90; // approx offset for header
              final frac = (localY / 180).clamp(0.0, 1.0);
              _setPos((frac * 100).round() / 100);
            },
            child: SizedBox(
              height: 180, width: double.infinity,
              child: CustomPaint(painter: _BlindPainter(position: _pos)),
            ),
          ),
          const SizedBox(height: 16),
          Text('$pct% open', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600,
            color: open ? SmithMkColors.accent : SmithMkColors.textTertiary)),
          const SizedBox(height: 16),
          Row(children: [
            for (final p in [('Closed', 0.0), ('25%', 0.25), ('50%', 0.5), ('75%', 0.75), ('Open', 1.0)]) ...[
              if (p.$2 > 0) const SizedBox(width: 6),
              Expanded(child: GestureDetector(
                onTap: () { HapticFeedback.selectionClick(); _setPos(p.$2); },
                child: Container(height: 36,
                  decoration: BoxDecoration(
                    color: (_pos - p.$2).abs() < 0.05 ? SmithMkColors.accent.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: (_pos - p.$2).abs() < 0.05 ? SmithMkColors.accent.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Center(child: Text(p.$1, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                    color: (_pos - p.$2).abs() < 0.05 ? SmithMkColors.accent : SmithMkColors.textTertiary))),
                ),
              )),
            ],
          ]),
        ]),
      ),
    );
  }
}

// ─── Blind CustomPainter — original slat design ───
class _BlindPainter extends CustomPainter {
  final double position;
  _BlindPainter({required this.position});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const pad = 8.0;
    final fw = w - pad * 2, fh = h - pad * 2;

    // Window glass
    final glassPaint = Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
        Color.lerp(const Color(0xFF0A0A0A), const Color(0xFF1A2030), position)!,
        Color.lerp(const Color(0xFF080808), const Color(0xFF141E2C), position)!,
      ]).createShader(Rect.fromLTWH(pad, pad, fw, fh));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(pad, pad, fw, fh), const Radius.circular(4)), glassPaint);

    // Light glow
    if (position > 0.1) {
      final glow = Paint()
        ..shader = RadialGradient(center: Alignment.topCenter, radius: 0.8, colors: [
          SmithMkColors.accent.withValues(alpha: 0.08 * position), Colors.transparent,
        ]).createShader(Rect.fromLTWH(pad, pad, fw, fh));
      canvas.drawRect(Rect.fromLTWH(pad, pad, fw, fh), glow);
    }

    // Slats
    const slatCount = 14;
    final slatAreaTop = pad + 8;
    final slatAreaH = fh - 12;
    final maxSlatH = slatAreaH / slatCount;

    for (int i = 0; i < slatCount; i++) {
      final compY = slatAreaTop + i * maxSlatH * (1 - position * 0.8);
      final sH = maxSlatH * (1 - position * 0.6);
      if (compY + sH > slatAreaTop + slatAreaH) continue;

      final t = i / slatCount;
      final slatPaint = Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
          Color.lerp(const Color(0xFF383838), const Color(0xFF444444), t)!,
          Color.lerp(const Color(0xFF282828), const Color(0xFF333333), t)!,
        ]).createShader(Rect.fromLTWH(pad + 4, compY, fw - 8, max(1, sH - 1.5)));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(pad + 4, compY, fw - 8, max(1, sH - 1.5)), const Radius.circular(1)), slatPaint);

      // Highlight
      canvas.drawLine(Offset(pad + 8, compY), Offset(pad + fw - 8, compY),
        Paint()..color = Colors.white.withValues(alpha: 0.06)..strokeWidth = 0.5);
    }

    // Headrail
    final hrPaint = Paint()
      ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF4A4A4A), Color(0xFF333333)])
        .createShader(Rect.fromLTWH(pad + 2, pad, fw - 4, 8));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(pad + 2, pad, fw - 4, 8), const Radius.circular(1)), hrPaint);

    // Frame
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(pad, pad, fw, fh), const Radius.circular(4)),
      Paint()..color = const Color(0xFF2A2A2A)..style = PaintingStyle.stroke..strokeWidth = 3);

    // Pull cord
    final cordX = w / 2 + 30;
    final cordEnd = pad + 22 + position * 18;
    canvas.drawLine(Offset(cordX, pad + 8), Offset(cordX, cordEnd),
      Paint()..color = const Color(0xFF555555)..strokeWidth = 1.5..strokeCap = StrokeCap.round);
    canvas.drawCircle(Offset(cordX, cordEnd + 4), 3.5, Paint()..color = const Color(0xFF666666));
  }

  @override
  bool shouldRepaint(_BlindPainter old) => old.position != position;
}

// ═══════════════════════════════════════════════════════════
// CLIMATE MODAL — ducted aircon only
// ═══════════════════════════════════════════════════════════
class _ClimateModal extends StatefulWidget {
  final String name;
  final double target;
  final bool isOn;
  final ValueChanged<double> onTargetChanged;
  final VoidCallback onToggle;
  const _ClimateModal({required this.name, required this.target, required this.isOn, required this.onTargetChanged, required this.onToggle});
  @override
  State<_ClimateModal> createState() => _ClimateModalState();
}

class _ClimateModalState extends State<_ClimateModal> {
  late double _t;
  late bool _on;
  @override
  void initState() { super.initState(); _t = widget.target; _on = widget.isOn; }

  void _adj(double d) {
    HapticFeedback.selectionClick();
    setState(() => _t = (_t + d).clamp(16.0, 32.0));
    widget.onTargetChanged(_t);
  }

  @override
  Widget build(BuildContext context) {
    final col = _on ? SmithMkColors.heatingMode : SmithMkColors.inactive;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 340, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment(-0.5, -0.5), end: Alignment(0.5, 0.5), colors: [Color(0xFA1E1E22), Color(0xFA141418)]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, offset: const Offset(0, 16))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Icon(PhosphorIcons.thermometerSimple(_on ? PhosphorIconsStyle.fill : PhosphorIconsStyle.light), size: 22, color: col),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            GestureDetector(
              onTap: () { HapticFeedback.mediumImpact(); setState(() => _on = !_on); widget.onToggle(); },
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _on ? SmithMkColors.heatingMode.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(6),
                  border: _on ? Border.all(color: SmithMkColors.heatingMode.withValues(alpha: 0.2)) : null),
                child: Text(_on ? 'ON' : 'OFF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: _on ? SmithMkColors.heatingMode : SmithMkColors.textTertiary))),
            ),
            const SizedBox(width: 8),
            GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 28, height: 28,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
              child: const Center(child: Text('✕', style: TextStyle(fontSize: 13, color: SmithMkColors.textTertiary))))),
          ]),
          const SizedBox(height: 28),
          Text('${_t.round()}°C', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w600, color: _on ? col : SmithMkColors.textTertiary)),
          const SizedBox(height: 4),
          const Text('Target', style: TextStyle(fontSize: 11, color: SmithMkColors.textTertiary)),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _bevBtn('−', () => _adj(-0.5)),
            const SizedBox(width: 32),
            _bevBtn('+', () => _adj(0.5)),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            for (final temp in [18.0, 20.0, 22.0, 24.0]) ...[
              if (temp > 18) const SizedBox(width: 6),
              Expanded(child: GestureDetector(
                onTap: () { HapticFeedback.selectionClick(); setState(() => _t = temp); widget.onTargetChanged(temp); },
                child: Container(height: 36,
                  decoration: BoxDecoration(
                    color: _t == temp ? SmithMkColors.heatingMode.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _t == temp ? SmithMkColors.heatingMode.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Center(child: Text('${temp.round()}°', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: _t == temp ? SmithMkColors.heatingMode : SmithMkColors.textTertiary))),
                ),
              )),
            ],
          ]),
        ]),
      ),
    );
  }

  Widget _bevBtn(String label, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(width: 52, height: 52,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)]),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 6, offset: const Offset(0, 3)),
          BoxShadow(color: Colors.white.withValues(alpha: 0.04), blurRadius: 0, offset: const Offset(0, -1))]),
      child: Center(child: Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: SmithMkColors.textSecondary)))));
  }
}

// ═══════════════════════════════════════════════════════════
// MEDIA MODAL — play/pause + volume
// ═══════════════════════════════════════════════════════════
class _MediaModal extends StatefulWidget {
  final String name;
  final double volume;
  final bool playing;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onPlayPause;
  const _MediaModal({required this.name, required this.volume, required this.playing, required this.onVolumeChanged, required this.onPlayPause});
  @override
  State<_MediaModal> createState() => _MediaModalState();
}

class _MediaModalState extends State<_MediaModal> {
  late double _vol;
  late bool _pl;
  @override
  void initState() { super.initState(); _vol = widget.volume; _pl = widget.playing; }

  @override
  Widget build(BuildContext context) {
    final pct = (_vol * 100).round();
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 340, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment(-0.5, -0.5), end: Alignment(0.5, 0.5), colors: [Color(0xFA1E1E22), Color(0xFA141418)]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, offset: const Offset(0, 16))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Icon(PhosphorIcons.speakerHigh(_pl ? PhosphorIconsStyle.fill : PhosphorIconsStyle.light),
              size: 22, color: _pl ? SmithMkColors.accent : SmithMkColors.textTertiary),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 28, height: 28,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
              child: const Center(child: Text('✕', style: TextStyle(fontSize: 13, color: SmithMkColors.textTertiary))))),
          ]),
          const SizedBox(height: 24),
          // Play/Pause
          GestureDetector(
            onTap: () { HapticFeedback.mediumImpact(); setState(() => _pl = !_pl); widget.onPlayPause(); },
            child: Container(width: 64, height: 64,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: _pl ? [SmithMkColors.accent.withValues(alpha: 0.2), SmithMkColors.accent.withValues(alpha: 0.08)]
                    : [const Color(0xFF2A2A2A), const Color(0xFF1A1A1A)]),
                border: Border.all(color: _pl ? SmithMkColors.accent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.08)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4)),
                  if (_pl) BoxShadow(color: SmithMkColors.accent.withValues(alpha: 0.1), blurRadius: 16)]),
              child: Icon(_pl ? PhosphorIcons.pause(PhosphorIconsStyle.fill) : PhosphorIcons.play(PhosphorIconsStyle.fill),
                size: 26, color: _pl ? SmithMkColors.accent : SmithMkColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          Text('Volume $pct%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: _pl ? SmithMkColors.textPrimary : SmithMkColors.textTertiary)),
          const SizedBox(height: 12),
          // Horizontal volume slider
          LayoutBuilder(builder: (ctx, constraints) {
            final trackW = constraints.maxWidth;
            return GestureDetector(
              onHorizontalDragUpdate: (d) {
                final frac = (d.localPosition.dx / trackW).clamp(0.0, 1.0);
                setState(() => _vol = (frac * 100).round() / 100);
                widget.onVolumeChanged(_vol);
              },
              onTapDown: (d) {
                final frac = (d.localPosition.dx / trackW).clamp(0.0, 1.0);
                setState(() => _vol = (frac * 100).round() / 100);
                widget.onVolumeChanged(_vol);
              },
              child: SizedBox(height: 32, child: Stack(alignment: Alignment.centerLeft, children: [
                Container(height: 6, decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.04)))),
                FractionallySizedBox(widthFactor: _vol, child: Container(height: 6,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(3),
                    gradient: LinearGradient(colors: [SmithMkColors.accent.withValues(alpha: 0.3), SmithMkColors.accent.withValues(alpha: 0.6 + _vol * 0.3)])))),
                Positioned(left: _vol * (trackW - 18), child: Container(width: 18, height: 18,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4A3800), Color(0xFF332600)]),
                    border: Border.all(color: SmithMkColors.accent.withValues(alpha: 0.3)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4, offset: const Offset(0, 2))]))),
              ])),
            );
          }),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ADD ROOM — full page (NOT modal)
// ═══════════════════════════════════════════════════════════
class _AddRoomPage extends StatefulWidget {
  final List<_HADevice> allDevices;
  final _Room? editRoom;
  final void Function(_Room) onSave;
  const _AddRoomPage({required this.allDevices, this.editRoom, required this.onSave});
  @override
  State<_AddRoomPage> createState() => _AddRoomPageState();
}

class _AddRoomPageState extends State<_AddRoomPage> {
  late TextEditingController _nameCtrl;
  String _emoji = '🏠';
  final Set<String> _selected = {};
  static const _emojis = ['🏠','🛏️','🛋️','💻','🍳','🚿','🧺','🚗','🌳','🎮','🏋️','📚'];
  static const _typeOrder = [_DType.light, _DType.blind, _DType.climate, _DType.power, _DType.media];
  static const _typeLabels = {_DType.light:'LIGHTS', _DType.blind:'BLINDS', _DType.climate:'CLIMATE', _DType.power:'POWER', _DType.media:'MEDIA'};

  @override
  void initState() {
    super.initState();
    if (widget.editRoom != null) {
      _nameCtrl = TextEditingController(text: widget.editRoom!.name);
      _emoji = widget.editRoom!.emoji;
      _selected.addAll(widget.editRoom!.devices.map((d) => d.entityId));
    } else {
      _nameCtrl = TextEditingController();
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  bool get _canSave => _nameCtrl.text.trim().isNotEmpty && _selected.isNotEmpty;

  void _save() {
    if (!_canSave) return;
    HapticFeedback.mediumImpact();
    final devices = _selected.map((id) {
      final ha = widget.allDevices.firstWhere((d) => d.entityId == id);
      if (widget.editRoom != null) {
        final existing = widget.editRoom!.devices.where((d) => d.entityId == id).toList();
        if (existing.isNotEmpty) return existing.first;
      }
      return _RoomDevice.fromHA(ha);
    }).toList();
    widget.onSave(_Room(name: _nameCtrl.text.trim(), emoji: _emoji, devices: devices));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <_DType, List<_HADevice>>{};
    for (final d in widget.allDevices) grouped.putIfAbsent(d.type, () => []).add(d);
    final isEdit = widget.editRoom != null;

    return Scaffold(
      backgroundColor: SmithMkColors.background,
      body: SafeArea(child: Column(children: [
        // Header
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0), child: Row(children: [
          GestureDetector(
            onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
            child: Container(width: 36, height: 36,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: SmithMkColors.textSecondary)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isEdit ? 'EDIT ROOM' : 'ADD ROOM',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SmithMkColors.textTertiary, letterSpacing: 1.2)),
            const SizedBox(height: 2),
            Text(isEdit ? 'Update devices' : 'Select devices',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ])),
          GestureDetector(
            onTap: _canSave ? _save : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _canSave ? SmithMkColors.accent : SmithMkColors.inactive.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(isEdit ? 'Save' : 'Create',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: _canSave ? SmithMkColors.background : SmithMkColors.textTertiary)),
            ),
          ),
        ])),
        const SizedBox(height: 16),
        // Name + emoji
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: SmithMkColors.cardSurface, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SmithMkColors.glassBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(_emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(child: TextField(
                controller: _nameCtrl,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: SmithMkColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Room name',
                  hintStyle: TextStyle(color: SmithMkColors.textTertiary.withValues(alpha: 0.5)),
                  border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
              )),
            ]),
            const SizedBox(height: 12),
            SizedBox(height: 36, child: ListView(scrollDirection: Axis.horizontal, children: _emojis.map((e) {
              final sel = e == _emoji;
              return GestureDetector(
                onTap: () { HapticFeedback.selectionClick(); setState(() => _emoji = e); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36, height: 36, margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: sel ? SmithMkColors.accent.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: sel ? SmithMkColors.accent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.04))),
                  child: Center(child: Text(e, style: const TextStyle(fontSize: 18))),
                ),
              );
            }).toList())),
          ]),
        )),
        const SizedBox(height: 12),
        // Count
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
          Text('${_selected.length} device${_selected.length == 1 ? '' : 's'} selected',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: _selected.isNotEmpty ? SmithMkColors.accent : SmithMkColors.textTertiary)),
          const Spacer(),
          if (_selected.isNotEmpty)
            GestureDetector(
              onTap: () { HapticFeedback.lightImpact(); setState(() => _selected.clear()); },
              child: const Text('Clear all', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SmithMkColors.textTertiary))),
        ])),
        const SizedBox(height: 8),
        // Device list
        Expanded(child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          physics: const BouncingScrollPhysics(),
          children: [
            for (final type in _typeOrder)
              if (grouped.containsKey(type)) ...[
                const SizedBox(height: 12),
                Text(_typeLabels[type]!,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SmithMkColors.textTertiary, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                for (final d in grouped[type]!) _devCheckbox(d),
              ],
          ],
        )),
      ])),
    );
  }

  Widget _devCheckbox(_HADevice device) {
    final sel = _selected.contains(device.entityId);
    final iconMap = {_DType.light: PhosphorIcons.lightbulb(PhosphorIconsStyle.light), _DType.blind: PhosphorIcons.slidersHorizontal(PhosphorIconsStyle.light),
      _DType.climate: PhosphorIcons.thermometerSimple(PhosphorIconsStyle.light), _DType.power: PhosphorIcons.plug(PhosphorIconsStyle.light),
      _DType.media: PhosphorIcons.speakerHigh(PhosphorIconsStyle.light)};

    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() { sel ? _selected.remove(device.entityId) : _selected.add(device.entityId); }); },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: sel ? SmithMkColors.accent.withValues(alpha: 0.06) : SmithMkColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? SmithMkColors.accent.withValues(alpha: 0.2) : SmithMkColors.glassBorder)),
        child: Row(children: [
          Icon(iconMap[device.type], size: 18, color: sel ? SmithMkColors.accent : SmithMkColors.textTertiary),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(device.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: sel ? SmithMkColors.textPrimary : SmithMkColors.textSecondary)),
            Text(device.entityId, style: const TextStyle(fontSize: 9, color: SmithMkColors.textTertiary)),
          ])),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: sel ? SmithMkColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: sel ? SmithMkColors.accent : SmithMkColors.inactive, width: sel ? 0 : 1.5)),
            child: sel ? const Icon(Icons.check_rounded, size: 14, color: SmithMkColors.background) : null,
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════
enum _DType { light, blind, climate, power, media }

class _HADevice {
  final String entityId, name;
  final _DType type;
  const _HADevice(this.entityId, this.name, this.type);
}

class _Room {
  String name, emoji;
  List<_RoomDevice> devices;
  _Room({required this.name, required this.emoji, required this.devices});
}

class _RoomDevice {
  final String entityId, name;
  final _DType type;
  double brightness = 0;
  double blindPos = 0;
  double climateTarget = 22;
  bool climateOn = false;
  bool powerOn = false;
  double mediaVol = 0.3;
  bool mediaPlaying = false;

  _RoomDevice({required this.entityId, required this.name, required this.type,
    this.brightness = 0, this.blindPos = 0, this.climateTarget = 22, this.climateOn = false,
    this.powerOn = false, this.mediaVol = 0.3, this.mediaPlaying = false});

  factory _RoomDevice.fromHA(_HADevice ha) => _RoomDevice(entityId: ha.entityId, name: ha.name, type: ha.type);
}
