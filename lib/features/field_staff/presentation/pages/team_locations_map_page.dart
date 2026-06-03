import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/utils/reverse_geocode_place.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/field_staff/data/models/team_member_location_model.dart';
import 'package:sales_medical_app_mobile/features/field_staff/presentation/cubit/team_locations_cubit.dart';
import 'package:sales_medical_app_mobile/features/field_staff/presentation/widgets/team_map_named_marker_bitmap.dart';
import 'package:url_launcher/url_launcher.dart';

/// Default center when the team has no valid coordinates yet.
const LatLng _kDefaultCenter = LatLng(26.8206, 30.8025);

class TeamLocationsMapPage extends StatefulWidget {
  const TeamLocationsMapPage({super.key});

  @override
  State<TeamLocationsMapPage> createState() => _TeamLocationsMapPageState();
}

class _TeamLocationsMapPageState extends State<TeamLocationsMapPage> {
  GoogleMapController? _mapController;
  late final TeamLocationsCubit _teamCubit;

  /// Custom marker icon per user (name shown above pin in bitmap).
  final Map<String, BitmapDescriptor> _memberMarkerIcons = {};
  final Map<String, String> _markerLabelKeyByUserId = {};
  final Map<String, int> _markerLoadGeneration = {};

  @override
  void initState() {
    super.initState();
    _teamCubit = context.read<TeamLocationsCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _teamCubit.startPolling();
      _refreshMarkerIconsIfNeeded(_teamCubit.state.members);
    });
  }

  void _refreshMarkerIconsIfNeeded(List<TeamMemberLocationModel> members) {
    if (!mounted) return;
    final dir = Directionality.of(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);

    final withCoords =
        members.where((m) => m.isCurrentlyOnline && m.hasCoordinates).toList();
    final activeIds = withCoords.map((m) => m.userId).toSet();

    _memberMarkerIcons.removeWhere((id, _) => !activeIds.contains(id));
    _markerLabelKeyByUserId.removeWhere((id, _) => !activeIds.contains(id));
    _markerLoadGeneration.removeWhere((id, _) => !activeIds.contains(id));

    for (final m in withCoords) {
      final label = m.fullName.isNotEmpty ? m.fullName : m.userId;
      final prevLabel = _markerLabelKeyByUserId[m.userId];
      if (prevLabel == label && _memberMarkerIcons.containsKey(m.userId)) {
        continue;
      }
      if (prevLabel != null && prevLabel != label) {
        setState(() => _memberMarkerIcons.remove(m.userId));
      }
      _markerLabelKeyByUserId[m.userId] = label;
      final gen = (_markerLoadGeneration[m.userId] ?? 0) + 1;
      _markerLoadGeneration[m.userId] = gen;
      createTeamMapMemberMarkerBitmap(
        displayName: label,
        textDirection: dir,
        devicePixelRatio: dpr,
      ).then((icon) {
        if (!mounted) return;
        if (_markerLoadGeneration[m.userId] != gen) return;
        setState(() {
          _memberMarkerIcons[m.userId] = icon;
        });
      });
    }
  }

  @override
  void dispose() {
    _teamCubit.stopPolling();
    super.dispose();
  }

  Future<void> _fitBounds(List<TeamMemberLocationModel> members) async {
    final ctrl = _mapController;
    if (ctrl == null) return;
    final pts = <LatLng>[];
    for (final m in members) {
      if (m.isCurrentlyOnline && m.hasCoordinates) {
        pts.add(LatLng(m.latitude!, m.longitude!));
      }
    }
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      await ctrl.animateCamera(CameraUpdate.newLatLngZoom(pts.first, 14));
      return;
    }
    double minLat = pts.first.latitude;
    double maxLat = pts.first.latitude;
    double minLng = pts.first.longitude;
    double maxLng = pts.first.longitude;
    for (final p in pts) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }
    if ((maxLat - minLat).abs() < 1e-5) {
      minLat -= 0.002;
      maxLat += 0.002;
    }
    if ((maxLng - minLng).abs() < 1e-5) {
      minLng -= 0.002;
      maxLng += 0.002;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    try {
      await ctrl.animateCamera(CameraUpdate.newLatLngBounds(bounds, 64));
    } catch (_) {
      await ctrl.animateCamera(CameraUpdate.newLatLngZoom(pts.first, 12));
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final state = _teamCubit.state;
    if (state.members.any((m) => m.isCurrentlyOnline && m.hasCoordinates)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitBounds(state.members);
      });
    }
  }

  Future<void> _openInMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showSalesRepDetails(BuildContext context, TeamMemberLocationModel m) {
    if (!m.hasCoordinates) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return _TeamMemberLocationBottomSheet(
          member: m,
          onOpenInMaps: _openInMaps,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<TeamLocationsCubit, TeamLocationsState>(
      listenWhen: (p, c) => p.members != c.members,
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _refreshMarkerIconsIfNeeded(state.members);
        });
        if (state.members.any((m) => m.isCurrentlyOnline && m.hasCoordinates)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _fitBounds(state.members);
          });
        }
      },
      builder: (context, state) {
        final markers = <Marker>{};
        for (final m in state.members) {
          if (!m.isCurrentlyOnline || !m.hasCoordinates) continue;
          final label = m.fullName.isNotEmpty ? m.fullName : m.userId;
          markers.add(
            Marker(
              markerId: MarkerId('team_${m.userId}'),
              position: LatLng(m.latitude!, m.longitude!),
              anchor: const Offset(0.5, 1),
              icon:
                  _memberMarkerIcons[m.userId] ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
              infoWindow: InfoWindow(title: label),
              onTap: () => _showSalesRepDetails(context, m),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.lastUpdated != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  l10n.teamMapLastUpdated(
                    DateFormat.Hm().format(state.lastUpdated!.toLocal()),
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: _kDefaultCenter,
                      zoom: 6,
                    ),
                    onMapCreated: _onMapCreated,
                    markers: markers,
                    mapType: MapType.normal,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: true,
                  ),
                  if (state.isLoading && state.members.isEmpty)
                    const Center(child: CircularProgressIndicator()),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: FloatingActionButton.small(
                      heroTag: 'team_map_refresh',
                      onPressed:
                          () =>
                              context
                                  .read<TeamLocationsCubit>()
                                  .fetchTeamLocations(),
                      child: const Icon(Icons.refresh),
                    ),
                  ),
                ],
              ),
            ),
            _TeamListPanel(
              members: state.members,
              isLoading: state.isLoading,
              error: state.error,
              onMemberTap: (m) => _showSalesRepDetails(context, m),
            ),
          ],
        );
      },
    );
  }
}

