import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class Profil extends StatefulWidget {
  const Profil({Key? key}) : super(key: key);

  @override
  State<Profil> createState() => _ProfilState();
}

class _ProfilState extends State<Profil> {
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newpassword = TextEditingController();
  final TextEditingController _confirmpassword = TextEditingController();

  bool _isLoading = false;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    loadUserSession();
  }

  Future<void> loadUserSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullnameController.text = prefs.getString('name') ?? '';
      _emailController.text = prefs.getString('email') ?? '';
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('token_access');

    if (accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Access token not found. Please login again.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final url = Uri.parse(
        'https://settled-previously-elephant.ngrok-free.app/update_profile_picture');
    final headers = {
      'Content-Type': 'multipart/form-data',
      'Authorization': 'Bearer $accessToken',
    };

    var request = http.MultipartRequest('POST', url);
    request.headers.addAll(headers);
    request.files.add(await http.MultipartFile.fromPath('profile_picture', _imageFile!.path));

    setState(() {
      _isLoading = true;
    });

    final response = await request.send();

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile picture updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile picture'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  alignment: Alignment.center,
                  child: Text(
                    "Informasi Pengguna",
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 16.0),
                CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : AssetImage('assets/images/kucing.jpg') as ImageProvider,
                ),
                TextButton.icon(
                  icon: Icon(Icons.camera_alt),
                  label: Text("Ganti Foto Profil"),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  margin: EdgeInsets.only(top: 10),
                  child: Text(
                    "Nama Lengkap",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 5),
                  width: 500,
                  child: TextField(
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),
                      hintText: 'Nama Lengkap',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    controller: _fullnameController,
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Email",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 5),
                  width: 500,
                  child: TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),
                      hintText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    controller: _emailController,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 10),
                  width: 400,
                  height: 50,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Color.fromRGBO(17, 0, 158, 1),
                    ),
                    onPressed: () async {
                      String newFullName = _fullnameController.text;
                      String newEmail = _emailController.text;
                      await updateProfile(newFullName, newEmail);
                    },
                    child: Text(
                      "Simpan",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: Colors.grey[300],
                  margin: EdgeInsets.symmetric(vertical: 10),
                ),
                Container(
                  alignment: Alignment.center,
                  child: Text(
                    "Ubah Password",
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  margin: EdgeInsets.only(top: 10),
                  child: Text(
                    "Password Baru",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: _isLoading
                      ? Container(
                          key: ValueKey('loading'),
                          child: Center(
                            child: LoadingAnimationWidget.waveDots(
                              color: Colors.blue,
                              size: 100,
                            ),
                          ),
                        )
                      : Column(
                          key: ValueKey('form'),
                          children: [
                            Container(
                              margin: EdgeInsets.only(top: 5),
                              width: 400,
                              child: TextField(
                                obscureText: true,
                                obscuringCharacter: "*",
                                controller: _newpassword,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.all(10.0),
                                  hintText: 'Password Baru',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[300],
                                ),
                              ),
                            ),
                            Container(
                              alignment: Alignment.centerLeft,
                              margin: EdgeInsets.only(top: 10),
                              child: Text(
                                "Konfirmasi Password",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 5),
                              width: 400,
                              child: TextField(
                                obscureText: true,
                                obscuringCharacter: "*",
                                controller: _confirmpassword,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.all(10.0),
                                  hintText: 'Konfirmasi Password',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20.0)),
                                  filled: true,
                                  fillColor: Colors.grey[300],
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 10),
                              width: 400,
                              height: 50,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor:
                                      Color.fromRGBO(17, 0, 158, 1),
                                ),
                                onPressed: () async {
                                  String newPassword = _newpassword.text;
                                  String confirmPassword =
                                      _confirmpassword.text;
                                  await updatePassword(
                                      newPassword, confirmPassword);
                                },
                                child: Text(
                                  "Ubah Password",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: LoadingAnimationWidget.waveDots(
                  color: Colors.blue,
                  size: 100,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> updateProfile(String newName, String newEmail) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('token_access');

    if (accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Access token not found. Please login again.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final url = Uri.parse(
        'https://settled-previously-elephant.ngrok-free.app/update_profile');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
    final body = jsonEncode({'name': newName, 'email': newEmail});

    setState(() {
      _isLoading = true;
    });

    final response = await http.put(url, headers: headers, body: body);

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      // Profile updated successfully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Update local stored display name and email if necessary
      prefs.setString('name', newName);
      prefs.setString('email', newEmail);
    } else {
      // Failed to update profile
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> updatePassword(String newPassword, String confirmPassword) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('token_access');

    if (newPassword != confirmPassword) {
      _showAlertDialog(context, 'Peringatan',
          'Kata sandi baru dan konfirmasi kata sandi tidak cocok.');
      return;
    }

    if (accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Access token not found. Please login again.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final url = Uri.parse(
        'https://settled-previously-elephant.ngrok-free.app/update_password');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
    final body = jsonEncode({
      'password_baru': newPassword,
      'konfirmasi_password': confirmPassword,
    });

    setState(() {
      _isLoading = true;
    });

    final response = await http.put(url, headers: headers, body: body);

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Password updated successfully'),
        backgroundColor: Colors.green,
      ));
      _newpassword.clear();
      _confirmpassword.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update password'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _showAlertDialog(BuildContext context, String title, String content) {
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('OK'),
        ),
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
