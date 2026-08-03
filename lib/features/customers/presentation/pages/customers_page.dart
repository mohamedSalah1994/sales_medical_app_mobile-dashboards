import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sales_medical_app_mobile/core/constants/customer_odbc_scope.dart';
import 'package:sales_medical_app_mobile/core/error/error_message_helper.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/core/utils/odbc_card_type_label.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/customers/data/models/create_erp_customer_request_model.dart';
import 'package:sales_medical_app_mobile/features/customers/data/models/customer_series_model.dart';
import 'package:sales_medical_app_mobile/features/customers/data/models/duplicate_customer_phone_exception.dart';
import 'package:sales_medical_app_mobile/features/customers/data/models/master_data_option_model.dart';
import 'package:sales_medical_app_mobile/features/customers/domain/entities/customer.dart';
import 'package:sales_medical_app_mobile/features/customers/domain/usecases/get_master_data_options_usecase.dart';
import 'package:sales_medical_app_mobile/features/customers/presentation/cubit/customers_cubit.dart';

enum _CustomerPhoneLineKind { mobile, landLine }

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardNameController = TextEditingController();
  final _cardForeignNameController = TextEditingController();
  final _channelBPController = TextEditingController();
  final _mapsLinkController = TextEditingController();
  final _phone1Controller = TextEditingController();
  final _phone2Controller = TextEditingController();
  final _vatNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _phone1FocusNode = FocusNode();

  CustomerSeriesModel? _selectedSeries;
  Customer? _selectedChannelBPCustomer;
  MasterDataOptionModel? _selectedArea;
  MasterDataOptionModel? _selectedZone;
  MasterDataOptionModel? _selectedState;
  MasterDataOptionModel? _selectedCity;
  MasterDataOptionModel? _selectedRegion;
  MasterDataOptionModel? _selectedCustomerType;
  _CustomerPhoneLineKind _phone1Kind = _CustomerPhoneLineKind.mobile;
  _CustomerPhoneLineKind _phone2Kind = _CustomerPhoneLineKind.mobile;
  double? _selectedLatitude;
  double? _selectedLongitude;
  int _mapsLookupRequestId = 0;
  Timer? _channelBpDialogSearchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomersCubit>().loadSeries();
    });
  }

  @override
  void dispose() {
    _channelBpDialogSearchDebounce?.cancel();
    _cardNameController.dispose();
    _cardForeignNameController.dispose();
    _channelBPController.dispose();
    _mapsLinkController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _vatNumberController.dispose();
    _addressController.dispose();
    _phone1FocusNode.dispose();
    super.dispose();
  }

  /// Tries to parse latitude/longitude from common Google Maps share links.
  /// Supported patterns include:
  /// - ...?q=LAT,LNG
  /// - ...?query=LAT,LNG
  /// - .../@LAT,LNG,17z
  /// - ...?ll=LAT,LNG
  /// - ...!3dLAT!4dLNG
  /// - LAT,LNG
  static ({double lat, double lng})? _parseLatLngFromGoogleMapsLink(
    String raw,
  ) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final plainPair = RegExp(
      r'^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$',
    ).firstMatch(text);
    if (plainPair != null) {
      final lat = double.tryParse(plainPair.group(1) ?? '');
      final lng = double.tryParse(plainPair.group(2) ?? '');
      if (lat != null && lng != null && lat.abs() <= 90 && lng.abs() <= 180) {
        return (lat: lat, lng: lng);
      }
    }

    final patterns = <RegExp>[
      // /@30.12345,31.12345,17z
      RegExp(r'@(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)'),
      // ?q=30.12345,31.12345
      RegExp(r'[?&]q=(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)'),
      // ?query=30.12345,31.12345
      RegExp(r'[?&]query=(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)'),
      // ?ll=30.12345,31.12345
      RegExp(r'[?&]ll=(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)'),
      // !3d30.12345!4d31.12345
      RegExp(r'!3d(-?\d+(?:\.\d+)?)!4d(-?\d+(?:\.\d+)?)'),
    ];

    for (final re in patterns) {
      final m = re.firstMatch(text);
      if (m == null) continue;
      final lat = double.tryParse(m.group(1) ?? '');
      final lng = double.tryParse(m.group(2) ?? '');
      if (lat == null || lng == null) continue;
      if (lat.abs() > 90 || lng.abs() > 180) continue;
      return (lat: lat, lng: lng);
    }
    return null;
  }

  Future<({double lat, double lng})?> _resolveLatLngFromMapsInput(
    String raw,
  ) async {
    final direct = _parseLatLngFromGoogleMapsLink(raw);
    if (direct != null) return direct;

    final text = raw.trim();
    if (text.isEmpty || !text.startsWith('http')) return null;

    try {
      final response = await Dio().getUri(
        Uri.parse(text),
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 400,
        ),
      );
      final finalUrl = response.realUri.toString();
      return _parseLatLngFromGoogleMapsLink(finalUrl) ??
          _parseLatLngFromGoogleMapsLink(response.data?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  Future<void> _onMapsLinkChanged(String value) async {
    final requestId = ++_mapsLookupRequestId;
    final parsed = await _resolveLatLngFromMapsInput(value);
    if (!mounted || requestId != _mapsLookupRequestId) return;
    setState(() {
      _selectedLatitude = parsed?.lat;
      _selectedLongitude = parsed?.lng;
    });
  }

  String _googleMapsLinkFromCoords(double latitude, double longitude) {
    return 'https://www.google.com/maps?q=$latitude,$longitude';
  }

  void _showCustomerLocationErrorDialog(
    String message, {
    bool showSettingsButton = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 8),
            Text(l10n.locationErrorTitle),
          ],
        ),
        content: Text(message),
        actions: [
          if (showSettingsButton)
            TextButton(
              onPressed: () async {
                await openAppSettings();
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: Text(l10n.openSettings),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocationForCustomer() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          Navigator.of(context).pop();
          _showCustomerLocationErrorDialog(l10n.locationServicesDisabled);
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            Navigator.of(context).pop();
            _showCustomerLocationErrorDialog(l10n.locationPermissionDenied);
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          Navigator.of(context).pop();
          _showCustomerLocationErrorDialog(
            l10n.locationPermissionDeniedForever,
            showSettingsButton: true,
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      final link = _googleMapsLinkFromCoords(
        position.latitude,
        position.longitude,
      );
      setState(() {
        _mapsLinkController.text = link;
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.locationCapturedSuccess),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showCustomerLocationErrorDialog(
          userFriendlyErrorMessage(e.toString()),
        );
      }
    }
  }

  Future<void> _openGoogleMapsForManualPick() async {
    final l10n = AppLocalizations.of(context)!;
    var success = false;
    try {
      final webUrl = Uri.parse('https://www.google.com/maps');
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      success = true;
    } catch (_) {
      try {
        Uri? platformUrl;
        if (Platform.isAndroid) {
          platformUrl = Uri.parse('geo:0,0?q=');
        } else if (Platform.isIOS) {
          platformUrl = Uri.parse('comgooglemaps://');
        }
        if (platformUrl != null) {
          try {
            await launchUrl(platformUrl, mode: LaunchMode.externalApplication);
            success = true;
          } catch (_) {}
        }
        if (!success) {
          await launchUrl(
            Uri.parse('https://www.google.com/maps'),
            mode: LaunchMode.platformDefault,
          );
          success = true;
        }
      } catch (e2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(userFriendlyErrorMessage(e2.toString())),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.customersGoogleMapsOpenedSnackbar),
          duration: const Duration(seconds: 4),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openMapPicker() async {
    final l10n = AppLocalizations.of(context)!;
    LatLng selectedPoint = LatLng(
      _selectedLatitude ?? 30.0444,
      _selectedLongitude ?? 31.2357,
    );
    GoogleMapController? mapController;
    final searchController = TextEditingController();
    var searchResults = <_LocationSearchResult>[];
    var isSearching = false;
    var dialogIsActive = true;

    Future<void> searchLocation(
      BuildContext context,
      void Function(void Function()) setDialogState,
    ) async {
      final query = searchController.text.trim();
      if (query.isEmpty) {
        setDialogState(() {
          searchResults = [];
          isSearching = false;
        });
        return;
      }

      setDialogState(() {
        isSearching = true;
      });

      try {
        final response = await Dio().get(
          'https://nominatim.openstreetmap.org/search',
          queryParameters: {'q': query, 'format': 'jsonv2', 'limit': 8},
          options: Options(
            headers: {'User-Agent': 'sales_medical_app_mobile/1.0'},
          ),
        );

        final list =
            (response.data as List<dynamic>? ?? const [])
                .map(
                  (item) => _LocationSearchResult.fromJson(
                    item as Map<String, dynamic>,
                    unknownPlaceTitle: l10n.customersUnknownPlace,
                  ),
                )
                .where(
                  (item) => item.latitude != null && item.longitude != null,
                )
                .toList();

        if (!context.mounted || !dialogIsActive) return;
        setDialogState(() {
          searchResults = list;
          isSearching = false;
        });
      } catch (_) {
        if (!context.mounted || !dialogIsActive) return;
        setDialogState(() {
          searchResults = [];
          isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.customersCouldNotSearchArea),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    await showDialog<void>(
      context: context,
      useSafeArea: true,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 520,
                    maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.86,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.customersPickCustomerLocationTitle,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed:
                                  () => Navigator.of(dialogContext).pop(),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          l10n.customersPickLocationMapHint,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: searchController,
                                textInputAction: TextInputAction.search,
                                decoration: InputDecoration(
                                  hintText: l10n.customersSearchAreaHint,
                                  prefixIcon: const Icon(Icons.search),
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                onSubmitted:
                                    (_) => searchLocation(
                                      dialogContext,
                                      setDialogState,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed:
                                  isSearching
                                      ? null
                                      : () => searchLocation(
                                        dialogContext,
                                        setDialogState,
                                      ),
                              icon:
                                  isSearching
                                      ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Icon(Icons.search),
                              tooltip: l10n.customersSearchAreaTooltip,
                            ),
                          ],
                        ),
                      ),
                      if (searchResults.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 110,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              final result = searchResults[index];
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                leading: const Icon(
                                  Icons.place_outlined,
                                  size: 18,
                                ),
                                title: Text(
                                  result.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                subtitle:
                                    result.subtitle == null
                                        ? null
                                        : Text(
                                          result.subtitle!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                onTap: () {
                                  if (result.latitude == null ||
                                      result.longitude == null) {
                                    return;
                                  }
                                  final point = LatLng(
                                    result.latitude!,
                                    result.longitude!,
                                  );
                                  setDialogState(() {
                                    selectedPoint = point;
                                    searchResults = [];
                                    searchController.text = result.title;
                                  });
                                  mapController?.animateCamera(
                                    CameraUpdate.newLatLngZoom(point, 15),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(
                          height: 240,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: selectedPoint,
                                zoom: 11,
                              ),
                              onMapCreated: (controller) {
                                mapController = controller;
                              },
                              onTap: (point) {
                                setDialogState(() {
                                  selectedPoint = point;
                                });
                              },
                              markers: {
                                Marker(
                                  markerId: const MarkerId('picked_location'),
                                  position: selectedPoint,
                                ),
                              },
                              mapType: MapType.normal,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              l10n.customersLatLngLine(
                                selectedPoint.latitude.toStringAsFixed(6),
                                selectedPoint.longitude.toStringAsFixed(6),
                              ),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed:
                                        () => Navigator.of(dialogContext).pop(),
                                    child: Text(l10n.cancel),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedLatitude =
                                            selectedPoint.latitude;
                                        _selectedLongitude =
                                            selectedPoint.longitude;
                                        _mapsLinkController.text =
                                            'https://www.google.com/maps?q=${selectedPoint.latitude.toStringAsFixed(6)},${selectedPoint.longitude.toStringAsFixed(6)}';
                                      });
                                      Navigator.of(dialogContext).pop();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(
                                      l10n.customersMapConfirmPick,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
    dialogIsActive = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      searchController.dispose();
    });
  }

  void _showValidationSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static const _mobilePrefix = '2';

  String _phoneApiValue(String digits, _CustomerPhoneLineKind kind) {
    if (kind == _CustomerPhoneLineKind.mobile) {
      return '$_mobilePrefix$digits';
    }
    return digits;
  }

  String? _validatePhoneField(
    String? value,
    _CustomerPhoneLineKind kind,
    {
    required bool required,
    required AppLocalizations l10n,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return required ? l10n.customersFieldRequired : null;
    }
    if (!RegExp(r'^\d+$').hasMatch(text)) {
      return l10n.customersPhoneDigitsOnly;
    }
    final maxLen =
        kind == _CustomerPhoneLineKind.mobile ? 11 : 10;
    if (text.length > maxLen) {
      return l10n.customersPhoneMaxLengthInvalid(maxLen);
    }
    return null;
  }

  void _showPhoneKindPicker({
    required _CustomerPhoneLineKind current,
    required TextEditingController controller,
    required ValueChanged<_CustomerPhoneLineKind> onKindChanged,
  }) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.smartphone_outlined),
                title: Text(l10n.customersPhoneKindMobile),
                trailing:
                    current == _CustomerPhoneLineKind.mobile
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  if (current == _CustomerPhoneLineKind.mobile) return;
                  controller.clear();
                  onKindChanged(_CustomerPhoneLineKind.mobile);
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone_in_talk_outlined),
                title: Text(l10n.customersPhoneKindLandLine),
                trailing:
                    current == _CustomerPhoneLineKind.landLine
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  if (current == _CustomerPhoneLineKind.landLine) return;
                  controller.clear();
                  onKindChanged(_CustomerPhoneLineKind.landLine);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  bool _validateRequiredPickers(AppLocalizations l10n) {
    if (_selectedSeries == null) {
      _showValidationSnackBar(l10n.customersSelectSeriesRequired);
      return false;
    }
    if (_selectedArea == null) {
      _showValidationSnackBar(l10n.customersSelectAreaRequired);
      return false;
    }
    if (_selectedZone == null) {
      _showValidationSnackBar(l10n.customersSelectZoneRequired);
      return false;
    }
    if (_selectedState == null) {
      _showValidationSnackBar(l10n.customersSelectStateRequired);
      return false;
    }
    if (_selectedCity == null) {
      _showValidationSnackBar(l10n.customersSelectCityRequired);
      return false;
    }
    if (_selectedRegion == null) {
      _showValidationSnackBar(l10n.customersSelectRegionRequired);
      return false;
    }
    if (_selectedCustomerType == null) {
      _showValidationSnackBar(l10n.customersSelectCustomerTypeRequired);
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_validateRequiredPickers(l10n)) return;
    if (!_formKey.currentState!.validate()) return;
    final link = _mapsLinkController.text.trim();
    var latitude = _selectedLatitude;
    var longitude = _selectedLongitude;
    if (link.isNotEmpty && (latitude == null || longitude == null)) {
      final resolved = await _resolveLatLngFromMapsInput(link);
      if (resolved != null) {
        latitude = resolved.lat;
        longitude = resolved.lng;
        if (mounted) {
          setState(() {
            _selectedLatitude = resolved.lat;
            _selectedLongitude = resolved.lng;
          });
        }
      } else if (mounted) {
        _showValidationSnackBar(l10n.customersInvalidMapsLink);
        return;
      }
    }
    if (latitude == null || longitude == null) {
      if (!mounted) return;
      _showValidationSnackBar(l10n.customersLocationRequired);
      return;
    }
    if (!mounted) return;
    final cubit = context.read<CustomersCubit>();
    final formattedLocPnt = '($latitude,$longitude)';
    final mapsLink =
        link.isNotEmpty
            ? link
            : 'https://www.google.com/maps?q=$latitude,$longitude';
    final body = CreateErpCustomerRequestModel(
      series: '${_selectedSeries!.series}',
      cardName: _cardNameController.text.trim(),
      cardType: 'L',
      cardForeignName: _cardForeignNameController.text.trim(),
      channelBP:
          _channelBPController.text.trim().isEmpty
              ? null
              : _channelBPController.text.trim(),
      uNArea: _selectedArea!.name,
      uZone: _selectedZone!.name,
      uS: _selectedState!.name,
      uC: _selectedCity!.name,
      uRegion: _selectedRegion!.name,
      uLocPnt: formattedLocPnt,
      uGLink: mapsLink,
      phone1: _phoneApiValue(_phone1Controller.text.trim(), _phone1Kind),
      phone2:
          _phone2Controller.text.trim().isEmpty
              ? null
              : _phoneApiValue(_phone2Controller.text.trim(), _phone2Kind),
      address: _addressController.text.trim(),
      uCusTyp: _selectedCustomerType!.code,
      vatNumber:
          _vatNumberController.text.trim().isEmpty
              ? null
              : _vatNumberController.text.trim(),
      confirmDuplicatePhone: false,
    );
    Map<String, dynamic>? created;
    try {
      created = await cubit.createCustomer(body);
    } on DuplicateCustomerPhoneException catch (e) {
      if (!mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final dialogL10n = AppLocalizations.of(dialogContext)!;
          return AlertDialog(
            title: Text(dialogL10n.customersDuplicatePhoneTitle),
            content: Text(e.displayMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(dialogL10n.customersDuplicatePhoneCreateAnyway),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(dialogL10n.customersDuplicatePhoneChange),
              ),
            ],
          );
        },
      );
      // "Change" → don't post, focus Phone 1. "Create anyway" → post with true.
      if (proceed != true) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _phone1FocusNode.requestFocus();
          final ctx = _phone1FocusNode.context;
          if (ctx != null) {
            Scrollable.ensureVisible(
              ctx,
              duration: const Duration(milliseconds: 250),
              alignment: 0.3,
              curve: Curves.easeOut,
            );
          }
        });
        return;
      }
      if (!mounted) return;
      created = await cubit.createCustomer(
        body.copyWith(confirmDuplicatePhone: true),
      );
    }
    if (mounted && created != null) {
      final l10n = AppLocalizations.of(context)!;
      final code = created['code']?.toString().trim() ?? '';
      final name =
          created['name']?.toString().trim().isNotEmpty == true
              ? created['name']!.toString().trim()
              : _cardNameController.text.trim();
      final String message =
          (code.isNotEmpty || name.isNotEmpty)
              ? l10n.customersCustomerCreatedWithDetails(
                  [code, name].where((s) => s.isNotEmpty).join(' - '),
                )
              : l10n.customersCustomerCreatedSuccess;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Return code/name so the list screen can search for the new lead.
      final searchHint = code.isNotEmpty ? code : name;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(searchHint.isEmpty ? null : searchHint);
      } else {
        _clearForm();
      }
    }
  }

  void _clearForm() {
    setState(() {
      _selectedSeries = null;
      _selectedChannelBPCustomer = null;
      _selectedArea = null;
      _selectedZone = null;
      _selectedState = null;
      _selectedCity = null;
      _selectedRegion = null;
      _selectedCustomerType = null;
      _phone1Kind = _CustomerPhoneLineKind.mobile;
      _phone2Kind = _CustomerPhoneLineKind.mobile;
      _selectedLatitude = null;
      _selectedLongitude = null;
    });
    _cardNameController.clear();
    _cardForeignNameController.clear();
    _channelBPController.clear();
    _mapsLinkController.clear();
    _phone1Controller.clear();
    _phone2Controller.clear();
    _vatNumberController.clear();
    _addressController.clear();
  }

  void _showChannelBPCustomerDialog() {
    final salesEmployeeCode =
        context
            .read<AuthCubit>()
            .state
            .loginResponse
            ?.user
            .sapSalesEmployeeCode;
    context.read<CustomersCubit>().getCustomers(
      salesEmployeeCode: salesEmployeeCode,
      pageNumber: 1,
      pageSize: 10,
      scope: CustomerOdbcScope.customersOnly,
    );
    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<CustomersCubit>(),
            child: BlocBuilder<CustomersCubit, CustomersState>(
              buildWhen:
                  (p, c) =>
                      p.customers != c.customers ||
                      p.isLoading != c.isLoading ||
                      p.error != c.error,
              builder: (context, state) {
                final dlgL10n = AppLocalizations.of(context)!;
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 500,
                      maxHeight: 500,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  dlgL10n.customersSelectChannelBpTitle,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed:
                                    () => Navigator.of(dialogContext).pop(),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: dlgL10n.customersSearchCustomersEllipsis,
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.textSecondary,
                                size: 18,
                              ),
                              filled: true,
                              fillColor: AppColors.card,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              _channelBpDialogSearchDebounce?.cancel();
                              _channelBpDialogSearchDebounce = Timer(
                                const Duration(seconds: 1),
                                () {
                                  if (!mounted) return;
                                  final q = value.trim();
                                  context.read<CustomersCubit>().getCustomers(
                                    search: q.isEmpty ? null : q,
                                    salesEmployeeCode: salesEmployeeCode,
                                    pageNumber: 1,
                                    pageSize: 10,
                                    scope: CustomerOdbcScope.customersOnly,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child:
                              state.isLoading
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : state.customers.isEmpty
                                  ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Text(
                                        state.error ??
                                            dlgL10n.customersNoCustomersFoundList,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                  : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: state.customers.length,
                                    itemBuilder: (context, index) {
                                      final customer = state.customers[index];
                                      final lang =
                                          Localizations.localeOf(
                                            context,
                                          ).languageCode;
                                      final secondary =
                                          customer.secondaryDisplayName(lang);
                                      return ListTile(
                                        title: Text(
                                          customer.localizedName(lang),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (odbcCardTypeKindLabel(
                                                  customer.cardType,
                                                )
                                                .isNotEmpty)
                                              Text(
                                                odbcCardTypeKindLabel(
                                                  customer.cardType,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.95),
                                                ),
                                              ),
                                            Text(customer.customerCode),
                                            if (secondary != null)
                                              Text(
                                                secondary,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                          ],
                                        ),
                                        isThreeLine:
                                            secondary != null ||
                                            odbcCardTypeKindLabel(
                                              customer.cardType,
                                            ).isNotEmpty,
                                        onTap: () {
                                          setState(
                                            () =>
                                                _selectedChannelBPCustomer =
                                                    customer,
                                          );
                                          _channelBPController.text =
                                              customer.customerCode;
                                          Navigator.of(dialogContext).pop();
                                        },
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
    ).whenComplete(() => _channelBpDialogSearchDebounce?.cancel());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final content = BlocListener<CustomersCubit, CustomersState>(
      listenWhen: (p, c) => p.createError != c.createError && c.createError != null,
      listener: (context, state) {
        final message = state.createError;
        if (message == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Clear after showing so it cannot leak into list / search UI.
        context.read<CustomersCubit>().clearCreateError();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              _buildDropdown(l10n),
              const SizedBox(height: 16),
              _buildField(
                l10n.customersFieldName,
                _cardNameController,
                required: true,
                hint: 'English name only',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r"[a-zA-Z0-9\s\-'.,&()/]"),
                  ),
                ],
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null;
                  if (!RegExp(r"^[a-zA-Z0-9\s\-'.,&()/]+$").hasMatch(text)) {
                    return l10n.customersEnglishNameOnly;
                  }
                  return null;
                },
              ),
              _buildField(
                l10n.customersFieldArabicName,
                _cardForeignNameController,
                required: true,
                hint: 'الاسم بالعربية فقط',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(
                      r"[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF0-9\s\-'.,،]",
                    ),
                  ),
                ],
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null;
                  if (!RegExp(
                    r"^[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF0-9\s\-'.,،]+$",
                  ).hasMatch(text)) {
                    return l10n.customersArabicNameOnly;
                  }
                  return null;
                },
              ),
              _buildChannelBPPicker(l10n),
              const SizedBox(height: 12),
              Text(
                l10n.customersCustomerLocationSection,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.customersLocationHowTo,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _mapsLinkController,
                      decoration: InputDecoration(
                        labelText: l10n.customersGoogleMapsLinkLabel,
                        hintText: l10n.customersGoogleMapsLinkHint,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.location_on, size: 20),
                      ),
                      onChanged: _onMapsLinkChanged,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _getCurrentLocationForCustomer,
                    icon: const Icon(
                      Icons.my_location,
                      color: AppColors.primary,
                    ),
                    tooltip: l10n.tooltipGetCurrentLocation,
                  ),
                  IconButton(
                    onPressed: _openGoogleMapsForManualPick,
                    icon: const Icon(Icons.map, color: AppColors.primary),
                    tooltip: l10n.tooltipOpenMapsSelectLocation,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.standaloneMapsLocationTip,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (_selectedLatitude != null && _selectedLongitude != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.customersLatitude,
                          border: const OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedLatitude!.toStringAsFixed(6),
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.customersLongitude,
                          border: const OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedLongitude!.toStringAsFixed(6),
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _openMapPicker,
                icon: const Icon(Icons.location_searching, size: 18),
                label: Text(l10n.customersPickOnMap),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              _buildAreaPicker(l10n),
              _buildZonePicker(l10n),
              _buildStatePicker(l10n),
              _buildCityPicker(l10n),
              _buildRegionPicker(l10n),
              _buildCustomerTypePicker(),
              _buildField(
                l10n.customersFieldAddress,
                _addressController,
                required: true,
              ),
              _buildCustomerPhoneField(
                l10n: l10n,
                label: l10n.customersFieldPhone1,
                controller: _phone1Controller,
                focusNode: _phone1FocusNode,
                kind: _phone1Kind,
                required: true,
                onKindChanged:
                    (k) => setState(() => _phone1Kind = k),
              ),
              _buildCustomerPhoneField(
                l10n: l10n,
                label: l10n.customersFieldPhone2,
                controller: _phone2Controller,
                kind: _phone2Kind,
                required: false,
                onKindChanged:
                    (k) => setState(() => _phone2Kind = k),
              ),
              _buildField(
                l10n.customersFieldVatNumber,
                _vatNumberController,
              ),
              const SizedBox(height: 24),
              BlocBuilder<CustomersCubit, CustomersState>(
                buildWhen: (p, c) => p.isCreating != c.isCreating,
                builder: (context, state) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.isCreating ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child:
                          state.isCreating
                              ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(l10n.customersCreateCustomerTitle),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (!widget.showScaffold) return content;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          l10n.customersCreateCustomerTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: content,
    );
  }

  Widget _buildAreaPicker(AppLocalizations l10n) {
    return _buildMasterDataRow(
      label: l10n.customersFieldArea,
      placeholder: l10n.customersSelectArea,
      value: _selectedArea?.name,
      enabled: true,
      onTap: () => _showMasterDataDialog(
        section: MasterDataSection.areas,
        title: l10n.customersSelectAreaTitle,
        onSelect: (opt) {
          setState(() {
            _selectedArea = opt;
            _selectedZone = null;
            _selectedState = null;
            _selectedCity = null;
            _selectedRegion = null;
          });
        },
      ),
    );
  }

  Widget _buildZonePicker(AppLocalizations l10n) {
    final hasArea = _selectedArea != null;
    return _buildMasterDataRow(
      label: l10n.customersFieldZone,
      placeholder:
          hasArea ? l10n.customersSelectZone : l10n.customersSelectZoneFirst,
      value: _selectedZone?.name,
      enabled: hasArea,
      onTap: () => _showMasterDataDialog(
        section: MasterDataSection.areaUdtZones,
        parentTerritoryId: _selectedArea!.name,
        title: l10n.customersSelectZoneTitle,
        onSelect: (opt) {
          setState(() {
            _selectedZone = opt;
            _selectedState = null;
            _selectedCity = null;
            _selectedRegion = null;
          });
        },
      ),
    );
  }

  Widget _buildStatePicker(AppLocalizations l10n) {
    final hasZone = _selectedZone != null;
    return _buildMasterDataRow(
      label: l10n.customersFieldState,
      placeholder:
          hasZone
              ? l10n.customersSelectState
              : l10n.customersSelectStateZoneFirst,
      value: _selectedState?.name,
      enabled: hasZone,
      onTap: () {
        _showMasterDataDialog(
          section: MasterDataSection.areaUdtStates,
          parentTerritoryId: _selectedZone!.name,
          title: l10n.customersSelectStateTitle,
          onSelect: (opt) {
            setState(() {
              _selectedState = opt;
              _selectedCity = null;
              _selectedRegion = null;
            });
          },
        );
      },
    );
  }

  Widget _buildCustomerTypePicker() {
    return _buildMasterDataRow(
      label: 'Customer Type',
      placeholder: 'Select customer type',
      value: _selectedCustomerType?.name,
      enabled: true,
      onTap: () => _showMasterDataDialog(
        section: MasterDataSection.customerTypes,
        title: 'Select customer type',
        onSelect: (opt) {
          setState(() => _selectedCustomerType = opt);
        },
      ),
    );
  }

  Widget _buildCityPicker(AppLocalizations l10n) {
    final hasState = _selectedState != null;
    return _buildMasterDataRow(
      label: l10n.customersFieldCity,
      placeholder:
          hasState ? l10n.customersSelectCity : l10n.customersSelectStateFirst,
      value: _selectedCity?.name,
      enabled: hasState,
      onTap: () {
        _showMasterDataDialog(
          section: MasterDataSection.areaUdtCities,
          parentTerritoryId: _selectedState!.name,
          title: l10n.customersSelectCityTitle,
          onSelect: (opt) {
            setState(() {
              _selectedCity = opt;
              _selectedRegion = null;
            });
          },
        );
      },
    );
  }

  Widget _buildRegionPicker(AppLocalizations l10n) {
    final hasCity = _selectedCity != null;
    return _buildMasterDataRow(
      label: l10n.customersFieldRegion,
      placeholder:
          hasCity ? l10n.customersSelectRegion : l10n.customersSelectCityFirst,
      value: _selectedRegion?.name,
      enabled: hasCity,
      onTap: () {
        _showMasterDataDialog(
          section: MasterDataSection.areaUdtRegions,
          parentTerritoryId: _selectedCity!.name,
          title: l10n.customersSelectRegionTitle,
          onSelect: (opt) {
            setState(() => _selectedRegion = opt);
          },
        );
      },
    );
  }

  Widget _buildMasterDataRow({
    required String label,
    required String placeholder,
    required String? value,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final display = (value != null && value.isNotEmpty) ? value : placeholder;
    final isPlaceholder = value == null || value.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(
            display,
            style: TextStyle(
              color:
                  isPlaceholder
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  void _showMasterDataDialog({
    required MasterDataSection section,
    String? parentTerritoryId,
    required String title,
    required void Function(MasterDataOptionModel) onSelect,
  }) {
    context.read<CustomersCubit>().loadMasterDataOptions(
      section: section,
      parentTerritoryId: parentTerritoryId,
    );
    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<CustomersCubit>(),
            child: _MasterDataPickerDialog(
              title: title,
              onSelect: (MasterDataOptionModel opt) {
                onSelect(opt);
                Navigator.of(dialogContext).pop();
              },
            ),
          ),
    );
  }

  Widget _buildChannelBPPicker(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _showChannelBPCustomerDialog,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: l10n.customersChannelBpLabel,
            filled: true,
            fillColor: AppColors.card,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(
            _selectedChannelBPCustomer != null
                ? '${_selectedChannelBPCustomer!.customerCode} - ${_selectedChannelBPCustomer!.name}'
                : l10n.customersSelectCustomerPlaceholder,
            style: TextStyle(
              color:
                  _selectedChannelBPCustomer != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(AppLocalizations l10n) {
    return BlocBuilder<CustomersCubit, CustomersState>(
      buildWhen:
          (p, c) =>
              p.series != c.series || p.isLoadingSeries != c.isLoadingSeries,
      builder: (context, state) {
        if (state.isLoadingSeries) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final list = state.series;
        // Use value from current list so dropdown never has value not in items (avoids uncaught exception)
        CustomerSeriesModel? selectedValue;
        if (_selectedSeries != null && list.isNotEmpty) {
          for (final s in list) {
            if (s.series == _selectedSeries!.series) {
              selectedValue = s;
              break;
            }
          }
        }
        return DropdownButtonFormField<CustomerSeriesModel>(
          value: selectedValue,
          decoration: InputDecoration(
            labelText: l10n.customersSeries,
            border: const OutlineInputBorder(),
          ),
          items:
              list
                  .map(
                    (s) => DropdownMenuItem<CustomerSeriesModel>(
                      value: s,
                      child: Text(s.name),
                    ),
                  )
                  .toList(),
          validator: (v) => v == null ? l10n.customersSelectSeriesRequired : null,
          onChanged: (v) => setState(() => _selectedSeries = v),
        );
      },
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hint,
    Widget? prefixIcon,
    bool required = false,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLength: maxLength,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          prefixIcon: prefixIcon,
          prefixIconConstraints:
              prefixIcon != null
                  ? const BoxConstraints(minWidth: 40, minHeight: 0)
                  : null,
          border: const OutlineInputBorder(),
          counterText: maxLength != null ? '' : null,
        ),
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return l10n.customersFieldRequired;
          }
          if (validator != null) {
            return validator(value);
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCustomerPhoneField({
    required AppLocalizations l10n,
    required String label,
    required TextEditingController controller,
    FocusNode? focusNode,
    required _CustomerPhoneLineKind kind,
    required bool required,
    required ValueChanged<_CustomerPhoneLineKind> onKindChanged,
  }) {
    final isMobile = kind == _CustomerPhoneLineKind.mobile;
    final maxLength = isMobile ? 11 : 10;
    final hint = '0123456789';
    final kindLabel =
        isMobile ? l10n.customersPhoneKindMobile : l10n.customersPhoneKindLandLine;

    Widget? prefixIcon;
    if (isMobile) {
      prefixIcon = const Padding(
        padding: EdgeInsets.only(left: 12, right: 4),
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: 1,
          child: Text(
            _mobilePrefix,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        maxLength: maxLength,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          prefixIcon: prefixIcon,
          prefixIconConstraints:
              prefixIcon != null
                  ? const BoxConstraints(minWidth: 40, minHeight: 0)
                  : null,
          suffixIcon: InkWell(
            onTap:
                () => _showPhoneKindPicker(
                  current: kind,
                  controller: controller,
                  onKindChanged: onKindChanged,
                ),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isMobile ? Icons.smartphone_outlined : Icons.phone_in_talk_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    kindLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          border: const OutlineInputBorder(),
          counterText: '',
        ),
        validator:
            (value) => _validatePhoneField(
              value,
              kind,
              required: required,
              l10n: l10n,
            ),
      ),
    );
  }
}

class _MasterDataPickerDialog extends StatefulWidget {
  const _MasterDataPickerDialog({required this.onSelect, required this.title});

  final void Function(MasterDataOptionModel) onSelect;
  final String title;

  @override
  State<_MasterDataPickerDialog> createState() =>
      _MasterDataPickerDialogState();
}

class _MasterDataPickerDialogState extends State<_MasterDataPickerDialog> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.customersSearchMasterDataHint,
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<CustomersCubit, CustomersState>(
                buildWhen:
                    (p, c) =>
                        p.masterDataOptions != c.masterDataOptions ||
                        p.isLoadingMasterData != c.isLoadingMasterData ||
                        p.error != c.error,
                builder: (context, state) {
                  if (state.isLoadingMasterData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          state.error!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }
                  final query = _searchController.text.trim().toLowerCase();
                  final opts = state.masterDataOptions;
                  final filtered =
                      query.isEmpty
                          ? opts
                          : opts.where((t) {
                            return t.name.toLowerCase().contains(query) ||
                                t.code.toLowerCase().contains(query);
                          }).toList();
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        query.isEmpty
                            ? l10n.customersNoMasterDataFound
                            : l10n.customersNoMatchingMasterData,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final t = filtered[index];
                      return ListTile(
                        title: Text(t.name),
                        subtitle:
                            (t.code.isNotEmpty && t.code != t.name)
                                ? Text(t.code)
                                : null,
                        onTap: () => widget.onSelect(t),
                      );
                    },
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

class _LocationSearchResult {
  const _LocationSearchResult({
    required this.title,
    this.subtitle,
    this.latitude,
    this.longitude,
  });

  final String title;
  final String? subtitle;
  final double? latitude;
  final double? longitude;

  factory _LocationSearchResult.fromJson(
    Map<String, dynamic> json, {
    required String unknownPlaceTitle,
  }) {
    final displayName = (json['display_name'] as String? ?? '').trim();
    final parts =
        displayName.isEmpty
            ? const <String>[]
            : displayName.split(',').map((part) => part.trim()).toList();
    return _LocationSearchResult(
      title: parts.isNotEmpty ? parts.first : unknownPlaceTitle,
      subtitle: parts.length > 1 ? parts.skip(1).join(', ') : null,
      latitude: double.tryParse((json['lat'] ?? '').toString()),
      longitude: double.tryParse((json['lon'] ?? '').toString()),
    );
  }
}
