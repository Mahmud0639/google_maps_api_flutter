import 'package:flutter/cupertino.dart';
import 'package:google_maps_demo/models/address_model.dart';

class AppInfo extends ChangeNotifier{
  AddressModel? sourceLocation;
  AddressModel? destinationLocation;

  void updateSourceLocation(AddressModel source){
    sourceLocation = source;
    notifyListeners();
  }

  void updateDestinationLocation(AddressModel destination){
    destinationLocation = destination;
    notifyListeners();
  }

}