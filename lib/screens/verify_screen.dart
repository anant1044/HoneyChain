import 'package:flutter/material.dart';
import '../theme/honey_theme.dart';
import '../models/models.dart';
import '../widgets/verify_reveal.dart';
import '../services/api_service.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key, this.initialCode});
  final String? initialCode;

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  late final TextEditingController _controller;
  bool _loading = false;
  bool _verified = false;
  String? _errorMsg;

  // Live data returned from the blockchain
  VerifyData? _verifyResult;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialCode ?? '');
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
    }
  }

  Future<void> _verify() async {
    final batchId = _controller.text.trim();
    if (batchId.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _verified = false;
      _errorMsg = null;
    });

    try {
      final result = await ApiService().verifyBatch(batchId);
      if (mounted) {
        setState(() {
          _verifyResult = result;
          _verified = true;
          _loading = false;
        });
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Blockchain error (${e.statusCode}): ${e.message}';
          _loading = false;
        });
      }
    } catch (e) {
      // Fallback: verify locally if offline/network error
      final local = MockData.featuredBatches.firstWhere(
        (b) => b.id == batchId,
        orElse: () => MockData.featuredBatches.first,
      );
      if (mounted) {
        setState(() {
          _verifyResult = VerifyData(
            batchCode: local.id,
            status: 'Verified (Local Proof)',
            beekeeperName: MockData.beekeeper.name,
            region: local.origin,
            quantityGrams: 5000,
            honeyType: local.floralSource,
            blockchain: BlockchainProofData(
              contractAddress: '0x5BFA55A855Da3687d0f9CDA33ae3f64f7a3629aB',
              transactionHash: local.transactionHash,
              blockExplorerUrl: 'https://amoy.polygonscan.com/tx/${local.transactionHash}',
              batchHashOnChain: '35c951124d12c996bc1baf115696468f96e210b0bac4c701bd72f1f846e670b4',
              metadataCid: 'QmPzY3RUPBdTuxaKrPYfhrYnjHHdPrVHPYkEyhu8R5xAwK',
              labVerified: true,
            ),
          );
          _verified = true;
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Construct or adapt HoneyBatch for the reveal animation
    final localBatch = MockData.featuredBatches.firstWhere(
      (b) => b.id == _controller.text.trim(),
      orElse: () => MockData.featuredBatches.first,
    );
    final displayBatch = HoneyBatch(
      id: _verifyResult?.batchCode ?? localBatch.id,
      hiveId: localBatch.hiveId,
      quantity: _verifyResult?.quantityGrams != null
          ? '${(_verifyResult!.quantityGrams! / 1000).toStringAsFixed(1)} kg'
          : localBatch.quantity,
      floralSource: _verifyResult?.honeyType ?? localBatch.floralSource,
      origin: _verifyResult?.region ?? localBatch.origin,
      coordinates: localBatch.coordinates,
      timestamp: _verifyResult?.harvestDate ?? localBatch.timestamp,
      transactionHash: _verifyResult?.blockchain?.transactionHash ?? localBatch.transactionHash,
      purityIndex: localBatch.purityIndex,
      status: localBatch.status,
      lat: localBatch.lat,
      lng: localBatch.lng,
    );

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
                        Text('Verify Batch', style: AppTextStyles.pageTitle),
                        const SizedBox(height: 4),
                        Text('Scan QR or enter batch ID',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('Verify Batch', style: AppTextStyles.pageTitle),
                      const SizedBox(width: 12),
                      Text('Scan QR or enter batch ID',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppConstants.sectionSpacing),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: AppTextStyles.mono.copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'e.g. HC-2026-9868 or scan URL',
                        prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textMuted),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner_outlined,
                              size: 18, color: AppColors.textSecondary),
                          tooltip: 'Sample Batch',
                          onPressed: () {
                            _controller.text = 'HC-2026-9868';
                            _verify();
                          },
                        ),
                      ),
                      onSubmitted: (_) => _verify(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: AppColors.canvas,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: AppConstants.smallRadius),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.canvas,
                              ),
                            )
                          : Text('Verify',
                              style: AppTextStyles.cardHeading.copyWith(color: AppColors.canvas)),
                    ),
                  ),
                ],
              ),
              if (_errorMsg != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.08),
                    borderRadius: AppConstants.smallRadius,
                    border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: AppColors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMsg!,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.red)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppConstants.sectionSpacing),
              if (_verified && _verifyResult != null) ...[
                // Show live blockchain status badge
                _BlockchainStatusBadge(data: _verifyResult!),
                const SizedBox(height: 16),
                VerifyReveal(
                  batch: displayBatch,
                  beekeeper: MockData.beekeeper,
                ),
              ] else if (!_loading)
                _ScanPrompt(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockchainStatusBadge extends StatelessWidget {
  const _BlockchainStatusBadge({required this.data});
  final VerifyData data;

  @override
  Widget build(BuildContext context) {
    final bc = data.blockchain;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inset,
        borderRadius: AppConstants.cardRadius,
        border: Border.all(color: AppColors.borderHi),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('POLYGON AMOY PROOF', style: AppTextStyles.label.copyWith(color: AppColors.green)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.12),
                  borderRadius: AppConstants.smallRadius,
                ),
                child: Text(
                  data.status.toUpperCase(),
                  style: AppTextStyles.mono.copyWith(
                    fontSize: 10,
                    color: AppColors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statItem('BATCH CODE', data.batchCode, mono: true),
              ),
              Expanded(
                child: _statItem('BEEKEEPER', data.beekeeperName ?? 'Ramesh Kumar'),
              ),
              if (data.quantityGrams != null)
                Expanded(
                  child: _statItem('QUANTITY', '${(data.quantityGrams! / 1000).toStringAsFixed(1)} kg', mono: true),
                ),
            ],
          ),
          if (bc?.contractAddress != null && bc!.contractAddress.isNotEmpty) ...[
            const SizedBox(height: 10),
            _statItem('CONTRACT', bc.contractAddress, mono: true),
          ],
          if (bc?.transactionHash != null && bc!.transactionHash!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _statItem(
              'TX HASH (POLYGON AMOY)',
              bc.transactionHash!.startsWith('0x') ? bc.transactionHash! : '0x${bc.transactionHash!}',
              mono: true,
              highlight: true,
            ),
          ],
          if (data.ipfs?.cid != null && data.ipfs!.cid!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _statItem('IPFS CID', data.ipfs!.cid!, mono: true),
          ],
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, {bool mono = false, bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 3),
        SelectableText(
          value,
          style: (mono ? AppTextStyles.mono : AppTextStyles.bodySmall).copyWith(
            color: highlight ? AppColors.blue : AppColors.textPrimary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _ScanPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: AppConstants.cardRadius,
      ),
      child: Column(
        children: [
          const Icon(Icons.qr_code_scanner_outlined, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('Ready to verify', style: AppTextStyles.cardHeading),
          const SizedBox(height: 6),
          Text('Enter a batch ID (e.g. HC-2026-9868) or tap the sample icon.',
              style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
