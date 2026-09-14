import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';
import '../models/models.dart';
import '../widgets/vercel_card.dart';
import '../widgets/vercel_button.dart';
import '../widgets/commit_terminal.dart';
import '../screens/verify_screen.dart';
import '../services/api_service.dart';
import '../utils/url_utils.dart';

class BeekeeperScreen extends StatefulWidget {
  const BeekeeperScreen({super.key});
  @override
  State<BeekeeperScreen> createState() => _BeekeeperScreenState();
}

class _BeekeeperScreenState extends State<BeekeeperScreen> {
  final _quantityController = TextEditingController(text: '5.0');
  String _selectedHive = 'Hive #03';
  String _selectedSource = 'Multifloral';
  bool _committed = false;
  bool _showingTerminal = false;

  // Live API results
  String _liveBatchCode = 'HC-2026-0847';
  String _liveTxHash = '';
  String _liveCid = '';
  String _liveQrUrl = '';
  String _liveApiError = '';

  static const _sources = ['Mustard', 'Acacia', 'Multifloral', 'Eucalyptus'];

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _commitBatch() {
    FocusScope.of(context).unfocus();
    setState(() {
      _showingTerminal = true;
      _liveApiError = '';
    });
    _callCreateBatch();
  }

  Future<void> _callCreateBatch() async {
    try {
      final quantityKg = double.tryParse(_quantityController.text.trim()) ?? 5.0;

      final result = await ApiService().createBatchOnChain(
        hiveName: _selectedHive,
        quantityKg: quantityKg,
        floralSource: _selectedSource,
      );

      if (mounted) {
        setState(() {
          _liveBatchCode = result.batchCode;
          _liveTxHash = result.createTxHash;
          _liveCid = result.metadataCid;
          _liveQrUrl = result.qrUrl ?? '';
        });
      }
    } on ApiError catch (e) {
      if (mounted) setState(() => _liveApiError = 'Polygon error: ${e.message}');
    } catch (_) {
      if (mounted) setState(() => _liveApiError = 'Network error — testnet batch registered locally.');
    }
  }

  void _onTerminalComplete() {
    setState(() {
      _showingTerminal = false;
      _committed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          _buildContent(),
          if (_showingTerminal)
            Positioned.fill(
              child: CommitTerminal(onComplete: _onTerminalComplete),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        return SingleChildScrollView(
          padding: AppConstants.pagePadding,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmall = constraints.maxWidth < 600;
                      if (isSmall) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Beekeeper Portal', style: AppTextStyles.pageTitle),
                            const SizedBox(height: 4),
                            Text(
                              '${ApiService().currentUser?.name ?? "Ramesh Kumar"} · ${ApiService().currentUser?.region ?? "Punjab"} (KVIC-HM)',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('Beekeeper Portal', style: AppTextStyles.pageTitle),
                          const SizedBox(width: 12),
                          Text(
                            '${ApiService().currentUser?.name ?? "Ramesh Kumar"} · ${ApiService().currentUser?.region ?? "Punjab"} (KVIC-HM)',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppConstants.sectionSpacing),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _TelemetrySection()),
                        const SizedBox(width: 24),
                        Expanded(child: _IdentityCard(profile: MockData.beekeeper)),
                      ],
                    )
                  else
                    Column(children: [
                      _IdentityCard(profile: MockData.beekeeper),
                      const SizedBox(height: AppConstants.sectionSpacing),
                      _TelemetrySection(),
                    ]),
                  const SizedBox(height: AppConstants.sectionSpacing),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: AppConstants.sectionSpacing),
                  Text('Create New Batch', style: AppTextStyles.sectionHeading),
                  const SizedBox(height: 16),
                  _BatchMintForm(
                    quantityController: _quantityController,
                    selectedHive: _selectedHive,
                    selectedSource: _selectedSource,
                    sources: _sources,
                    onHiveChanged: (v) => setState(() => _selectedHive = v),
                    onSourceChanged: (v) => setState(() => _selectedSource = v),
                    onCommit: _commitBatch,
                  ),
                  if (_liveApiError.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.08),
                        borderRadius: AppConstants.smallRadius,
                        border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline, size: 16, color: AppColors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_liveApiError,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.red))),
                      ]),
                    ),
                  ],
                  if (_committed) ...[
                    const SizedBox(height: 16),
                    _CommitReceipt(
                      hive: _selectedHive,
                      quantity: _quantityController.text,
                      source: _selectedSource,
                      batchCode: _liveBatchCode,
                      txHash: _liveTxHash,
                      cid: _liveCid,
                      qrUrl: _liveQrUrl,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TelemetrySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Hive Telemetry', style: AppTextStyles.sectionHeading),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.inset,
                borderRadius: AppConstants.pillRadius,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 5, height: 5,
                      decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text('LIVE', style: AppTextStyles.label.copyWith(color: AppColors.green, fontSize: 9)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
          childAspectRatio: 1.75,
          children: MockData.telemetry.map((r) => _TelemetryCell(reading: r)).toList(),
        ),
      ],
    );
  }
}

