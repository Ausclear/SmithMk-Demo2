import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animated_emoji/animated_emoji.dart';
import '../theme/smithmk_theme.dart';
import '../pages/home_page.dart';
import '../pages/dashboard_page.dart';
import '../pages/lighting_page.dart';
import '../pages/placeholder_page.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // null = home launcher, 0-4 = inner pages
  int? _currentPage;

  final List<_InnerPage> _innerPages = [
    _InnerPage('Dashboard', '📊'),
    _InnerPage('Lights', '💡'),
    _InnerPage('Security', '🛡️'),
    _InnerPage('Climate', '🌡️'),
    _InnerPage('Blinds', '🪟'),
    _InnerPage('Energy', '⚡'),
    _InnerPage('Media', '🎵'),
    _InnerPage('Rooms', '🚪'),
    _InnerPage('Settings', '🔧'),
  ];

  List<Widget> get _pageWidgets => [
    const DashboardPage(),
    const LightingPage(),
    PlaceholderPage(title: 'Security', icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.light)),
    PlaceholderPage(title: 'Climate', icon: PhosphorIcons.thermometerSimple(PhosphorIconsStyle.light)),
    PlaceholderPage(title: 'Blinds', icon: PhosphorIcons.slidersHorizontal(PhosphorIconsStyle.light)),
    PlaceholderPage(title: 'Energy', icon: PhosphorIcons.lightning(PhosphorIconsStyle.light)),
    PlaceholderPage(title: 'Media', icon: PhosphorIcons.musicNotes(PhosphorIconsStyle.light)),
    PlaceholderPage(title: 'Rooms', icon: PhosphorIcons.door(PhosphorIconsStyle.light)),
    PlaceholderPage(title: 'Settings', icon: PhosphorIcons.gear(PhosphorIconsStyle.light)),
  ];

  void _goHome() {
    HapticFeedback.lightImpact();
    setState(() => _currentPage = null);
  }

  void _goToPage(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentPage = index);
  }

  // Called from HomePage when a tile is tapped
  void navigateToTile(String tileName) {
    final map = {
      'Dashboard': 0,
      'Lights': 1,
      'Security': 2,
      'Climate': 3,
      'Blinds': 4,
      'Energy': 5,
      'Media': 6,
      'Rooms': 7,
      'Settings': 8,
    };
    final idx = map[tileName];
    if (idx != null) {
      _goToPage(idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Home launcher — no nav
    if (_currentPage == null) {
      return HomePage(onTileTap: navigateToTile);
    }

    // Inner page — with nav
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final useSideNav = isWide || isLandscape;

        if (useSideNav) {
          return _buildSideNavLayout();
        } else {
          return _buildBottomNavLayout();
        }
      },
    );
  }

  Widget _buildEmojiIcon(String emoji, double size) {
    final animated = AnimatedEmojis.fromEmojiString(emoji);
    if (animated != null) {
      return AnimatedEmoji(animated, size: size, repeat: false);
    }
    return Text(emoji, style: TextStyle(fontSize: size * 0.8));
  }

  // ─── BOTTOM NAV ───
  Widget _buildBottomNavLayout() {
    return Scaffold(
      body: IndexedStack(index: _currentPage!, children: _pageWidgets),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: SmithMkColors.cardSurface,
          border: Border(top: BorderSide(color: SmithMkColors.glassBorder, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Home button
                _buildBottomNavItem(-1, '🏠', 'Home', _currentPage == null),
                // Inner pages
                ...List.generate(_innerPages.length, (i) =>
                  _buildBottomNavItem(i, _innerPages[i].emoji, _innerPages[i].label, _currentPage == i),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(int index, String emoji, String label, bool isActive) {
    return GestureDetector(
      onTap: () => index == -1 ? _goHome() : _goToPage(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEmojiIcon(emoji, isActive ? 22 : 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? SmithMkColors.accent : SmithMkColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SIDE NAV ───
  Widget _buildSideNavLayout() {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 72,
            decoration: BoxDecoration(
              color: SmithMkColors.cardSurface,
              border: Border(right: BorderSide(color: SmithMkColors.glassBorder, width: 0.5)),
            ),
            child: SafeArea(
              right: false,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Home button
                    _buildSideNavItem(-1, '🏠', 'Home', false),
                    const SizedBox(height: 4),
                    // Inner pages
                    ...List.generate(_innerPages.length, (i) =>
                      _buildSideNavItem(i, _innerPages[i].emoji, _innerPages[i].label, _currentPage == i),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(index: _currentPage!, children: _pageWidgets),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNavItem(int index, String emoji, String label, bool isActive) {
    return GestureDetector(
      onTap: () => index == -1 ? _goHome() : _goToPage(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 32,
              decoration: BoxDecoration(
                color: isActive ? SmithMkColors.accent.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: _buildEmojiIcon(emoji, isActive ? 20 : 17)),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? SmithMkColors.accent : SmithMkColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InnerPage {
  final String label;
  final String emoji;
  const _InnerPage(this.label, this.emoji);
}
