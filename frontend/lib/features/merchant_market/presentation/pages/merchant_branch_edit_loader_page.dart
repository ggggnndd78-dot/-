import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_organization_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/pages/merchant_branch_edit_page.dart';

final _merchantBranchEditProvider =
    FutureProvider.family<MerchantBranchModel, String>((ref, branchId) async {
  final repository = ref.read(merchantMarketRepositoryProvider);
  final organizationId = await repository.getMerchantOrganizationId();
  if ((organizationId ?? '').isEmpty) {
    throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
  }
  return repository.getBranch(
    organizationId: organizationId!,
    branchId: branchId,
  );
});

class MerchantBranchEditLoaderPage extends ConsumerWidget {
  const MerchantBranchEditLoaderPage({required this.branchId, super.key});

  final String branchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branch = ref.watch(_merchantBranchEditProvider(branchId));
    return branch.when(
      data: (item) => MerchantBranchEditPage(
        branch: MerchantBranchManagementItem.fromBranchModel(item),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('تعديل الفرع')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 42),
                const SizedBox(height: 12),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      ref.invalidate(_merchantBranchEditProvider(branchId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