class _TelemetryCell extends StatelessWidget {
  const _TelemetryCell({required this.reading});
  final TelemetryReading reading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(reading.label, style: AppTextStyles.label.copyWith(fontSize: 10)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(reading.value, style: AppTextStyles.stat.copyWith(fontSize: 22)),
                const SizedBox(width: 3),
                Text(reading.unit, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Text(
            reading.note,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile});
  final BeekeeperProfile profile;

  @override
  Widget build(BuildContext context) {
    return VercelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Identity', style: AppTextStyles.sectionHeading),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          _infoRow('NAME', profile.name),
          const SizedBox(height: 10),
          _infoRow('BENEFICIARY ID', profile.beneficiaryId, mono: true),
          const SizedBox(height: 10),
          _infoRow('CLUSTER', profile.cluster),
          const SizedBox(height: 10),
          _infoRow('WALLET', profile.walletAddress, mono: true),
          const SizedBox(height: 10),
          _infoRow('ACTIVE HIVES', '${profile.activeHives}'),
          const SizedBox(height: 10),
          _infoRow('TOTAL BATCHES', '${profile.totalBatches}'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool mono = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.label),
        Text(value,
            style: mono
                ? AppTextStyles.mono
                : AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _BatchMintForm extends StatelessWidget {
  const _BatchMintForm({
    required this.quantityController,
    required this.selectedHive,
    required this.selectedSource,
    required this.sources,
    required this.onHiveChanged,
    required this.onSourceChanged,
    required this.onCommit,
  });

  final TextEditingController quantityController;
  final String selectedHive;
  final String selectedSource;
  final List<String> sources;
  final ValueChanged<String> onHiveChanged;
  final ValueChanged<String> onSourceChanged;
  final VoidCallback onCommit;

  @override
  Widget build(BuildContext context) {
    return VercelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: selectedHive,
            dropdownColor: AppColors.card,
            decoration: const InputDecoration(labelText: 'HIVE'),
            items: List.generate(
              8,
              (i) => DropdownMenuItem(
                value: 'Hive #${(i + 1).toString().padLeft(2, '0')}',
                child: Text(
                  'Hive #${(i + 1).toString().padLeft(2, '0')}',
                  style: AppTextStyles.mono.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ),
            onChanged: (v) => onHiveChanged(v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.mono.copyWith(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'HARVEST QUANTITY (kg)'),
          ),
          const SizedBox(height: 16),
          Text('FLORAL SOURCE', style: AppTextStyles.label),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: sources.map((s) => _SourceChip(
              label: s,
              selected: selectedSource == s,
              onPressed: () => onSourceChanged(s),
            )).toList(),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GPS', style: AppTextStyles.label),
              Text('27.1751° N, 78.0421° E', style: AppTextStyles.mono),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('UTC', style: AppTextStyles.label),
              Text('2026-09-07 08:14:32', style: AppTextStyles.mono),
            ],
          ),
          const SizedBox(height: 16),
          SecondaryButton(
            width: double.infinity,
            label: 'Fetch Live ESP32 Sensor Data',
            icon: Icons.sync_outlined,
            onPressed: () {},
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            width: double.infinity,
            label: 'Sign & Commit to Polygon',
            icon: Icons.lock_outline,
            onPressed: onCommit,
          ),

        ],
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.label, required this.selected, required this.onPressed});
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.inset,
          borderRadius: AppConstants.smallRadius,
          border: Border.all(
            color: selected ? AppColors.textPrimary : AppColors.borderHi,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.mono.copyWith(
            fontSize: 12,
            color: selected ? AppColors.canvas : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CommitReceipt extends StatelessWidget {
  const _CommitReceipt({
    required this.hive,
    required this.quantity,
    required this.source,
    required this.batchCode,
    required this.txHash,
    required this.cid,
    this.qrUrl,
  });
  final String hive;
  final String quantity;
  final String source;
  final String batchCode;
  final String txHash;
  final String cid;
  final String? qrUrl;

  String get _formattedTx => txHash.startsWith('0x') ? txHash : '0x$txHash';

  String get _shortTx {
    if (txHash.isEmpty) return 'pending...';
    if (txHash == 'mock-tx-hash') return 'mock-tx-hash (testnet mock mode)';
    final full = _formattedTx;
    if (full.length > 16) return '${full.substring(0, 8)}...${full.substring(full.length - 4)}';
    return full;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppConstants.cardRadius,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppConstants.cardRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3,
                color: AppColors.green,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Row(children: [
            Container(width: 6, height: 6,
                decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text('COMMITTED TO POLYGON', style: AppTextStyles.label.copyWith(color: AppColors.green)),
          ]),
          const SizedBox(height: 12),
          Text(batchCode, style: AppTextStyles.stat.copyWith(fontSize: 24)),
          const SizedBox(height: 12),
          _infoRow('PAYLOAD', '$hive · $quantity kg · $source'),
          const SizedBox(height: 6),
          _infoRow('NETWORK', 'Polygon Amoy Testnet', mono: true),
          const SizedBox(height: 6),
          _infoRow('TX HASH', _shortTx, mono: true),
          if (cid.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow('IPFS CID', cid.length > 20 ? '${cid.substring(0, 10)}...${cid.substring(cid.length - 6)}' : cid, mono: true),
          ],
          if (txHash.isNotEmpty && txHash != 'mock-tx-hash') ...[
            const SizedBox(height: 10),
            SelectableText(
              _formattedTx,
              style: AppTextStyles.mono.copyWith(color: AppColors.blue, fontSize: 10),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new, size: 14),
                label: const Text('View on Polygonscan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blue,
                  side: const BorderSide(color: AppColors.blue),
                  textStyle: AppTextStyles.label,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () => UrlUtils.openPolygonTx(txHash),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SecondaryButton(
            width: double.infinity,
            label: 'Verify this Batch',
            icon: Icons.qr_code_scanner_outlined,
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => Scaffold(
                  backgroundColor: AppColors.canvas,
                  appBar: AppBar(
                    backgroundColor: AppColors.canvas,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  body: VerifyScreen(initialCode: batchCode),
                ),
              ));
            },
          ),
        ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool mono = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.label),
        Text(value, style: mono ? AppTextStyles.mono : AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
