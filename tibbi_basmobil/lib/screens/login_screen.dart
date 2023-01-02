import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:tibbi_basmobil/screens/register_screen.dart';
import 'package:http/http.dart' as http;
import 'doktor_screen.dart';
import 'hasta_screen.dart';

Future<UserRequest> loginUser(
    String user, String pass, BuildContext ctx) async {
  final response = await http.post(Uri.parse("http://192.168.1.32:5000/login"),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json'
      },
      body: jsonEncode(<String, String>{
        'username': user,
        'password': pass,
      }));

  if (response.statusCode == 200) {
    Fluttertoast.showToast(
        msg: "Giriş Başarılı, yönlendiriliyor.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0);

    final responseJson = jsonDecode(response.body);
    final currResponse = UserRequest.fromJson(responseJson);

    const storage = FlutterSecureStorage();
    await storage.write(key: "KEY", value: currResponse.token);
    var payload = Jwt.parseJwt(currResponse.token);

    if (payload["type"] == 0) {
      // TODO: async uygulamalar :( [contexti burada patlatabilir, dikkat...] -ama calisir herhal?-
      Navigator.pushAndRemoveUntil(
        ctx,
        MaterialPageRoute(builder: (ctx) => const HastaScreen()),
        (Route<dynamic> route) => false,
      );
    } else {
      // TODO: async uygulamalar :( [contexti burada patlatabilir, dikkat...] -ama calisir herhal?-
      Navigator.pushAndRemoveUntil(
        ctx,
        MaterialPageRoute(builder: (ctx) => const DoktorScreen()),
        (Route<dynamic> route) => false,
      );
    }

    return currResponse;
  } else if (response.statusCode == 401) {
    Fluttertoast.showToast(
        msg: "Hata! Kullanıcı adı veya parolanız yanlış.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
    return const UserRequest(message: 'Error', status: 400, token: '');
  } else {
    Fluttertoast.showToast(
        msg: "Hata! Lütfen değerleri doldurduğunuzdan emin olun.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
    return const UserRequest(message: 'Error', status: 400, token: '');
  }
}

class UserRequest {
  final String message;
  final int status;
  final String token;

  const UserRequest(
      {required this.message, required this.status, required this.token});

  factory UserRequest.fromJson(Map<String, dynamic> json) {
    return UserRequest(
      message: json['message'],
      status: json['status'],
      token: json['token'],
    );
  }
}

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 8, 113, 112),
                Color.fromARGB(255, 12, 145, 136),
                Color.fromARGB(255, 23, 188, 171),
                Color.fromARGB(255, 27, 232, 201),
                Color.fromARGB(255, 36, 253, 213),
              ],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              stops: [0.0, 0.25, 0.5, 0.75, 1.0],
              tileMode: TileMode.clamp),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 40),
              child: const Text(
                'Mobil Baş Ağrısı \nTakip Uygulaması',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 30),
              width: 360,
              height: 360,
              child: SvgPicture.asset('assets/doctor.svg'),
            ),
            Container(
              margin: const EdgeInsets.only(top: 40),
              child: SizedBox(
                width: 420,
                child: Material(
                  elevation: 10.0,
                  borderRadius: BorderRadius.circular(22.0),
                  child: TextFormField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      hintStyle: const TextStyle(color: Colors.black),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 255, 255, 255),
                      hintText: 'Kullanıcı Adı',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22.0),
                      ),
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Kullanıcı adı boş bırakılamaz';
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 30),
              child: SizedBox(
                width: 420,
                child: Material(
                  elevation: 10.0,
                  borderRadius: BorderRadius.circular(22.0),
                  child: TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                        hintStyle: const TextStyle(color: Colors.black),
                        filled: true,
                        fillColor: const Color.fromARGB(255, 255, 255, 255),
                        hintText: 'Şifre',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22.0),
                        )),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Kullanıcı adı boş bırakılamaz';
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 40),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 104, 225, 253),
                    foregroundColor: const Color(0xFF000000),
                    fixedSize: const Size(350, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    )),
                child: const Text(
                  'Giriş Yap',
                  style: TextStyle(fontWeight: FontWeight.w400, fontSize: 17),
                ),
                onPressed: () => {
                  loginUser(
                      usernameController.text, passwordController.text, context)
                },
              ),
            ),
            TextButton(
                onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterScreen()),
                    ),
                child: const Text(
                  "Hesabın yok mu? Kayıt ol.",
                  style: TextStyle(color: Colors.white),
                )),
          ],
        ),
      ),
    );
  }
}
