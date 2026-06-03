import 'package:flutter/material.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_ready_for_delivery_model.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/cubit/sales_order_cubit.dart';

/// Bottom sheet: loads deliveries ready for return, search, returns selected [docEntry].
/// [customerCardCode]: when non-null, list is limited to that customer's deliveries.
Future<int?> showReadyForReturnPicker(
  BuildContext context,
  SalesOrderCubit cubit, {
  String? customerCardCode,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder:
        (ctx) => _ReadyForReturnPickerBody(
          cubit: cubit,
          customerCardCode: customerCardCode,
        ),
  );
}

class _ReadyForReturnPickerBody extends StatefulWidget {
  const _ReadyForReturnPickerBody({
    required this.cubit,
    this.customerCardCode,
  });

  final SalesOrderCubit cubit;
  final String? customerCardCode;

  @override
  State<_ReadyForReturnPickerBody> createState() =>
      _ReadyForReturnPickerBodyState();
}

class _ReadyForReturnPickerBodyState extends State<_ReadyForReturnPickerBody> {
  final _searchController = TextEditingController();
  List<SalesOrderReadyForDeliveryModel> _all = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.cubit.loadDeliveriesReadyForReturn(
        customerCardCode: widget.customerCardCode,
      );
      if (!mounted) return;
      setState(() {
        _all = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<SalesOrderReadyForDeliveryModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((e) {
      final numStr = e.docNum != null ? '${e.docNum}' : '';
      final code = (e.cardCode ?? '').toLowerCase();
      final name = (e.cardName ?? '').toLowerCase();
      return numStr.contains(q) ||
          code.contains(q) ||
          name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxH = MediaQuery.sizeOf(context).height * 0.85;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height: maxH,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.readyForReturnTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.readyForReturnSearchHint,
                  prefixIcon: const Icon(Icons.search, size: 22),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.error),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _load,
                              child: Text(l10n.readyForReturnRetry),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _filtered.isEmpty
                  ? Center(
                      child: Text(
                        l10n.readyForReturnEmpty,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final row = _filtered[index];
                        final de = row.docEntry;
                        final totalStr = row.docTotal != null
                            ? NumberFormat.decimalPattern().format(row.docTotal)
                            : '—';
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          enabled: de != null,
                          title: Text(
                            row.cardName?.trim().isNotEmpty == true
                                ? row.cardName!.trim()
                                : (row.cardCode ?? '—'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${l10n.docNumber} ${row.docNum ?? '—'} · ${row.cardCode ?? '—'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            totalStr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                          onTap: de == null
                              ? null
                              : () => Navigator.of(context).pop(de),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
