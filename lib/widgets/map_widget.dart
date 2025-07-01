import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  void _createMarkers() {
    _markers = {
      Marker(
        markerId: const MarkerId('train'),
        position: LatLng(
          widget.trainLocation.lat,
          widget.trainLocation.long,
        ),
        infoWindow: InfoWindow(
          title: 'Train Location',
          snippet:
              'Heading ${widget.trainLocation.heading} at '
              '${widget.trainLocation.speed.toStringAsFixed(0)} mph',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
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
        mapType: MapType.normal,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
        compassEnabled: true,
        scrollGesturesEnabled: true,
        zoomGesturesEnabled: true,
        rotateGesturesEnabled: true,
        tiltGesturesEnabled: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
