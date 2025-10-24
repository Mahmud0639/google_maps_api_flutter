import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_demo/app_info/app_info.dart';
import 'package:google_maps_demo/global/global_var.dart';
import 'package:google_maps_demo/models/address_model.dart';
import 'package:google_maps_demo/models/direction_details.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class CommonMethods{
  static sendRequestToApi(String apiUrl)async{
    http.Response response = await http.get(Uri.parse(apiUrl));

    try{
      if(response.statusCode == 200){
        String dataFromApi = response.body;
        var dataDecoded = jsonDecode(dataFromApi);
        return dataDecoded;
      }else{
        return "error";
      }
    }catch(errorMsg){
      return "error";
    }

  }

  ///reverse geocoding(We need the formatted address)
  static Future<String> getUserAddressFromCoordinates(Position position,BuildContext context)async{

      String humanReadableAddress = "";

      String urlOfGeoCodingApi = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";
      var responseOfGeocode = await sendRequestToApi(urlOfGeoCodingApi);
      if(responseOfGeocode != "error"){
       humanReadableAddress = responseOfGeocode["results"][0]["formatted_address"];
       print("My Address: $humanReadableAddress");

       //pass data to the address model
        AddressModel addressModel = AddressModel();
        addressModel.humanReadableAddress = humanReadableAddress;
        addressModel.latitudePosition = position.latitude;
        addressModel.longitudePosition = position.longitude;
        
        Provider.of<AppInfo>(context,listen: false).updateSourceLocation(addressModel);
      }

      return humanReadableAddress;
  }



  ///places api - auto complete api








  ///Direction api
  static Future<DirectionDetails?> getDirectionsDetails(LatLng source, LatLng destination)async{
    String url = "https://maps.googleapis.com/maps/api/directions/json?destination=${destination.latitude},${destination.longitude}&origin=${source.latitude},${source.longitude}&mode=driving&key=$mapKey";
    var responseFromDirections = await sendRequestToApi(url);
    if(responseFromDirections == "error"){
      return null;
    }else{
      DirectionDetails directionDetails = DirectionDetails();
      directionDetails.distanceText = responseFromDirections["routes"][0]["legs"][0]["distance"]["text"];
      directionDetails.distanceValue = responseFromDirections["routes"][0]["legs"][0]["distance"]["value"];

      directionDetails.durationText = responseFromDirections["routes"][0]["legs"][0]["duration"]["text"];
      directionDetails.durationValue = responseFromDirections["routes"][0]["legs"][0]["duration"]["value"];

      directionDetails.encodedPoints = responseFromDirections["routes"][0]["overview_polyline"]["points"];

      return directionDetails;
    }
  }
}

