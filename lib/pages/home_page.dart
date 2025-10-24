import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_demo/app_info/app_info.dart';
import 'package:google_maps_demo/global/global_var.dart';
import 'package:google_maps_demo/methods/common_methods.dart';
import 'package:google_maps_demo/models/address_model.dart';
import 'package:google_maps_demo/models/direction_details.dart';
import 'package:google_maps_demo/pages/search_destination.dart';
import 'package:google_maps_demo/widgets/loading_dialog.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double rideDetailsContainerHeight = 0;
  double searchContainerHeight = 0;
  DirectionDetails? directionDetails;
  List<LatLng> polyLineCoordinates = [];
  Set<Polyline> polyLineSet = {};
  Set<Marker> markerSet = {};
  Set<Circle> circleSet = {};
  Position? currentPositionOfUser;
  String placeName = "";
  bool isSetCurrentLocation = false;


  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;

  displayUserRideDetailsContainer()async{
    await retrieveDirectionDetails();
    setState(() {
      searchContainerHeight = 0;
      rideDetailsContainerHeight = 342.h;
    });

  }

  retrieveDirectionDetails() async {


    var sourceLocation = Provider.of<AppInfo>(context,listen: false).sourceLocation;
    var destinationLocation = Provider.of<AppInfo>(context, listen: false).destinationLocation;

    var sourceGeographicCoordinates = LatLng(sourceLocation!.latitudePosition!, sourceLocation.longitudePosition!);
    var destinationGeographicCoordinates = LatLng(destinationLocation!.latitudePosition!, destinationLocation.longitudePosition!);

    showDialog(
      context: context,
      builder: (BuildContext context) =>
          LoadingDialog(messageText: "Getting directions..."),
    );

    var resultOfDirections = await CommonMethods.getDirectionsDetails(sourceGeographicCoordinates,destinationGeographicCoordinates);


    setState(() {
      directionDetails = resultOfDirections;
    });
    Navigator.pop(context);
    drawPolyline(sourceGeographicCoordinates,destinationGeographicCoordinates,sourceLocation,destinationLocation);
  }



  drawPolyline(LatLng sourceGeoCoordinates, LatLng destinationGeoCoordinates,AddressModel sourceLocation, AddressModel destinationLocation) {
    PolylinePoints pointsPolyLines = PolylinePoints();
    List<PointLatLng> latLngPoints = pointsPolyLines.decodePolyline(
      directionDetails!.encodedPoints!,
    );
    //now we need a forEach loop
    polyLineCoordinates.clear();

    if (latLngPoints.isNotEmpty) {
      latLngPoints.forEach((PointLatLng pointLatLng) {
        polyLineCoordinates.add(
          LatLng(pointLatLng.latitude, pointLatLng.longitude),
        );
      });
    }

    polyLineSet.clear();
    setState(() {
      Polyline polyline = Polyline(
        polylineId: PolylineId("polylineID"),
        color: Colors.pink,
        points: polyLineCoordinates,
        jointType: JointType.round,
        width: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );
      polyLineSet.add(polyline);
    });

    //fit the polyline into the map
    LatLngBounds latLngBounds;

    if(sourceGeoCoordinates.latitude > destinationGeoCoordinates.latitude && sourceGeoCoordinates.longitude > destinationGeoCoordinates.longitude){
      latLngBounds = LatLngBounds(southwest: destinationGeoCoordinates, northeast: sourceGeoCoordinates);
    }else if(sourceGeoCoordinates.longitude > destinationGeoCoordinates.longitude){
      latLngBounds = LatLngBounds(southwest: LatLng(sourceGeoCoordinates.latitude, destinationGeoCoordinates.longitude), northeast: LatLng(destinationGeoCoordinates.latitude, sourceGeoCoordinates.longitude));
    }else if(sourceGeoCoordinates.latitude > destinationGeoCoordinates.latitude){
      latLngBounds = LatLngBounds(southwest: LatLng(destinationGeoCoordinates.latitude, sourceGeoCoordinates.longitude), northeast: LatLng(sourceGeoCoordinates.latitude, destinationGeoCoordinates.longitude));
    }else{
      latLngBounds = LatLngBounds(southwest: sourceGeoCoordinates, northeast: destinationGeoCoordinates);
    }

    controllerGoogleMap!.animateCamera(
      CameraUpdate.newLatLngBounds(latLngBounds, 72),
    );

    //adding marker to the source and destination point
    Marker sourcePointMarker = Marker(
      markerId: const MarkerId("sourcePointMarkerID"),
      position: sourceGeoCoordinates,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(
        title: sourceLocation.placeName,
        snippet: "Source Location",
      ),
    );

    Marker destinationPointMarker = Marker(
      markerId: const MarkerId("destinationPointMarkerID"),
      position: destinationGeoCoordinates,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      infoWindow: InfoWindow(
        title: destinationLocation.placeName,
        snippet: "Destination Location",
      ),
    );

    setState(() {
      markerSet.add(sourcePointMarker);
      markerSet.add(destinationPointMarker);
    });

    //adding circle to source and destination points
    Circle sourcePointCircle = Circle(
      circleId: const CircleId("sourcePointCircleID"),
      strokeColor: Colors.blue,
      strokeWidth: 4,
      radius: 14,
      center: sourceGeoCoordinates,
      fillColor: Colors.pink,
    );

    Circle destinationPointCircle = Circle(
      circleId: const CircleId("destinationPointCircleID"),
      strokeColor: Colors.blue,
      strokeWidth: 4,
      radius: 14,
      center: destinationGeoCoordinates,
      fillColor: Colors.pink,
    );

    setState(() {
      circleSet.add(sourcePointCircle);
      circleSet.add(destinationPointCircle);
    });
  }

  //we can also do like this way
  Future<String> getMapStyle(String path) async {
    return await rootBundle.loadString(path);
  }

  String? _mapStyle;

  //and then just use the _mapStyle
  //
  // @override
  // void initState() {
  //   super.initState();
  //
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     retrieveDirectionDetails();
  //   });
  // }

  void changeGoogleMapTheme(GoogleMapController controller) {
    getJsonFileFromThemesDir(
      "themes/night_style.json",
    ).then((value) => setGoogleMapStyle(value, controller));
  }

  Future<String> getJsonFileFromThemesDir(String path) async {
    ByteData byteData = await rootBundle.load(path);
    var list = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
    return utf8.decode(list);
  }

  setGoogleMapStyle(String googleMapStyle, GoogleMapController controller) {
    controller.setMapStyle(googleMapStyle);
  }

  @override
  Widget build(BuildContext context) {
    ///get current location
    getCurrentLocation() async {

      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      currentPositionOfUser = currentPosition;

      LatLng userCurrentLatLng = LatLng(
        currentPositionOfUser!.latitude,
        currentPositionOfUser!.longitude,
      );

      CameraPosition cameraPosition = CameraPosition(
        target: userCurrentLatLng,
        zoom: 15,
      );
      controllerGoogleMap!.animateCamera(
        CameraUpdate.newCameraPosition(cameraPosition),
      );

      await CommonMethods.getUserAddressFromCoordinates(
        currentPositionOfUser!,
        context,
      );

      setState(() {
        searchContainerHeight = 276.h;
        isSetCurrentLocation = true;
      });

    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            padding: rideDetailsContainerHeight == 342.h
                ? EdgeInsets.only(bottom: 340.h, top: 30.h)
                : EdgeInsets.only(bottom: 0, top: 30.h),
            initialCameraPosition: googlePlex,
            mapType: MapType.normal,
            myLocationEnabled: true,
            markers: markerSet,
            circles: circleSet,
            polylines: polyLineSet,
            onMapCreated: (GoogleMapController mapController) {
              controllerGoogleMap = mapController;
              //if we use style then no need to use the below way
              changeGoogleMapTheme(controllerGoogleMap!);

              googleMapCompleterController.complete(controllerGoogleMap);
              getCurrentLocation();
            },
            // style: _mapStyle,
          ),



          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: rideDetailsContainerHeight,
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15.0),
                  topRight: Radius.circular(15.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white12,
                    blurRadius: 15.0,
                    spreadRadius: 0.5,
                    offset: Offset(0.7, 0.7),
                  ),
                ],
              ),

              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 18.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 16.w, right: 16.w),
                      child: SizedBox(
                        height: 230.h,
                        child: Card(
                          elevation: 10.0,
                          child: Container(
                            width: MediaQuery.of(context).size.width * .70,

                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: 8.w,
                                      right: 8.w,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          (directionDetails != null)
                                              ? directionDetails!.distanceText!
                                              : "0 km",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white70,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          (directionDetails != null)
                                              ? directionDetails!.durationText!
                                              : "0 min",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white70,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  GestureDetector(
                                    onTap: () {

                                        setState(() {
                                          rideDetailsContainerHeight = 0;
                                          searchContainerHeight = 276.h;
                                        });
                                      //call method for polyline here
                                      //drawPolyline();

                                    },
                                    child: Image.asset(
                                      "assets/images/uberexec.png",
                                      width: 100.w,
                                      height: 100.h,
                                    ),
                                  ),
                                  
                                    Text(Provider.of<AppInfo>(context,listen: false).destinationLocation?.placeName.toString()??"")
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(left: 0,
              right: 0,
              bottom: -80.h,
              child: Container(
                height: searchContainerHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(onPressed: ()async{

                     var waitForInfo = await Navigator.push(context, MaterialPageRoute(builder: (c)=>SearchDestination()));
                     if(waitForInfo == "placeSelected"){
                        displayUserRideDetailsContainer();
                      


                     }
                    }, style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black12,
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(14)
                    ),child: Icon(Icons.search,size: 25.w,color: Colors.blue,))
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
