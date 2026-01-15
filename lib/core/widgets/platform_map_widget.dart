// lib/core/widgets/platform_map_widget.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import '../theme/app_colors.dart';

/// Platform-specific map widget
/// Uses Google Maps on mobile (Android/iOS) and OpenStreetMap on web
class PlatformMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double zoom;
  final Function(double lat, double lng)? onTap;
  final Function(double lat, double lng)? onCameraMove;
  final Function(double lat, double lng)? onCameraIdle;
  final bool draggable;
  final bool showMarker;
  final Color? markerColor;
  final double? height;
  final bool enableZoomControls;
  final bool enableScrollGestures;
  final bool enableRotateGestures;
  final Function(gmaps.GoogleMapController)? onMapCreated; // For Google Maps only

  const PlatformMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.zoom = 14.0,
    this.onTap,
    this.onCameraMove,
    this.onCameraIdle,
    this.draggable = true,
    this.showMarker = true,
    this.markerColor,
    this.height,
    this.enableZoomControls = true,
    this.enableScrollGestures = true,
    this.enableRotateGestures = true,
    this.onMapCreated,
  });

  @override
  State<PlatformMapWidget> createState() => _PlatformMapWidgetState();
}

class _PlatformMapWidgetState extends State<PlatformMapWidget> {
  late MapController _osmMapController;
  late latlng.LatLng _currentPosition;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _osmMapController = MapController();
    _currentPosition = latlng.LatLng(widget.latitude, widget.longitude);
  }

  @override
  void didUpdateWidget(PlatformMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude || 
        oldWidget.longitude != widget.longitude) {
      _currentPosition = latlng.LatLng(widget.latitude, widget.longitude);
      if (kIsWeb) {
        // Update OSM map position
        _osmMapController.move(_currentPosition, widget.zoom);
      }
    }
  }

  @override
  void dispose() {
    _osmMapController.dispose();
    super.dispose();
  }

  // Build Google Maps for mobile platforms
  Widget _buildGoogleMap() {
    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(widget.latitude, widget.longitude),
        zoom: widget.zoom,
      ),
      onMapCreated: (gmaps.GoogleMapController controller) {
        widget.onMapCreated?.call(controller);
      },
      onTap: widget.onTap != null
          ? (gmaps.LatLng position) {
              widget.onTap!(position.latitude, position.longitude);
            }
          : null,
      onCameraMove: widget.onCameraMove != null
          ? (gmaps.CameraPosition position) {
              widget.onCameraMove!(
                position.target.latitude,
                position.target.longitude,
              );
            }
          : null,
      onCameraIdle: widget.onCameraIdle != null
          ? () {
              // Get current camera position from the last onCameraMove
              // The position is tracked via onCameraMove callback
              if (widget.onCameraIdle != null) {
                // Use the current widget position as fallback
                widget.onCameraIdle!(widget.latitude, widget.longitude);
              }
            }
          : null,
      markers: widget.showMarker
          ? {
              gmaps.Marker(
                markerId: const gmaps.MarkerId('selected_location'),
                position: gmaps.LatLng(widget.latitude, widget.longitude),
                draggable: widget.draggable,
                onDragEnd: widget.draggable && widget.onTap != null
                    ? (gmaps.LatLng position) {
                        widget.onTap!(position.latitude, position.longitude);
                      }
                    : null,
                icon: widget.markerColor != null
                    ? gmaps.BitmapDescriptor.defaultMarkerWithHue(
                        _colorToHue(widget.markerColor!),
                      )
                    : gmaps.BitmapDescriptor.defaultMarker,
              ),
            }
          : {},
      myLocationButtonEnabled: false,
      zoomControlsEnabled: widget.enableZoomControls,
      zoomGesturesEnabled: widget.enableZoomControls,
      scrollGesturesEnabled: widget.enableScrollGestures,
      rotateGesturesEnabled: widget.enableRotateGestures,
      tiltGesturesEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      mapType: gmaps.MapType.normal,
    );
  }

  // Build OpenStreetMap for web platform
  Widget _buildOpenStreetMap() {
    return FlutterMap(
      mapController: _osmMapController,
      options: MapOptions(
        initialCenter: _currentPosition,
        initialZoom: widget.zoom,
        minZoom: 3.0,
        maxZoom: 18.0,
        onTap: widget.onTap != null
            ? (tapPosition, point) {
                widget.onTap!(point.latitude, point.longitude);
              }
            : null,
        onMapEvent: (event) {
          if (event is MapEventMove) {
            if (widget.onCameraMove != null) {
              widget.onCameraMove!(
                event.camera.center.latitude,
                event.camera.center.longitude,
              );
            }
            _isDragging = true;
          } else if (event is MapEventMoveEnd) {
            _isDragging = false;
            if (widget.onCameraIdle != null) {
              widget.onCameraIdle!(
                event.camera.center.latitude,
                event.camera.center.longitude,
              );
            }
          }
        },
        interactionOptions: InteractionOptions(
          flags: widget.draggable
              ? (InteractiveFlag.all & ~InteractiveFlag.rotate)
              : InteractiveFlag.none,
        ),
      ),
      children: [
        // OpenStreetMap tile layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.tutorfinder.app',
          maxZoom: 19,
        ),
        // Marker layer
        if (widget.showMarker)
          MarkerLayer(
            markers: [
              Marker(
                point: _currentPosition,
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () {
                    // Marker tap handler if needed
                  },
                  child: Icon(
                    Icons.location_on,
                    color: widget.markerColor ?? AppColors.primary,
                    size: 40,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // Convert Color to BitmapDescriptor hue for Google Maps
  double _colorToHue(Color color) {
    // Simple color to hue conversion
    if (color == AppColors.primary) return gmaps.BitmapDescriptor.hueBlue;
    if (color == AppColors.success) return gmaps.BitmapDescriptor.hueGreen;
    if (color == AppColors.error) return gmaps.BitmapDescriptor.hueRed;
    if (color == AppColors.warning) return gmaps.BitmapDescriptor.hueOrange;
    return gmaps.BitmapDescriptor.hueBlue;
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // OpenStreetMap - marker is already included in the map
      return _buildOpenStreetMap();
    } else {
      // Google Maps - show map with center pin indicator
      return Stack(
        children: [
          _buildGoogleMap(),
          // Center location pin indicator for Google Maps
          if (widget.showMarker)
            Center(
              child: Icon(
                Icons.location_on,
                color: widget.markerColor ?? AppColors.primary,
                size: 40,
              ),
            ),
        ],
      );
    }
  }
}
