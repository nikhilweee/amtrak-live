import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models.dart';

class MapWidget extends StatefulWidget {
  final TrainLocation trainLocation;

  const MapWidget({super.key, required this.trainLocation});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _createMarkers();
    _createPolylines();
  }

  @override
  void didUpdateWidget(MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update markers and polylines if the train location has changed
    if (oldWidget.trainLocation.lat != widget.trainLocation.lat ||
        oldWidget.trainLocation.long != widget.trainLocation.long ||
        oldWidget.trainLocation.speed != widget.trainLocation.speed ||
        oldWidget.trainLocation.heading != widget.trainLocation.heading) {
      _createMarkers();
      _createPolylines();

      // Update camera position to new train location
      _controller?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(widget.trainLocation.lat, widget.trainLocation.long),
        ),
      );
    }
  }

  void _createMarkers() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('train'),
          position: LatLng(widget.trainLocation.lat, widget.trainLocation.long),
          infoWindow: InfoWindow(
            title: 'Train Location',
            snippet:
                'Heading ${widget.trainLocation.heading} at '
                '${widget.trainLocation.speed.toStringAsFixed(0)} mph',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      };
    });
  }

  void _createPolylines() {
    setState(() {
      if (widget.trainLocation.routeCoordinates != null &&
          widget.trainLocation.routeCoordinates!.isNotEmpty) {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: widget.trainLocation.routeCoordinates!,
            color: Colors.blue,
            width: 3,
            patterns: [],
          ),
        };
      } else {
        _polylines = {};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _controller = controller;
        },
        initialCameraPosition: CameraPosition(
          target: LatLng(widget.trainLocation.lat, widget.trainLocation.long),
          zoom: 8.0,
        ),
        markers: _markers,
        polylines: _polylines,
        mapType: MapType.normal,
        zoomGesturesEnabled: true,
        scrollGesturesEnabled: true,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        compassEnabled: false,
        zoomControlsEnabled: false,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
