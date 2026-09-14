import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';
import '../models/models.dart';
import '../widgets/vercel_card.dart';
import '../widgets/vercel_button.dart';
import '../services/api_service.dart';
import '../utils/url_utils.dart';

class LabReportScreen extends StatefulWidget {
  const LabReportScreen({super.key});

  @override
  State<LabReportScreen> createState() => _LabReportScreenState();
}

class _LabReportScreenState extends State<LabReportScreen> {
  String _selectedBatchId = MockData.featuredBatches.first.id;

  // Live blockchain state
  BatchData? _blockchainData;
  bool _fetchingChain = false;
  String _chainError = '';

  @override
  void initState() {
    super.initState();
    _fetchBlockchainData();
  }

  Future<void> _fetchBlockchainData() async {
    setState(() {
      _fetchingChain = true;
      _chainError = '';
    });
    try {
      final result = await ApiService().getBatchByCode(_selectedBatchId);
      if (mounted) {
        setState(() {
          _blockchainData = result;
          _fetchingChain = false;
        });
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _chainError = 'Chain note: ${e.message}';
          _fetchingChain = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _chainError = '';
          _fetchingChain = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final batch = MockData.featuredBatches.firstWhere(
      (b) => b.id == _selectedBatchId,
      orElse: () => MockData.featuredBatches.first,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: AppConstants.pagePadding,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: AppConstants.sectionSpacing),
                  _buildBatchSelector(),
                  const SizedBox(height: AppConstants.sectionSpacing),
                  _buildBatchSummaryCard(batch),
                  const SizedBox(height: AppConstants.sectionSpacing),
                  _buildFiveMetricsSection(),
                  const SizedBox(height: AppConstants.sectionSpacing),
                  _buildCertificateBlockchainCard(batch),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(builder: (ctx, bc) {
      final isMobile = bc.maxWidth < 600;
      if (isMobile) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lab Report', style: AppTextStyles.pageTitle),
            const SizedBox(height: 2),
            Text(
              'NABL Accredited · Polygon Sealed',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('Quality Lab Report', style: AppTextStyles.pageTitle),
          const SizedBox(width: 12),
          Text(
            'NABL Accredited Chemical & Purity Analysis · Polygon Sealed',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      );
    });
  }

  Widget _buildBatchSelector() {
    final chips = MockData.featuredBatches.map((b) {
      final isSelected = b.id == _selectedBatchId;
      return ChoiceChip(
        label: Text(b.id, style: AppTextStyles.mono.copyWith(
          fontSize: 11,
          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
        )),
        selected: isSelected,
        selectedColor: AppColors.inset,
        backgroundColor: AppColors.card,
        side: BorderSide(color: isSelected ? AppColors.borderHi : AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: AppConstants.smallRadius),
        showCheckmark: false,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedBatchId = b.id);
            _fetchBlockchainData();
          }
        },
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SELECT BATCH:', style: AppTextStyles.label),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: chips
                .map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: c))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBatchSummaryCard(HoneyBatch batch) {
    return VercelCard(
      child: LayoutBuilder(builder: (ctx, bc) {
        final isMobile = bc.maxWidth < 500;
        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryItem('BATCH ID', batch.id, mono: true),
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _summaryItem('FLORAL SOURCE', batch.floralSource)),
                  Container(width: 1, height: 36, color: AppColors.border,
                      margin: const EdgeInsets.symmetric(horizontal: 12)),
                  Expanded(child: _summaryItem('ORIGIN', batch.origin)),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STATUS', style: AppTextStyles.label),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text('CERTIFIED PURE', style: AppTextStyles.label.copyWith(
                      color: AppColors.green, fontWeight: FontWeight.w600, fontSize: 10)),
                  ]),
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: _summaryItem('BATCH ID', batch.id, mono: true)),
            Container(width: 1, height: 36, color: AppColors.border),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _summaryItem('FLORAL SOURCE', batch.floralSource),
              ),
            ),
            Container(width: 1, height: 36, color: AppColors.border),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _summaryItem('ORIGIN', batch.origin),
              ),
            ),
            Container(width: 1, height: 36, color: AppColors.border),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('STATUS', style: AppTextStyles.label),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text('CERTIFIED PURE', style: AppTextStyles.label.copyWith(
                        color: AppColors.green, fontWeight: FontWeight.w600, fontSize: 10)),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _summaryItem(String label, String value, {bool mono = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 4),
        Text(
          value,
          style: (mono ? AppTextStyles.mono : AppTextStyles.bodySmall).copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFiveMetricsSection() {
    final metrics = [
      _MetricData(
        title: '1. NMR PURITY TEST',
        value: '100% AUTHENTIC',
        subtitle: 'Nuclear Magnetic Resonance',
        detail: '0% added corn, cane, or rice sugar syrup detected',
        standard: 'Codex Alimentarius & FSSAI Standard',
        status: 'PASSED',
        icon: Icons.biotech_outlined,
      ),
      _MetricData(
        title: '2. MOISTURE CONTENT',
        value: '17.1%',
        subtitle: 'Refractometric Index',
        detail: 'FSSAI upper limit: ≤ 20.0% moisture',
        standard: 'Optimal shelf stability · Zero fermentation risk',
        status: 'PASSED',
        icon: Icons.water_drop_outlined,
      ),
      _MetricData(
        title: '3. HMF LEVEL',
        value: '11.8 mg/kg',
        subtitle: 'Hydroxymethylfurfural',
        detail: 'FSSAI upper limit: ≤ 80.0 mg/kg',
        standard: 'Guarantees cold-extracted raw honey · Unheated',
        status: 'PASSED',
        icon: Icons.thermostat_outlined,
      ),
      _MetricData(
        title: '4. ANTIBIOTIC-FREE SCREENING',
        value: 'CLEAR',
        subtitle: 'Multi-Residue LC-MS/MS',
        detail: 'Zero residue of Chloramphenicol, Nitrofurans, Streptomycin',
        standard: 'Export Clean Standard · 100% Residue-Free',
        status: 'PASSED',
        icon: Icons.verified_user_outlined,
      ),
      _MetricData(
        title: '5. NABL LAB CERTIFICATE',
        value: 'NABL-CERT-9021',
        subtitle: 'Accreditation #MHL-2901',
        detail: 'Central Bee Research & Training Institute (KVIC)',
        standard: 'Digitally signed & hashed to Polygon blockchain',
        status: 'SEALED',
        icon: Icons.verified_outlined,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(builder: (ctx, bc) {
          final isMobile = bc.maxWidth < 500;
          final badge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.1),
              borderRadius: AppConstants.smallRadius,
              border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, size: 12, color: AppColors.green),
                const SizedBox(width: 4),
                Text('ALL 5 MET', style: AppTextStyles.mono.copyWith(
                  fontSize: 10, color: AppColors.green, fontWeight: FontWeight.w600,
                )),
              ],
            ),
          );
          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LAB METRICS (5 PARAMS)', style: AppTextStyles.sectionHeading),
                const SizedBox(height: 6),
                badge,
              ],
            );
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('OFFICIAL LAB METRICS (5 PARAMETERS)', style: AppTextStyles.sectionHeading),
              badge,
            ],
          );
        }),
        const SizedBox(height: 12),
        ...metrics.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _MetricCard(metric: m),
        )),
      ],
    );
  }

  Widget _buildCertificateBlockchainCard(HoneyBatch batch) {
    const ipfsCid = 'QmXoypizjW3WknFiJnKLwHCnL72vedxjQkDDP1mXWo6uco';
    const certHash = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

    return VercelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (ctx, bc) {
            final isMobile = bc.maxWidth < 500;
            final statusPillRow = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.inset,
                    borderRadius: AppConstants.pillRadius,
                    border: Border.all(color: AppColors.borderHi),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _fetchingChain ? AppColors.textMuted : AppColors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _fetchingChain
                            ? 'Querying...'
                            : (_blockchainData != null
                                ? _blockchainData!.statusLabel.toUpperCase()
                                : 'Polygon Amoy Testnet'),
                        style: AppTextStyles.mono.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _fetchingChain ? null : _fetchBlockchainData,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.inset,
                      borderRadius: AppConstants.smallRadius,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _fetchingChain
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.textMuted),
                          )
                        : const Icon(Icons.refresh, size: 14, color: AppColors.textMuted),
                  ),
                ),
              ],
            );

            final titleWidget = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.inset,
                    borderRadius: AppConstants.smallRadius,
                    border: Border.all(color: AppColors.borderHi),
                  ),
                  child: const Icon(Icons.token_outlined, size: 16, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 10),
                Text('ON-CHAIN LAB PROVENANCE', style: AppTextStyles.cardHeading),
              ],
            );

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleWidget,
                  const SizedBox(height: 8),
                  statusPillRow,
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                titleWidget,
                statusPillRow,
              ],
            );
          }),
          if (_chainError.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(_chainError, style: AppTextStyles.bodySmall.copyWith(color: AppColors.red, fontSize: 11)),
          ],
          if (_blockchainData != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.inset,
                borderRadius: AppConstants.smallRadius,
                border: Border.all(color: AppColors.borderHi),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text('On-Chain Status: ', style: AppTextStyles.label),
                  Text(_blockchainData!.status.toUpperCase(), style: AppTextStyles.mono.copyWith(
                    fontSize: 11, color: AppColors.green, fontWeight: FontWeight.w700,
                  )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          _detailRow('CERTIFICATE HASH (SHA-256)', certHash, mono: true),
          const SizedBox(height: 10),
          _detailRow(
            'IPFS CID',
            _blockchainData?.metadataCid.isNotEmpty == true
                ? _blockchainData!.metadataCid
                : ipfsCid,
            mono: true,
          ),
          const SizedBox(height: 10),
          _detailRow(
            'POLYGON TX HASH',
            _blockchainData?.createTxHash.isNotEmpty == true
                ? _blockchainData!.createTxHash
                : batch.transactionHash,
            mono: true,
            highlight: true,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              SecondaryButton(
                label: 'View Certificate on IPFS',
                icon: Icons.open_in_new,
                onPressed: () {
                  final cid = _blockchainData?.metadataCid.isNotEmpty == true
                      ? _blockchainData!.metadataCid
                      : ipfsCid;
                  UrlUtils.openIpfsCid(cid);
                },
              ),
              SecondaryButton(
                label: 'Verify on Polygonscan',
                icon: Icons.link,
                onPressed: () {
                  final tx = _blockchainData?.createTxHash.isNotEmpty == true
                      ? _blockchainData!.createTxHash
                      : batch.transactionHash;
                  UrlUtils.openPolygonTx(tx);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool mono = false, bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: (mono ? AppTextStyles.mono : AppTextStyles.bodySmall).copyWith(
            color: highlight ? AppColors.blue : AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.detail,
    required this.standard,
    required this.status,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final String detail;
  final String standard;
  final String status;
  final IconData icon;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});
  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppConstants.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(builder: (ctx, bc) {
        final isMobile = bc.maxWidth < 480;
        final statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            metric.status,
            style: AppTextStyles.mono.copyWith(
              color: AppColors.green, fontSize: 9,
              fontWeight: FontWeight.w700, letterSpacing: 0.5,
            ),
          ),
        );
        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.inset,
                    borderRadius: AppConstants.smallRadius,
                    border: Border.all(color: AppColors.borderHi),
                  ),
                  child: Icon(metric.icon, size: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(metric.title, style: AppTextStyles.label)),
                Text(metric.value, style: AppTextStyles.mono.copyWith(
                  fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                const SizedBox(width: 8),
                statusBadge,
              ]),
              const SizedBox(height: 6),
              Text(metric.detail, style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary, fontSize: 11)),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.inset,
                borderRadius: AppConstants.smallRadius,
                border: Border.all(color: AppColors.borderHi),
              ),
              child: Icon(metric.icon, size: 18, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(metric.title, style: AppTextStyles.label),
                  const SizedBox(height: 2),
                  Text(metric.subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(metric.detail, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(metric.standard, style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(metric.value, style: AppTextStyles.mono.copyWith(
                    fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  statusBadge,
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
