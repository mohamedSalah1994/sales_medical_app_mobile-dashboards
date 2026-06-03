import 'package:flutter/material.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/models/warehouse_odbc_model.dart';

/// Bottom sheet: search field + filtered list of warehouses.
Future<WarehouseOdbcModel?> showWarehouseSearchableSheet(
  BuildContext context, {
  required List<WarehouseOdbcModel> warehouses,
  String title = 'Select warehouse',
}) {
  return showModalBottomSheet<WarehouseOdbcModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _WarehouseSearchableSheet(
      warehouses: warehouses,
      title: title,
    ),
  );
}

class _WarehouseSearchableSheet extends StatefulWidget {
  const _WarehouseSearchableSheet({
    required this.warehouses,
    required this.title,
  });

  final List<WarehouseOdbcModel> warehouses;
  final String title;

  @override
  State<_WarehouseSearchableSheet> createState() =>
      _WarehouseSearchableSheetState();
}

class _WarehouseSearchableSheetState extends State<_WarehouseSearchableSheet> {
  final _searchController = TextEditingController();
  late List<WarehouseOdbcModel> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = List<WarehouseOdbcModel>.from(widget.warehouses);
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List<WarehouseOdbcModel>.from(widget.warehouses);
      } else {
        _filtered =
            widget.warehouses.where((w) {
              final code = w.code.toLowerCase();
              final name = (w.name ?? '').toLowerCase();
              return code.contains(q) || name.contains(q);
            }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final h = MediaQuery.of(context).size.height * 0.75;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        height: h,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search by code or name...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child:
                  _filtered.isEmpty
                      ? Center(
                        child: Text(
                          'No warehouses match your search.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final w = _filtered[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 4,
                            ),
                            title: Text(
                              w.code,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle:
                                w.name != null && w.name!.isNotEmpty
                                    ? Text(
                                      w.name!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    )
                                    : null,
                            onTap: () => Navigator.of(context).pop(w),
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
