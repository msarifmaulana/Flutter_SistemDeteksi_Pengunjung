import 'package:Sistem_Deteksi_Pengunjung_Wisata/WebViewVideo.dart';
import 'package:Sistem_Deteksi_Pengunjung_Wisata/detekti.dart';
import 'package:Sistem_Deteksi_Pengunjung_Wisata/pilih_lokasi.dart';
import 'package:Sistem_Deteksi_Pengunjung_Wisata/pilih_lokasi_video.dart';
import 'package:Sistem_Deteksi_Pengunjung_Wisata/video.dart';
import 'package:Sistem_Deteksi_Pengunjung_Wisata/WebViewExample.dart';
import 'package:Sistem_Deteksi_Pengunjung_Wisata/profil.dart';
import 'package:Sistem_Deteksi_Pengunjung_Wisata/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Sistem Deteksi Pengunjung"),
        actions: [
          // InkWell(
          //   // onTap: () {
          //   //   // Navigator.of(context).push(
          //   //   //   MaterialPageRoute(builder: (context) => const LoginScreen()),
          //   //   // );
          //   // },
          //   child: Padding(
          //     padding: const EdgeInsets.all(8.0),
          //     child: Icon(
          //       Icons.exit_to_app,
          //       color: Colors.lightBlue[900], // Ganti warna sesuai kebutuhan
          //     ),
          //   ),
          // ),
          InkWell(
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) => Profil()));
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.person,
                color: Colors.lightBlue[900], // Ganti warna sesuai kebutuhan
              ),
            ),
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(25),
        crossAxisCount: 1, // Mengatur jumlah kolom menjadi 1
        childAspectRatio:
            3, // Mengatur aspect ratio untuk memperpanjang setiap item secara horizontal
        mainAxisSpacing: 20, // Menambahkan spasi antar baris
        children: <Widget>[
          Card(
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        ButtonPage())); // Navigate to HasilScreen
              },
              splashColor: Colors.blue,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const <Widget>[
                    Icon(Icons.search, size: 70, color: Colors.blueAccent),
                    Text("Deteksi", style: TextStyle(fontSize: 17.0)),
                  ],
                ),
              ),
            ),
          ),
          Card(
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        WebViewExample())); // Navigate to HasilScreen
              },
              splashColor: Colors.blue,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const <Widget>[
                    Icon(Icons.visibility, size: 70, color: Colors.greenAccent),
                    Text("Hasil", style: TextStyle(fontSize: 17.0)),
                  ],
                ),
              ),
            ),
          ),
          Card(
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        PilihLokasiVideo())); // Navigate to HasilScreen
              },
              splashColor: Colors.blue,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const <Widget>[
                    Icon(Icons.videocam, size: 70, color: Colors.redAccent),
                    Text("Deteksi Video", style: TextStyle(fontSize: 17.0)),
                  ],
                ),
              ),
            ),
          ),
          Card(
            child: InkWell(
              onTap: () {
                // Log out user
                _logout(context);
              },
              splashColor: Colors.blue,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const <Widget>[
                    Icon(Icons.logout, size: 70, color: Colors.redAccent),
                    Text("Log Out", style: TextStyle(fontSize: 17.0)),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _logout(BuildContext context) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final GoogleSignIn googleSignIn = GoogleSignIn();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('token_access');

    try {
      // Sign out from Firebase
      await _auth.signOut();

      // Sign out from Google
      await googleSignIn.signOut();

      String? accessToken = prefs.getString('token_access');
      if (accessToken != null) {
        final url = Uri.parse(
            'https://settled-previously-elephant.ngrok-free.app/logout');
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        };

        final response = await http.post(url, headers: headers);

        if (response.statusCode == 200) {
          // Clear local storage
          await prefs.remove('user_id');
          await prefs.remove('token_access');
          await prefs.remove('name');
          await prefs.remove('email');

          // Show sign out success snackbar
          _showSnackBar(context, 'Sign out successful', Colors.green);

          // Navigate to WelcomeScreen or any other desired screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => WelcomeScreen()),
          );
        } else {
          // Show server sign out error snackbar
          _showSnackBar(context, 'Failed to logout from server', Colors.red);
        }
      } else {
        // Clear local storage
        await prefs.remove('user_id');
        await prefs.remove('name');
        await prefs.remove('email');

        // Show sign out success snackbar
        _showSnackBar(context, 'Sign out successful', Colors.green);

        // Navigate to WelcomeScreen or any other desired screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => WelcomeScreen()),
        );
      }
    } catch (error) {
      // Show sign out error snackbar
      _showSnackBar(
          context, 'Error signing out. Please try again later.', Colors.red);
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
