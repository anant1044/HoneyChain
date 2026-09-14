import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';
import '../main.dart';
import '../services/api_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 850;
          return Row(
            children: [
              Expanded(
                flex: isWide ? 55 : 100,
                child: const _LeftPanel(),
              ),
              if (isWide)
                Container(width: 1, color: AppColors.border),
              if (isWide)
                const Expanded(
                  flex: 45,
                  child: _RightPanel(),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LeftPanel extends StatefulWidget {
  const _LeftPanel();

  @override
  State<_LeftPanel> createState() => _LeftPanelState();
}

class _LeftPanelState extends State<_LeftPanel> {
  // Mode: 0 = Sign In, 1 = Register
  int _tabIndex = 0;

  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _regionController = TextEditingController(text: 'Punjab');
  final _walletController = TextEditingController(text: '0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB');

  String _registerRole = 'beekeeper';
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _regionController.dispose();
    _walletController.dispose();
    super.dispose();
  }

  void _fillDemoBeekeeper() {
    setState(() {
      _tabIndex = 0;
      _nameController.text = 'Ramesh Kumar';
      _passwordController.text = 'honeychain2026';
      _errorMessage = null;
    });
  }

  void _fillDemoLab() {
    setState(() {
      _tabIndex = 0;
      _nameController.text = 'NABL Central Lab';
      _passwordController.text = 'honeychain2026';
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your account name');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      CurrentUser user;
      if (_tabIndex == 0) {
        user = await ApiService().signIn(name: name, password: password);
      } else {
        user = await ApiService().registerUser(
          name: name,
          password: password,
          role: _registerRole,
          region: _regionController.text.trim(),
          walletAddress: _walletController.text.trim(),
        );
      }

      if (!mounted) return;

      UserRole roleEnum;
      final roleStr = user.role.toLowerCase();
      if (roleStr.contains('lab')) {
        roleEnum = UserRole.lab;
      } else if (roleStr.contains('beekeeper') || roleStr.contains('processor')) {
        roleEnum = UserRole.beekeeper;
      } else {
        roleEnum = UserRole.consumer;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HoneyChainShell(
            role: roleEnum,
            user: user,
          ),
        ),
      );
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network or connection error. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _enterAsConsumer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const HoneyChainShell(role: UserRole.consumer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              minWidth: constraints.maxWidth,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              // Logo
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.inset,
                      borderRadius: AppConstants.smallRadius,
                      border: Border.all(color: AppColors.borderHi),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'HC',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('HoneyChain', style: AppTextStyles.brand),
                ],
              ),
              const SizedBox(height: 36),

              Text(
                'Decentralized\nhoney provenance.',
                style: AppTextStyles.heroTitle.copyWith(fontSize: 34),
              ),
              const SizedBox(height: 8),
              Text(
                'Every batch. Every hive. Every test. Sealed on Polygon.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),

              // Segmented Tab Toggle (Sign In / Register)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppConstants.smallRadius,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _tabButton('Sign In', isSelected: _tabIndex == 0, onTap: () {
                        setState(() {
                          _tabIndex = 0;
                          _errorMessage = null;
                        });
                      }),
                    ),
                    Expanded(
                      child: _tabButton('Register Account', isSelected: _tabIndex == 1, onTap: () {
                        setState(() {
                          _tabIndex = 1;
                          _errorMessage = null;
                        });
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Error Banner if present
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.1),
                    borderRadius: AppConstants.smallRadius,
                    border: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: AppColors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTextStyles.mono.copyWith(fontSize: 11, color: AppColors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Main Auth Form Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppConstants.cardRadius,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_tabIndex == 1) ...[
                      // Role Selector for Register
                      Text('ACCOUNT ROLE', style: AppTextStyles.label),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.inset,
                          borderRadius: AppConstants.smallRadius,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _registerRole,
                            dropdownColor: AppColors.card,
                            isExpanded: true,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                            items: const [
                              DropdownMenuItem(value: 'beekeeper', child: Text('Beekeeper')),
                              DropdownMenuItem(value: 'lab', child: Text('Lab Technician')),
                              DropdownMenuItem(value: 'processor', child: Text('Honey Processor')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _registerRole = v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Name Field
                    Text('ACCOUNT NAME', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: _tabIndex == 0 ? 'e.g. Ramesh Kumar' : 'e.g. Jane Doe',
                        hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.inset,
                        border: OutlineInputBorder(
                          borderRadius: AppConstants.smallRadius,
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppConstants.smallRadius,
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppConstants.smallRadius,
                          borderSide: const BorderSide(color: AppColors.borderHi),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Password Field
                    Text('PASSWORD', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.inset,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: AppConstants.smallRadius,
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppConstants.smallRadius,
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppConstants.smallRadius,
                          borderSide: const BorderSide(color: AppColors.borderHi),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),

                    if (_tabIndex == 1) ...[
                      const SizedBox(height: 14),
                      // Region Field
                      Text('REGION / STATE', style: AppTextStyles.label),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _regionController,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'e.g. Punjab, California, Kashmir',
                          hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.inset,
                          border: OutlineInputBorder(
                            borderRadius: AppConstants.smallRadius,
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppConstants.smallRadius,
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppConstants.smallRadius,
                            borderSide: const BorderSide(color: AppColors.borderHi),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Wallet Address Field
                      Text('POLYGON WALLET ADDRESS', style: AppTextStyles.label),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _walletController,
                        style: AppTextStyles.mono.copyWith(fontSize: 11, color: AppColors.blue),
                        decoration: InputDecoration(
                          hintText: '0x...',
                          hintStyle: AppTextStyles.mono.copyWith(fontSize: 11, color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.inset,
                          border: OutlineInputBorder(
                            borderRadius: AppConstants.smallRadius,
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppConstants.smallRadius,
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppConstants.smallRadius,
                            borderSide: const BorderSide(color: AppColors.borderHi),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.textPrimary,
                          foregroundColor: AppColors.canvas,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppConstants.smallRadius,
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.canvas,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _tabIndex == 0 ? 'Sign In to HoneyChain' : 'Create Identity & Sign In',
                                    style: AppTextStyles.cardHeading.copyWith(
                                      color: AppColors.canvas,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, size: 14, color: AppColors.canvas),
                                ],
                              ),
                      ),
                    ),

                    if (_tabIndex == 0) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 12),
                      Text('QUICK DEMO LOGINS', style: AppTextStyles.label.copyWith(fontSize: 9)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _demoChip('🐝 Ramesh Kumar (Beekeeper)', _fillDemoBeekeeper),
                          _demoChip('🔬 NABL Central Lab', _fillDemoLab),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Consumer Guest Access
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('OR PUBLIC AUDIT', style: AppTextStyles.label.copyWith(fontSize: 10)),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: _enterAsConsumer,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppConstants.cardRadius,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.qr_code_scanner, size: 20, color: AppColors.green),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Continue as Public Consumer', style: AppTextStyles.cardHeading),
                            const SizedBox(height: 2),
                            Text(
                              'Verify batches on Polygon Amoy without signing in.',
                              style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
      },
    );
  }

  Widget _tabButton(String title, {required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.inset : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? AppColors.borderHi : Colors.transparent,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: AppTextStyles.label.copyWith(
            color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _demoChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.inset,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.borderHi),
        ),
        child: Text(
          label,
          style: AppTextStyles.mono.copyWith(fontSize: 10, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _RightPanel extends StatelessWidget {
  const _RightPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NETWORK OVERVIEW', style: AppTextStyles.label),
                const SizedBox(height: 32),
                const _BigStat(value: '12,450', label: 'Batches Sealed on Polygon'),
                const SizedBox(height: 28),
                const _BigStat(value: '842', label: 'Active Registered Beekeepers'),
                const SizedBox(height: 28),
                const _BigStat(value: '99.8%', label: 'Average Purity Index (NABL)'),
                const SizedBox(height: 28),
                const _BigStat(value: '5.8M', label: 'Polygon Amoy Block Height'),
                const SizedBox(height: 36),
                const Divider(color: AppColors.border),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Polygon Amoy Testnet · Live',
                      style: AppTextStyles.mono.copyWith(fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Contract: 0x5BFA55A855Da3687d0f9CDA33ae3f64f7a3629aB',
                  style: AppTextStyles.mono.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTextStyles.stat),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
