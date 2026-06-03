import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/customers/domain/entities/customer.dart';

/// Full details of a single customer (from GET /api/Erp/customers list item).
class CustomerDetailPage extends StatelessWidget {
  const CustomerDetailPage({super.key, required this.customer});

  final Customer customer;

  Future<void> _openCustomerLocation(BuildContext context) async {
    final uri = customer.mapsLaunchUri;
    if (uri == null) return;
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open maps'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open maps'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  static String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  static String _str(String? s) {
    final t = s?.trim() ?? '';
    return t.isEmpty ? '—' : t;
  }

  static String _money(double v) {
    if (v == 0) return '0';
    return v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(2);
  }

  /// User-facing label: hide ERP-style `u_` / `U_` prefix on keys.
  static String _displayFieldLabel(String key) {
    final k = key.trim();
    if (k.length > 2) {
      final lower = k.toLowerCase();
      if (lower.startsWith('u_')) {
        return k.substring(2);
      }
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final displayName = customer.localizedName(
      Localizations.localeOf(context).languageCode,
    );
    final mapsUri = customer.mapsLaunchUri;
    final locationText = customer.locationDisplayText;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        title: Text(
          displayName.isNotEmpty ? displayName : 'Customer',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Location', icon: Icons.my_location_outlined),
            _DetailCard(
              children: [
                if (locationText != null)
                  _DetailRow(
                    icon: Icons.pin_drop_outlined,
                    label: 'Location',
                    value: locationText,
                  ),
                if (mapsUri != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.open_in_new,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Open in maps',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  alignment: Alignment.centerLeft,
                                ),
                                onPressed: () => _openCustomerLocation(context),
                                child: const Text(
                                  'View on Google Maps',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else if (locationText == null)
                  const _DetailRow(
                    icon: Icons.info_outline,
                    label: '—',
                    value: 'No location data',
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionHeader(title: 'Basic info', icon: Icons.badge_outlined),
            _DetailCard(
              children: [
                _DetailRow(
                  icon: Icons.tag,
                  label: 'Code',
                  value: _str(customer.customerCode),
                ),
                _DetailRow(
                  icon: Icons.person_outline,
                  label: 'Name',
                  value: _str(displayName),
                ),
                if (customer.foreignName.isNotEmpty &&
                    customer.foreignName != displayName)
                  _DetailRow(
                    icon: Icons.translate_outlined,
                    label: 'Foreign name',
                    value: customer.foreignName,
                  ),
                _DetailRow(
                  icon:
                      customer.status == 1
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                  label: 'Active',
                  value: customer.status == 1 ? 'Yes' : 'No',
                  valueColor:
                      customer.status == 1
                          ? AppColors.success
                          : AppColors.textSecondary,
                ),
                _DetailRow(
                  icon: Icons.view_list_outlined,
                  label: 'Series',
                  value: _str(customer.series),
                ),
                _DetailRow(
                  icon: Icons.category_outlined,
                  label: 'Card type',
                  value: _str(customer.cardType),
                ),
                _DetailRow(
                  icon: Icons.hub_outlined,
                  label: 'Channel BP',
                  value: _str(customer.channelBP),
                ),
                if (customer.externalId.isNotEmpty)
                  _DetailRow(
                    icon: Icons.code,
                    label: 'External ID',
                    value: customer.externalId,
                  ),
                if (customer.createdAt != null)
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Created',
                    value: _formatDate(customer.createdAt!),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'Commercial',
              icon: Icons.payments_outlined,
            ),
            _DetailCard(
              children: [
                _DetailRow(
                  icon: Icons.credit_card_outlined,
                  label: 'Credit limit',
                  value: _money(customer.creditLimit),
                ),
                _DetailRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Balance',
                  value: _money(customer.balance),
                ),
                _DetailRow(
                  icon: Icons.schedule_outlined,
                  label: 'Payment terms',
                  value: _str(customer.paymentTerms),
                ),
                _DetailRow(
                  icon: Icons.price_change_outlined,
                  label: 'Price list code',
                  value: _str(customer.priceListCode),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'Territory & address',
              icon: Icons.map_outlined,
            ),
            _DetailCard(
              children: [
                _DetailRow(
                  icon: Icons.crop_square_outlined,
                  label: 'Area',
                  value: _str(customer.uArea),
                ),
                _DetailRow(
                  icon: Icons.flag_outlined,
                  label: 'Zone',
                  value: _str(customer.uGov),
                ),
                _DetailRow(
                  icon: Icons.signpost_outlined,
                  label: 'State',
                  value: _str(customer.uS),
                ),
                _DetailRow(
                  icon: Icons.location_city_outlined,
                  label: 'City',
                  value: _str(customer.city),
                ),
                _DetailRow(
                  icon: Icons.map_outlined,
                  label: 'Region',
                  value: _str(customer.uRegion),
                ),
                _DetailRow(
                  icon: Icons.terrain_outlined,
                  label: 'Territory',
                  value: _str(customer.uTerr),
                ),
                _DetailRow(
                  icon: Icons.home_outlined,
                  label: 'Address',
                  value: _str(customer.address),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'Contact',
              icon: Icons.contact_phone_outlined,
            ),
            _DetailCard(
              children: [
                _DetailRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone 1',
                  value: _str(customer.phone),
                ),
                _DetailRow(
                  icon: Icons.phone_in_talk_outlined,
                  label: 'Phone 2',
                  value: _str(customer.phone2),
                ),
                _DetailRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: _str(customer.email),
                ),
              ],
            ),
            if (customer.extendedProperties != null &&
                customer.extendedProperties!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionHeader(
                title: 'Extended properties',
                icon: Icons.extension_outlined,
              ),
              _DetailCard(
                children: () {
                  final keys = customer.extendedProperties!.keys.toList()
                    ..sort();
                  return keys.map((key) {
                    final v = customer.extendedProperties![key];
                  return _DetailRow(
                    icon: Icons.label_outline,
                    label: _displayFieldLabel(key),
                    value: v == null ? '—' : v.toString(),
                  );
                  }).toList();
                }(),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final displayName = customer.localizedName(
      Localizations.localeOf(context).languageCode,
    );
    final initial =
        displayName.isNotEmpty
            ? displayName.substring(0, 1).toUpperCase()
            : customer.customerCode.isNotEmpty
            ? customer.customerCode.substring(0, 1).toUpperCase()
            : '?';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName.isNotEmpty ? displayName : '—',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customer.customerCode,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (customer.status == 1) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Active',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: valueColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
