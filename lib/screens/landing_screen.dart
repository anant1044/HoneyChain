import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';
import '../models/models.dart';
import '../widgets/vercel_button.dart';
import '../widgets/india_map.dart';
import '../screens/verify_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key, this.onNavigate});
  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final isMobile = constraints.maxWidth < 600;
        return Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PageHeader(isMobile: isMobile),
                  SizedBox(height: isMobile ? 16 : 24),
                  _MetricRow(isMobile: isMobile),
                  SizedBox(height: isMobile ? 16 : 24),
                  const Divider(color: AppColors.border, height: 1),
                  SizedBox(height: isMobile ? 16 : 24),
                  Expanded(
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 60,
                                child: Column(
                                  children: [
                                    _ActivityTable(onNavigate: onNavigate),
                                    const SizedBox(height: 24),
                                    Expanded(child: _NetworkMetrics()),
                                  ],
                                ),
                              ),
                              Container(
                                  width: 1,
                                  color: AppColors.border,
                                  margin: const EdgeInsets.symmetric(horizontal: 24)),
                              Expanded(flex: 40, child: _MapPanel(onNavigate: onNavigate)),
                            ],
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                _ActivityTable(onNavigate: onNavigate, isMobile: isMobile),
                                const SizedBox(height: 24),
                                SizedBox(height: 260, child: _NetworkMetrics()),
                                const SizedBox(height: 24),
                                SizedBox(height: 380, child: _MapPanel(onNavigate: onNavigate)),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({this.isMobile = false});
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overview', style: AppTextStyles.pageTitle),
          const SizedBox(height: 2),
          Text('12,450 batches · Polygon Mainnet',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('Overview', style: AppTextStyles.pageTitle),
        const SizedBox(width: 12),
        Text('12,450 batches · Polygon Mainnet',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({this.isMobile = false});
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricData(label: 'VERIFIED BATCHES', value: '12,450'),
      _MetricData(label: 'AVG PURITY',        value: '99.8%'),
      _MetricData(label: 'BEEKEEPERS',        value: '842'),
      _MetricData(label: 'BLOCK HEIGHT',      value: '5.8M'),
    ];

    if (isMobile) {
      // 2×2 grid on mobile
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.0,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        children: metrics.asMap().entries.map((e) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(e.value.label,
                    style: AppTextStyles.label.copyWith(fontSize: 9)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(e.value.value,
                      style: AppTextStyles.stat.copyWith(fontSize: 28)),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    // Desktop: horizontal row
    return Row(
      children: metrics.asMap().entries.map((e) {
        final showBorder = e.key < metrics.length - 1;
        return Expanded(
          child: _Metric(
            label: e.value.label,
            value: e.value.value,
            showBorder: showBorder,
          ),
        );
      }).toList(),
    );
  }
}

class _MetricData {
  const _MetricData({required this.label, required this.value});
  final String label;
  final String value;
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.showBorder});
  final String label;
  final String value;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(right: 24),
      decoration: showBorder
          ? const BoxDecoration(border: Border(right: AppConstants.borderSide))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.stat),
        ],
      ),
    );
  }
}

