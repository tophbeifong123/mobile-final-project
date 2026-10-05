import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/provinces/thai_province.dart';
import '../../../../core/theme/app_tokens.dart';

/// A map-only picker: province centers come from the server's province master,
/// and the user places or drags the pin manually (no address lookup service).
class OfficeMapPicker extends StatelessWidget {
  const OfficeMapPicker({
    super.key,
    required this.province,
    required this.pin,
    required this.onPinChanged,
  });

  final ThaiProvince province;
  final LatLng? pin;
  final ValueChanged<LatLng?> onPinChanged;

  @override
  Widget build(BuildContext context) {
    final center = LatLng(province.centerLatitude, province.centerLongitude);
    final visiblePin = pin ?? center;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('หมุดสำนักงาน', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          pin == null
              ? 'หมุดเริ่มที่กึ่งกลางจังหวัด แตะหรือลากเพื่อระบุสำนักงาน'
              : 'ลากหมุดเพื่อปรับตำแหน่งสำนักงาน หรือแตะจุดใหม่บนแผนที่',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 260,
            child: FlutterMap(
              key: ValueKey('office-map-${province.id}'),
              options: MapOptions(
                initialCenter: pin ?? center,
                initialZoom: pin == null ? 10 : 15,
                minZoom: 5,
                maxZoom: 19,
                onTap: (_, position) => onPinChanged(position),
                onLongPress: (_, position) => onPinChanged(position),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.finalproject.client',
                ),
                DragMarkers(
                  markers: [
                    DragMarker(
                      key: const ValueKey('office-marker'),
                      point: visiblePin,
                      size: const Size(48, 48),
                      offset: const Offset(0, -14),
                      builder: (_, _, isDragging) => Icon(
                        Icons.location_pin,
                        size: isDragging ? 48 : 42,
                        color: pin == null
                            ? NeoColors.mutedInk
                            : NeoColors.electricIndigo,
                        shadows: const [
                          Shadow(color: Colors.white, blurRadius: 4),
                        ],
                      ),
                      onTap: (position) => onPinChanged(position),
                      onDragEnd: (_, position) => onPinChanged(position),
                    ),
                  ],
                ),
                const Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Colors.white),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Text(
                          '© OpenStreetMap contributors',
                          style: TextStyle(fontSize: 10, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (pin != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'พิกัด ${pin!.latitude.toStringAsFixed(6)}, '
                  '${pin!.longitude.toStringAsFixed(6)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TextButton.icon(
                onPressed: () => onPinChanged(null),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('ลบหมุด'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
