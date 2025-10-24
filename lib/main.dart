import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_demo/app_info/app_info.dart';
import 'package:google_maps_demo/firebase_options.dart';
import 'package:google_maps_demo/pages/home_page.dart';
import 'package:google_maps_demo/pages/search_destination.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

Future<void> main() async{
WidgetsFlutterBinding.ensureInitialized();
  //code for permission of location
  await Permission.locationWhenInUse.isDenied.then((isDenied){
    if(isDenied){
      Permission.locationWhenInUse.request();
    }
  });



  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(360, 800),
      builder:(context,child)=>ChangeNotifierProvider(
        create: (context)=>AppInfo(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flutter Demo',
          theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black,textSelectionTheme: const TextSelectionThemeData(
            cursorColor: Colors.black45,          // কার্সরের রঙ
            selectionColor: Colors.black45, // নির্বাচিত টেক্সটের ব্যাকগ্রাউন্ড
            selectionHandleColor: Colors.black45, // <-- এইটাই “গোল হ্যান্ডেল” এর রঙ
          ),),

          home: const HomePage(),
        ),
      ) ,
    );
  }
}