class _ActivityTable extends StatelessWidget {
  const _ActivityTable({this.onNavigate, this.isMobile = false});
  final ValueChanged<int>? onNavigate;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Activity', style: AppTextStyles.sectionHeading),
            GestureDetector(
              onTap: () => onNavigate?.call(1),
              child: Text('View all →',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: AppConstants.cardRadius,
          ),
          // On mobile wrap table in horizontal scroll
          child: isMobile
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _TableHeader(isMobile: true),
                        ...MockData.featuredBatches.asMap().entries.map((e) =>
                            _TableRow(batch: e.value, isLast: e.key == MockData.featuredBatches.length - 1, isMobile: true)),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    const _TableHeader(),
                    ...MockData.featuredBatches.asMap().entries.map((e) =>
                        _TableRow(batch: e.value, isLast: e.key == MockData.featuredBatches.length - 1)),
                  ],
                ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({this.isMobile = false});
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: AppConstants.borderSide),
        ),
        child: Row(
          children: [
            SizedBox(width: 130, child: Text('BATCH ID', style: AppTextStyles.label)),
            SizedBox(width: 180, child: Text('SOURCE / ORIGIN', style: AppTextStyles.label)),
            SizedBox(width: 70, child: Text('PURITY', style: AppTextStyles.label, textAlign: TextAlign.right)),
            SizedBox(width: 110, child: Text('STATUS', style: AppTextStyles.label, textAlign: TextAlign.right)),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: AppConstants.borderSide),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('BATCH ID', style: AppTextStyles.label)),
          Expanded(flex: 3, child: Text('SOURCE / ORIGIN', style: AppTextStyles.label)),
          Expanded(flex: 1, child: Text('PURITY', style: AppTextStyles.label, textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text('STATUS', style: AppTextStyles.label, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.batch, required this.isLast, this.isMobile = false});
  final HoneyBatch batch;
  final bool isLast;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final statusWidget = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            color: batch.status == BatchStatus.verified
                ? AppColors.green
                : AppColors.textMuted,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          batch.status.name.toUpperCase(),
          style: AppTextStyles.label.copyWith(
            color: batch.status == BatchStatus.verified
                ? AppColors.green
                : AppColors.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: AppConstants.borderSide),
        ),
        child: Row(
          children: [
            SizedBox(width: 130, child: Text(batch.id, style: AppTextStyles.mono)),
            SizedBox(
              width: 180,
              child: Text('${batch.floralSource} · ${batch.origin}',
                  style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis),
            ),
            SizedBox(
              width: 70,
              child: Text('${batch.purityIndex}%',
                  style: AppTextStyles.mono, textAlign: TextAlign.right),
            ),
            SizedBox(
              width: 110,
              child: statusWidget,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: AppConstants.borderSide),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(batch.id, style: AppTextStyles.mono)),
          Expanded(
            flex: 3,
            child: Text('${batch.floralSource} · ${batch.origin}',
                style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 1,
            child: Text('${batch.purityIndex}%',
                style: AppTextStyles.mono, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 2,
            child: statusWidget,
          ),
        ],
      ),
    );
  }
}

class _MapPanel extends StatelessWidget {
  const _MapPanel({this.onNavigate});
  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Live Hive Map', style: AppTextStyles.sectionHeading),
            Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'SYNCED',
                  style: AppTextStyles.mono.copyWith(
                    color: AppColors.green,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppConstants.cardRadius,
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: IndiaHiveMap(
              pins: MockData.hivePins,
              onPinTap: (pin) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hive Location: ${pin.label}')),
                  );
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: 'Verify Batch',
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
                      body: const VerifyScreen(),
                    ),
                  ));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SecondaryButton(
                label: 'Traceability',
                icon: Icons.alt_route_outlined,
                onPressed: () => onNavigate?.call(2),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


class _NetworkMetrics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Network Health', style: AppTextStyles.sectionHeading),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.border),
              borderRadius: AppConstants.cardRadius,
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _stat('RPC STATUS', 'Connected (42ms)', color: AppColors.green),
                      _stat('GAS PRICE', '32 Gwei'),
                      _stat('PEERS', '1,024'),
                    ],
                  ),
                  const Divider(color: AppColors.borderHi, height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _stat('HONEY REGISTERED', '42,850 kg'),
                      _stat('LAST BLOCK', '#5829104'),
                      _stat('TPS', '14.2'),
                    ],
                  ),
                  const Divider(color: AppColors.borderHi, height: 14),
                  _stat('CONTRACT', '0x3F8B...9A1B', mono: true),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stat(String label, String value, {Color? color, bool mono = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 10)),
        const SizedBox(height: 4),
        Text(
          value,
          style: (mono ? AppTextStyles.mono : AppTextStyles.bodySmall)
              .copyWith(color: color ?? AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
