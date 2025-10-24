import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_demo/app_info/app_info.dart';
import 'package:google_maps_demo/widgets/predicted_place_ui.dart';
import 'package:provider/provider.dart';

import '../global/global_var.dart';
import '../methods/common_methods.dart';
import '../models/prediction_model.dart';

class SearchDestination extends StatefulWidget {
  const SearchDestination({super.key});

  @override
  State<SearchDestination> createState() => _SearchDestinationState();
}

class _SearchDestinationState extends State<SearchDestination> {
  TextEditingController pickupController = TextEditingController();
  TextEditingController destinationController = TextEditingController();

  List<PredictionModel> destinationPredictionList = [];

  //https://developers.google.com/maps/documentation/places/web-service/legacy/autocomplete
  ///auto complete places api
  searchLocation(String myLocation) async {
    if (myLocation.length > 1) {
      String apiPlacesUrl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$myLocation&key=$mapKey&components=country:bd";
      var responseAutoCompleteApi = await CommonMethods.sendRequestToApi(
        apiPlacesUrl,
      );

      if (responseAutoCompleteApi == "error") {
        return;
      } else {
        if (responseAutoCompleteApi["status"] == "OK") {
          var predictionResults = responseAutoCompleteApi["predictions"];
          //if we need to add many same format of map type data in the list, at first we need to make it fromJson() type then each element should be then toList()
          var predictionList = (predictionResults as List)
              .map(
                (eachElementJson) => PredictionModel.fromJson(eachElementJson),
              )
              .toList();
          setState(() {
            destinationPredictionList = predictionList;
          });

          print(predictionResults);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String humanReadableAddress =
        Provider.of<AppInfo>(
          context,
          listen: false,
        ).sourceLocation!.humanReadableAddress ??
        "";
    pickupController.text = humanReadableAddress;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              elevation: 10,
              child: Container(
                height: 240.h,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 24.w,
                    right: 24.w,
                    top: 48.h,
                    bottom: 20.h,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 6.h),
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          Center(
                            child: Text(
                              "Set drop off Location",
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 18.h),
                      Row(
                        children: [
                          Image.asset(
                            "assets/images/initial.png",
                            width: 16.w,
                            height: 16.h,
                          ),
                          SizedBox(width: 18.w),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(5.w),
                              ),

                              child: Padding(
                                padding: EdgeInsets.all(3.w),
                                child: TextField(
                                  controller: pickupController,
                                  decoration: InputDecoration(
                                    hintText: "Pickup Address",
                                    fillColor: Colors.white12,
                                    filled: true,
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 10.h),

                      Row(
                        children: [
                          Image.asset(
                            "assets/images/final.png",
                            width: 16.w,
                            height: 16.h,
                          ),
                          SizedBox(width: 18.w),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(5.w),
                              ),

                              child: Padding(
                                padding: EdgeInsets.all(3.w),
                                child: TextField(
                                  cursorColor: Colors.black45,
                                  controller: destinationController,
                                  onChanged: (inputData) {
                                    searchLocation(inputData);
                                  },
                                  decoration: InputDecoration(
                                    hintText: "DropOff Address",
                                    fillColor: Colors.white12,
                                    filled: true,
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            (destinationPredictionList.length > 0)
                ? Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.all(0),
                      shrinkWrap: true,
                      physics: ClampingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 8,
                          child: PredictedPlaceUi(
                            predictionModel: destinationPredictionList[index],
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          SizedBox(height: 3.h),
                      itemCount: destinationPredictionList.length,
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
