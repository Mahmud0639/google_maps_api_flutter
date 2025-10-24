import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_demo/app_info/app_info.dart';
import 'package:google_maps_demo/global/global_var.dart';
import 'package:google_maps_demo/methods/common_methods.dart';
import 'package:google_maps_demo/models/address_model.dart';
import 'package:google_maps_demo/models/prediction_model.dart';
import 'package:google_maps_demo/widgets/loading_dialog.dart';
import 'package:provider/provider.dart';

class PredictedPlaceUi extends StatefulWidget {
  PredictionModel? predictionModel;

   PredictedPlaceUi({super.key,this.predictionModel});

  @override
  State<PredictedPlaceUi> createState() => _PredictedPlaceUiState();
}

class _PredictedPlaceUiState extends State<PredictedPlaceUi> {


  ///places details - to get clicked place latitude and longitude value for the further use like polyline drawing
  fetchClickedPlaceDetails(String placeID)async{

    showDialog(context: context, barrierDismissible: false,builder: (BuildContext context)=>LoadingDialog(messageText: "Getting details..."));

    String placesDetailsUrl = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeID&key=$mapKey";

    var responseFromPlaceDetails = await CommonMethods.sendRequestToApi(placesDetailsUrl);

    Navigator.pop(context);

    if(responseFromPlaceDetails == "error"){
      return;
    }

    if(responseFromPlaceDetails["status"]=="OK"){

      AddressModel addressModel = AddressModel();

     addressModel.placeName = responseFromPlaceDetails["result"]["name"];
     addressModel.latitudePosition = responseFromPlaceDetails["result"]["geometry"]["location"]["lat"];
     addressModel.longitudePosition = responseFromPlaceDetails["result"]["geometry"]["location"]["lng"];
     addressModel.placeID = placeID;

     Provider.of<AppInfo>(context,listen: false).updateDestinationLocation(addressModel);

     //after updating data into the provider state we can now go back to our homepage
      Navigator.pop(context,"placeSelected");
    }

  }


  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: (){
          fetchClickedPlaceDetails(widget.predictionModel!.place_id.toString());
    }, style: ElevatedButton.styleFrom(backgroundColor: Colors.white,shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),child: Container(
      child: Column(
        children: [
          SizedBox(height: 8.h,),
          Row(children: [
            const Icon(Icons.share_location,color: Colors.grey,),
            SizedBox(
              width: 13.w,
            ),
            Expanded(child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(widget.predictionModel!.main_text.toString(),overflow: TextOverflow.ellipsis,maxLines: 2,style: TextStyle(fontSize: 16.sp,color: Colors.black87),),
                SizedBox(
                  height: 3.h,
                ),
                Text(widget.predictionModel!.secondary_text.toString(),overflow: TextOverflow.ellipsis,maxLines: 2,style: TextStyle(fontSize: 12.sp,color: Colors.black54),)
              ],
            ))
          ], ),
          SizedBox(height: 10.h,),

        ],
      ),
    ));
  }
}
