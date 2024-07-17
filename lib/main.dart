import 'package:Sistem_Deteksi_Pengunjung_Wisata/screens/welcome_screen.dart';
import 'package:Sistem_Deteksi_Pengunjung_Wisata/state_util.dart';
import 'package:Sistem_Deteksi_Pengunjung_Wisata/core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure Flutter bindings are initialized
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login App',
      navigatorKey: Get.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: kBackgroundColor,
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: kPrimaryColor,
              fontFamily: 'Montserrat',
            ),
      ),
      home: const WelcomeScreen(),
    );
  }
}
