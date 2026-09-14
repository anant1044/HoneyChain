import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';
import 'auth_screen.dart';
import 'landing_screen.dart';
import 'traceability_screen.dart';
import 'lab_report_screen.dart';
import 'verify_screen.dart';
import 'beekeeper_screen.dart';
import 'lab_screen.dart';
import '../services/api_service.dart';

enum UserRole { consumer, beekeeper, lab }

class HoneyChainShell extends StatefulWidget {
  const HoneyChainShell({super.key, required this.role, this.user});
  final UserRole role;
  final CurrentUser? user;

  @override
  State<HoneyChainShell> createState() => _HoneyChainShellState();
}

class _HoneyChainShellState extends State<HoneyChainShell> {
  int _selectedIndex = 0;

  CurrentUser? get _currentUser => widget.user ?? ApiService().currentUser;

  String get _displayName {
    if (widget.user != null && _currentUser != null && _currentUser!.name.isNotEmpty) {
      return _currentUser!.name;
    }
    switch (widget.role) {
      case UserRole.beekeeper:
        return 'Ramesh Kumar';
      case UserRole.lab:
        return 'NABL Central Lab';
      case UserRole.consumer:
        return 'Public Consumer';
    }
  }

  String get _roleLabel {
    if (widget.user != null && _currentUser != null) {
      return _currentUser!.roleDisplay.toUpperCase();
    }
    switch (widget.role) {
      case UserRole.beekeeper:
        return 'BEEKEEPER';
      case UserRole.lab:
        return 'LAB TECH';
      case UserRole.consumer:
        return 'CONSUMER';
    }
  }

  IconData get _roleIcon {
    switch (widget.role) {
      case UserRole.beekeeper:
        return Icons.hive_outlined;
      case UserRole.lab:
        return Icons.biotech_outlined;
      case UserRole.consumer:
        return Icons.person_outline;
    }
  }

  String get _shortWallet {
    if (_currentUser?.walletAddress != null && _currentUser!.walletAddress!.isNotEmpty) {
      return _currentUser!.shortWallet;
    }
    if (widget.role == UserRole.beekeeper) return '0x4B...D2dB';
    if (widget.role == UserRole.lab) return '0x25...Ec30';
    return '';
  }

  late final List<Widget> _views;
  late final List<NavigationDestination> _destinations;
  late final List<String> _titles;

  @override
  void initState() {
    super.initState();
    _views = [
      LandingScreen(onNavigate: _onNavigate),
      const LabReportScreen(),
      const TraceabilityScreen(),
    ];

    _destinations = [
      const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Overview'),
      const NavigationDestination(
          icon: Icon(Icons.science_outlined),
          selectedIcon: Icon(Icons.science_rounded),
          label: 'Lab Report'),
      const NavigationDestination(
          icon: Icon(Icons.alt_route_outlined),
          selectedIcon: Icon(Icons.alt_route_rounded),
          label: 'Traceability'),
    ];

    _titles = ['Overview', 'Quality Lab Report', 'Traceability'];

    switch (widget.role) {
      case UserRole.consumer:
        _views.add(const VerifyScreen());
        _destinations.add(const NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Verify'));
        _titles.add('Verify Batch');
        break;
      case UserRole.beekeeper:
        _views.add(const BeekeeperScreen());
        _destinations.add(const NavigationDestination(
            icon: Icon(Icons.hive_outlined),
            selectedIcon: Icon(Icons.hive_rounded),
            label: 'Beekeeper'));
        _titles.add('Beekeeper Portal');
        break;
      case UserRole.lab:
        _views.add(const LabScreen());
        _destinations.add(const NavigationDestination(
            icon: Icon(Icons.biotech_outlined),
            selectedIcon: Icon(Icons.biotech_rounded),
            label: 'Lab Portal'));
        _titles.add('Lab Portal');
        break;
    }
  }

  void _onNavigate(int index) {
    if (index < 0 || index >= _views.length) return;
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  void _goBack() {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
    }
  }

  bool get _canGoBack => _selectedIndex != 0;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        toolbarHeight: 56,
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        leading: _canGoBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textMuted),
                tooltip: 'Go back',
                onPressed: _goBack,
              )
            : null,
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                'HC',
                style: AppTextStyles.mono.copyWith(
                  color: AppColors.canvas,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (!isMobile) ...[
              Text('HoneyChain', style: AppTextStyles.brand),
              const SizedBox(width: 8),
              Container(width: 1, height: 16, color: AppColors.border),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                _titles[_selectedIndex],
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Hide the Polygon Amoy pill on mobile to save space
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              margin: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.inset,
                borderRadius: AppConstants.pillRadius,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Polygon Amoy',
                    style: AppTextStyles.mono.copyWith(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
          ],
          // Profile badge — compact on mobile, full on desktop
          _ProfileSwitcher(
            currentRole: widget.role,
            onSwitch: (newRole) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => HoneyChainShell(role: newRole),
                ),
                (route) => false,
              );
            },
            displayName: _displayName,
            roleLabel: _roleLabel,
            roleIcon: _roleIcon,
            shortWallet: _shortWallet,
            compact: isMobile,
          ),
          const SizedBox(width: 4),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.textMuted),
            tooltip: 'Sign Out',
            onPressed: () {
              ApiService().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.border),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _views,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onNavigate,
        destinations: _destinations,
        backgroundColor: AppColors.canvas,
        indicatorColor: AppColors.inset,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}