class _TeamMemberLocationBottomSheet extends StatefulWidget {
  const _TeamMemberLocationBottomSheet({
    required this.member,
    required this.onOpenInMaps,
  });

  final TeamMemberLocationModel member;
  final void Function(double lat, double lng) onOpenInMaps;

  @override
  State<_TeamMemberLocationBottomSheet> createState() =>
      _TeamMemberLocationBottomSheetState();
}

class _TeamMemberLocationBottomSheetState
    extends State<_TeamMemberLocationBottomSheet> {
  String? _placeLabel;
  bool _loadingPlace = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_resolveNearbyPlace());
    });
  }

  Future<void> _resolveNearbyPlace() async {
    final m = widget.member;
    final lat = m.latitude!;
    final lng = m.longitude!;
    final locale = Localizations.localeOf(context);

    try {
      final label = await reverseGeocodeNearbyPlace(lat, lng, locale: locale);
      if (!mounted) return;
      setState(() {
        _placeLabel = label;
        _loadingPlace = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _placeLabel = null;
        _loadingPlace = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final m = widget.member;
    final name = m.fullName.isNotEmpty ? m.fullName : m.userId;
    final lat = m.latitude!;
    final lng = m.longitude!;
    final timeStr =
        m.updatedAt != null
            ? DateFormat.yMMMd().add_Hm().format(m.updatedAt!.toLocal())
            : '—';
    final statusText = m.isCurrentlyOnline ? 'Online' : 'Offline';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.teamMapMemberDetailsTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _TeamMapPlaceRow(
              label: l10n.teamMapMemberPlaceLabel,
              loading: _loadingPlace,
              loadingText: l10n.teamMapPlaceLookupLoading,
              placeText: _placeLabel,
              unknownText: l10n.teamMapPlaceUnknown,
            ),
            _TeamMapDetailRow(
              label: l10n.teamMapMemberLatitudeLabel,
              value: lat.toStringAsFixed(6),
            ),
            _TeamMapDetailRow(
              label: l10n.teamMapMemberLongitudeLabel,
              value: lng.toStringAsFixed(6),
            ),
            _TeamMapDetailRow(label: 'Status', value: statusText),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                m.isCurrentlyOnline
                    ? l10n.teamMapMemberLocationTime(timeStr)
                    : 'Last known location time: $timeStr',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (m.accuracyMeters != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.teamMapMemberAccuracyMeters(
                    m.accuracyMeters!.toStringAsFixed(0),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => widget.onOpenInMaps(lat, lng),
              icon: const Icon(Icons.map_outlined),
              label: Text(l10n.teamMapOpenInMaps),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamMapPlaceRow extends StatelessWidget {
  const _TeamMapPlaceRow({
    required this.label,
    required this.loading,
    required this.loadingText,
    required this.placeText,
    required this.unknownText,
  });

  final String label;
  final bool loading;
  final String loadingText;
  final String? placeText;
  final String unknownText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child:
                loading
                    ? Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            loadingText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    )
                    : Text(
                      placeText ?? unknownText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

class _TeamMapDetailRow extends StatelessWidget {
  const _TeamMapDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamListPanel extends StatelessWidget {
  const _TeamListPanel({
    required this.members,
    required this.isLoading,
    this.error,
    this.onMemberTap,
  });

  final List<TeamMemberLocationModel> members;
  final bool isLoading;
  final String? error;
  final void Function(TeamMemberLocationModel)? onMemberTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: AppColors.card,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  l10n.teamMapTeamList,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    error!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              Flexible(
                child:
                    members.isEmpty && !isLoading
                        ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            l10n.teamMapEmpty,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        )
                        : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          itemCount: members.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final m = members[index];
                            final has = m.hasCoordinates;
                            final online = m.isCurrentlyOnline;
                            final canOpenDetails = has && onMemberTap != null;
                            return InkWell(
                              onTap:
                                  canOpenDetails
                                      ? () => onMemberTap!(m)
                                      : null,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      has
                                          ? Icons.location_on
                                          : Icons.location_off,
                                      size: 18,
                                      color:
                                          online
                                              ? AppColors.success
                                              : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        m.fullName.isNotEmpty
                                            ? m.fullName
                                            : m.userId,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (!has)
                                      Text(
                                        l10n.teamMapNoLocation,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    if (has && !online)
                                      const Text(
                                        'Offline',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    if (has)
                                      const SizedBox(width: 8),
                                    if (has)
                                      const Icon(
                                        Icons.chevron_right,
                                        size: 18,
                                        color: AppColors.textSecondary,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
