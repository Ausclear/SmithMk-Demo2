import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/smithmk_theme.dart';
import 'music_page.dart';

class MediaPage extends StatelessWidget {
  const MediaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0D),
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0), child: Row(children: [
          Icon(PhosphorIcons.monitorPlay(PhosphorIconsStyle.light), size: 22, color: SmithMkColors.gold),
          const SizedBox(width: 10),
          const Text('Media', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ])),
        const SizedBox(height: 12),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
          _pill('HA', true), const SizedBox(width: 6),
          _pill('SUPABASE', true), const SizedBox(width: 6),
          _pill('SPOTIFY', true),
        ])),
        Expanded(child: LayoutBuilder(builder: (ctx, c) {
          final isWide = c.maxWidth > 500;
          return Center(child: Padding(padding: const EdgeInsets.all(20), child: isWide
            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _mediaTile(context, 'MUSIC', PhosphorIcons.headphones(PhosphorIconsStyle.light), 'Spotify · Echo · Sonos', true),
                const SizedBox(width: 16),
                _orDivider(true),
                const SizedBox(width: 16),
                _mediaTile(context, 'TV', PhosphorIcons.monitor(PhosphorIconsStyle.light), 'Roku · NVIDIA Shield', false),
              ])
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                _mediaTile(context, 'MUSIC', PhosphorIcons.headphones(PhosphorIconsStyle.light), 'Spotify · Echo · Sonos', true),
                const SizedBox(height: 16),
                _orDivider(false),
                const SizedBox(height: 16),
                _mediaTile(context, 'TV', PhosphorIcons.monitor(PhosphorIconsStyle.light), 'Roku · NVIDIA Shield', false),
              ])));
        })),
      ])),
    );
  }

  Widget _mediaTile(BuildContext context, String label, IconData icon, String sub, bool isMusic) {
    return _MediaTileBtn(
      label: label, icon: icon, sub: sub,
      onTap: () {
        if (isMusic) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MusicPage()));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('TV page coming soon'), backgroundColor: Color(0xFF1E1E26)));
        }
      },
    );
  }

  Widget _orDivider(bool vertical) {
    if (vertical) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 1, height: 30, decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.white.withValues(alpha: 0.08), Colors.transparent]))),
        const Padding(padding: EdgeInsets.symmetric(vertical: 6),
          child: Text('OR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, color: Color(0x26FFFFFF)))),
        Container(width: 1, height: 30, decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.white.withValues(alpha: 0.08), Colors.transparent]))),
      ]);
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(height: 1, width: 30, decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withValues(alpha: 0.08), Colors.transparent]))),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text('OR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, color: Color(0x26FFFFFF)))),
      Container(height: 1, width: 30, decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withValues(alpha: 0.08), Colors.transparent]))),
    ]);
  }

  static Widget _pill(String label, bool ok) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: const Color(0x0AFFFFFF),
      border: Border.all(color: ok ? const Color(0x4D4CAF50) : const Color(0x4DEF4444))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle,
        color: ok ? SmithMkColors.success : SmithMkColors.error,
        boxShadow: [BoxShadow(color: ok ? SmithMkColors.success : SmithMkColors.error, blurRadius: 6)])),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1, color: Color(0x66FFFFFF))),
    ]));
}

/// Media tile with press animation — scales down, border glows amber, lifts back up
class _MediaTileBtn extends StatefulWidget {
  final String label, sub;
  final IconData icon;
  final VoidCallback onTap;
  const _MediaTileBtn({required this.label, required this.icon, required this.sub, required this.onTap});
  @override
  State<_MediaTileBtn> createState() => _MediaTileBtnState();
}

class _MediaTileBtnState extends State<_MediaTileBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); HapticFeedback.mediumImpact(); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (_, v, child) => Transform.translate(
          offset: Offset(0, 20 * (1 - v)),
          child: Opacity(opacity: v, child: child)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          width: 200, height: 220,
          transform: Matrix4.identity()
            ..scale(_pressed ? 0.93 : 1.0)
            ..translate(0.0, _pressed ? 4.0 : 0.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(begin: const Alignment(-0.5, -0.5), end: const Alignment(0.5, 0.5),
              colors: _pressed ? [const Color(0xFF2A2210), const Color(0xFF1E1A0E)] : [const Color(0xF21E1E26), const Color(0xEB16161C)]),
            border: Border.all(color: _pressed ? SmithMkColors.accent.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.07), width: _pressed ? 1.5 : 1),
            boxShadow: _pressed
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(2, 2)),
                 BoxShadow(color: SmithMkColors.accent.withValues(alpha: 0.1), blurRadius: 20)]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(8, 8)),
                 BoxShadow(color: Colors.white.withValues(alpha: 0.02), blurRadius: 12, offset: const Offset(-4, -4)),
                 BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 50, offset: const Offset(0, 20))],
          ),
          child: Stack(children: [
            Positioned(top: 0, left: 0, right: 0, height: 1, child: Container(
              decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withValues(alpha: _pressed ? 0.2 : 0.12), Colors.transparent])))),
            Positioned(top: 0, left: 0, right: 0, height: 90, child: Container(
              decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.white.withValues(alpha: 0.04), Colors.transparent])))),
            Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 80, height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF222222), Color(0xFF161616)]),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: _pressed ? 0.3 : 0.6), blurRadius: _pressed ? 8 : 16, offset: Offset(_pressed ? 2 : 6, _pressed ? 2 : 6)),
                    if (_pressed) BoxShadow(color: SmithMkColors.accent.withValues(alpha: 0.12), blurRadius: 20),
                  ]),
                child: Icon(widget.icon, size: 32, color: _pressed ? SmithMkColors.accent : SmithMkColors.gold)),
              const SizedBox(height: 14),
              Text(widget.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 2,
                color: _pressed ? SmithMkColors.accent : SmithMkColors.gold)),
              const SizedBox(height: 4),
              Text(widget.sub, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0x4DFFFFFF))),
            ])),
          ]),
        ),
      ),
    );
  }
}