// ─── Profile Switcher Dropdown ────────────────────────────────────────────────

class _ProfileSwitcher extends StatelessWidget {
  const _ProfileSwitcher({
    required this.currentRole,
    required this.onSwitch,
    required this.displayName,
    required this.roleLabel,
    required this.roleIcon,
    required this.shortWallet,
    this.compact = false,
  });

  final UserRole currentRole;
  final ValueChanged<UserRole> onSwitch;
  final String displayName;
  final String roleLabel;
  final IconData roleIcon;
  final String shortWallet;
  final bool compact;

  static const _profiles = [
    (role: UserRole.beekeeper, name: 'Ramesh Kumar',    label: 'BEEKEEPER', wallet: '0x4B...D2dB', icon: Icons.hive_outlined),
    (role: UserRole.lab,       name: 'NABL Central Lab', label: 'LAB TECH',  wallet: '0x25...Ec30', icon: Icons.biotech_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<UserRole>(
      tooltip: 'Switch demo profile',
      offset: const Offset(0, 40),
      color: AppColors.card,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.borderHi),
      ),
      itemBuilder: (_) => [
        const PopupMenuItem<UserRole>(
          enabled: false,
          height: 28,
          child: Text(
            'SWITCH PROFILE',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              fontFamily: 'JetBrainsMono',
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const PopupMenuDivider(height: 1),
        ..._profiles.map((p) {
          final isActive = p.role == currentRole;
          return PopupMenuItem<UserRole>(
            value: p.role,
            enabled: !isActive,
            height: 44,
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.inset,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isActive ? AppColors.textSecondary : AppColors.border,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    p.icon,
                    size: 11,
                    color: isActive ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: TextStyle(
                          color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      Text(
                        p.wallet,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9,
                          fontFamily: 'JetBrainsMono',
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  const Icon(Icons.check_rounded, size: 14, color: AppColors.textPrimary),
              ],
            ),
          );
        }),
      ],
      onSelected: onSwitch,
      child: Container(
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppConstants.smallRadius,
          border: Border.all(color: AppColors.borderHi),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.inset,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.borderHi),
              ),
              alignment: Alignment.center,
              child: Icon(roleIcon, size: 13, color: AppColors.textPrimary),
            ),
            if (!compact) ...[
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    roleLabel,
                    style: AppTextStyles.mono.copyWith(
                      fontSize: 8,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (shortWallet.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.inset,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    shortWallet,
                    style: AppTextStyles.mono.copyWith(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(width: 4),
            const Icon(Icons.unfold_more_rounded, size: 12, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
