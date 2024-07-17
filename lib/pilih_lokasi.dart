import 'package:Sistem_Deteksi_Pengunjung_Wisata/detekti.dart';
import 'package:Sistem_Deteksi_Pengunjung_Wisata/video.dart';
import 'package:flutter/material.dart';

class ButtonPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pilih Lokasi"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildButton(context, "Rita", "Rita"),
            SizedBox(height: 16.0),
            buildButton(context, "Pasifik", "Pasifik"),
            SizedBox(height: 16.0),
            buildButton(context, "Waterpark", "Waterpark"),
          ],
        ),
      ),
    );
  }

  Widget buildButton(BuildContext context, String title, String pilih_lokasi) {
    return SizedBox(
      width: double.infinity,
      height: 50.0,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue, // Background color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0), // Rounded corners
          ),
        ),
        onPressed: () {
              Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => YoloVideo(data: pilih_lokasi),

              ),
            );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$title button pressed"),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
