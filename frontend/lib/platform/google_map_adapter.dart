import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../features/map/map_render_model.dart';

/// [TASK-05] SDK 경계. 일정 갱신·편집·확대 전환에서 카메라를 보존합니다.
final class GoogleMapAdapter {
  final _cameras = <String, CameraPosition>{};

  Widget build({
    required String viewId,
    required MapRenderModel model,
    required ValueChanged<String> onSelect,
  }) => _GoogleTripMap(
    key: ValueKey(viewId),
    model: model,
    onSelect: onSelect,
    initialCamera: _cameras[viewId],
    onCamera: (camera) => _cameras[viewId] = camera,
  );
}

class _GoogleTripMap extends StatefulWidget {
  const _GoogleTripMap({
    super.key,
    required this.model,
    required this.onSelect,
    required this.initialCamera,
    required this.onCamera,
  });
  final MapRenderModel model;
  final ValueChanged<String> onSelect;
  final CameraPosition? initialCamera;
  final ValueChanged<CameraPosition> onCamera;
  @override
  State<_GoogleTripMap> createState() => _GoogleTripMapState();
}

class _GoogleTripMapState extends State<_GoogleTripMap> {
  GoogleMapController? _controller;
  final _icons = <String, BitmapDescriptor>{};
  final _pendingIcons = <String>{};

  String _iconKey(MapPin pin) => '${pin.colorHex}/${pin.number}';
  Future<void> _numberIcon(MapPin pin) async {
    final key = _iconKey(pin);
    if (_icons.containsKey(key) || !_pendingIcons.add(key)) return;
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final color = Color(
        int.parse(pin.colorHex.replaceFirst('#', 'FF'), radix: 16),
      );
      canvas.drawCircle(
        const Offset(32, 32),
        30,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(const Offset(32, 32), 27, Paint()..color = color);
      final text = TextPainter(
        text: TextSpan(
          text: '${pin.number}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(32 - text.width / 2, 32 - text.height / 2));
      final picture = recorder.endRecording();
      final bitmap = await picture.toImage(64, 64);
      final bytes = await bitmap.toByteData(format: ui.ImageByteFormat.png);
      bitmap.dispose();
      picture.dispose();
      text.dispose();
      if (mounted && bytes != null) {
        setState(
          () => _icons[key] = BitmapDescriptor.bytes(
            bytes.buffer.asUint8List(),
            width: 36,
            height: 36,
          ),
        );
      }
    } finally {
      _pendingIcons.remove(key);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pins = widget.model.pins;
    if (pins.isEmpty) return const Center(child: Text('좌표가 있는 일정 장소가 없습니다.'));
    for (final pin in pins) {
      unawaited(_numberIcon(pin));
    }
    final first = pins.first.coordinate;
    return GoogleMap(
      initialCameraPosition:
          widget.initialCamera ??
          CameraPosition(target: LatLng(first.lat, first.lng), zoom: 12),
      onMapCreated: (controller) async {
        _controller = controller;
        if (widget.initialCamera == null && pins.length > 1) {
          final latitudes = pins.map((p) => p.coordinate.lat);
          final longitudes = pins.map((p) => p.coordinate.lng);
          final south = latitudes.reduce(math.min),
              north = latitudes.reduce(math.max);
          final west = longitudes.reduce(math.min),
              east = longitudes.reduce(math.max);
          if (south != north || west != east) {
            await controller.moveCamera(
              CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(south, west),
                  northeast: LatLng(north, east),
                ),
                48,
              ),
            );
          }
        }
      },
      onCameraMove: widget.onCamera,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      padding: const EdgeInsets.only(bottom: 44),
      markers: {
        for (final pin in pins)
          Marker(
            markerId: MarkerId(pin.itineraryItemId),
            position: LatLng(pin.coordinate.lat, pin.coordinate.lng),
            icon: _icons[_iconKey(pin)] ?? BitmapDescriptor.defaultMarker,
            anchor: const Offset(.5, .5),
            infoWindow: InfoWindow(
              title: '${pin.number}. ${pin.title}',
              snippet: pin.placeName,
            ),
            onTap: () => widget.onSelect(pin.itineraryItemId),
          ),
      },
      polylines: {
        for (final segment in widget.model.segments)
          Polyline(
            polylineId: PolylineId(
              '${segment.fromItineraryItemId}/${segment.toItineraryItemId}',
            ),
            points: [
              LatLng(segment.from.lat, segment.from.lng),
              LatLng(segment.to.lat, segment.to.lng),
            ],
            width: 3,
            color: Color(
              int.parse(segment.colorHex.replaceFirst('#', 'FF'), radix: 16),
            ),
          ),
      },
    );
  }
}
