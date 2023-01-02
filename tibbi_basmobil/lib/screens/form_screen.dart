import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';

import 'hasta_screen.dart';

Future<UserRequest> saveForm(
    DateTime baslangic,
    DateTime bitis,
    double siddet,
    int bolge,
    String ilac,
    String belirti,
    String detay,
    String token,
    BuildContext ctx) async {
  final response =
      await http.post(Uri.parse("http://192.168.1.32:5000/saveForm"),
          headers: {
            'Content-type': 'application/json',
            'Accept': 'application/json',
            'x-access-token': token
          },
          body: jsonEncode(<String, String>{
            'baslangic': baslangic.toString(),
            'bitis': bitis.toString(),
            'siddet': siddet.toString(),
            'bolge': bolge.toString(),
            'ilac': ilac,
            'belirti': belirti,
            'detay': detay,
          }));

  if (response.statusCode == 200) {
    Fluttertoast.showToast(
        msg: "Baş ağrısı bildiriminiz başarıyla gönderildi.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0);

    Navigator.pushAndRemoveUntil(
      ctx,
      MaterialPageRoute(builder: (ctx) => const HastaScreen()),
      (Route<dynamic> route) => false,
    );

    return const UserRequest(message: 'Başarılı İşlem', status: 200);
  } else if (response.statusCode == 401) {
    Fluttertoast.showToast(
        msg: "Hata! Bilinmeyen bir hata oluştu.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
    return const UserRequest(message: 'Error', status: 400);
  } else {
    Fluttertoast.showToast(
        msg: "Hata! Lütfen değerleri doldurduğunuzdan emin olun.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
    return const UserRequest(message: 'Error', status: 400);
  }
}

class UserRequest {
  final String message;
  final int status;

  const UserRequest({required this.message, required this.status});

  factory UserRequest.fromJson(Map<String, dynamic> json) {
    return UserRequest(
      message: json['message'],
      status: json['status'],
    );
  }
}

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => FormEkranState();
}

enum BasAgrisiBolgesi {
  onSag,
  onSol,
  arkaSol,
  arkaSag,
  ustArka,
  ustOn,
  yanArka,
  yanOn
}

class FormEkranState extends State<FormScreen> {
  late Map<String, dynamic> payload;
  late FlutterSecureStorage storage;
  late String token;

  DateTime _date_baslangic = DateTime(2023);
  DateTime _date_bitis = DateTime(2023);
  double _siddetSlider = 5;
  BasAgrisiBolgesi? _basAgrisiBolgesi = BasAgrisiBolgesi.onSag;
  final ilacController = TextEditingController();
  final belirtiController = TextEditingController();
  final detayController = TextEditingController();

  Future _readToken() async {
    token = await storage.read(key: "KEY") as String;
    payload = Jwt.parseJwt(token);
  }

  void getTimeText() {
    String gun = " ";
    if (DateTime.now().hour > 6 && DateTime.now().hour < 12) {
      gun = "Günaydın, ";
    } else if (DateTime.now().hour < 19) {
      gun = "İyi Günler, ";
    } else {
      gun = "İyi Geceler, ";
    }
  }

  @override
  void initState() {
    super.initState();
    storage = const FlutterSecureStorage();
    payload = {
      "id": 0,
      "username": "",
      "email": "",
      "type": 0,
      "exp": 0
    }; // dummy data for escaping from exception
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readToken();
    });
  }

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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 60, left: 30),
                child: const Text(
                  "Bildirim Formu",
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 10, left: 30, bottom: 40),
                child: const Text(
                  'Baş Ağrısı Bildirimi Yap',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 30, bottom: 30),
                child: const Text(
                  'Başlangıç ve Bitiş Tarihi Seçiniz',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              InkWell(
                child: Container(
                  decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset:
                              const Offset(0, 3), // changes position of shadow
                        )
                      ],
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(25)),
                  margin:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  height: 50,
                  width: double.infinity,
                  child: Container(
                    margin: const EdgeInsets.only(top: 15, left: 15),
                    child: Text("Başlangıç:    $_date_baslangic"),
                  ),
                ),
                onTap: () {
                  DatePicker.showDateTimePicker(context,
                      showTitleActions: true,
                      minTime:
                          DateTime.now().subtract(const Duration(days: 90)),
                      maxTime: DateTime.now(), onConfirm: (date) {
                    setState(() {
                      _date_baslangic = date;
                    });
                  }, locale: LocaleType.tr);
                },
              ),
              InkWell(
                child: Container(
                  decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset:
                              const Offset(0, 3), // changes position of shadow
                        )
                      ],
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(25)),
                  margin:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  height: 50,
                  width: double.infinity,
                  child: Container(
                    margin: const EdgeInsets.only(top: 15, left: 15),
                    child: Text("Bitis:             $_date_bitis"),
                  ),
                ),
                onTap: () {
                  DatePicker.showDateTimePicker(context,
                      showTitleActions: true,
                      minTime:
                          DateTime.now().subtract(const Duration(days: 90)),
                      maxTime: DateTime.now(), onConfirm: (date) {
                    setState(() {
                      _date_bitis = date;
                    });
                  }, locale: LocaleType.tr);
                },
              ),
              Container(
                margin: const EdgeInsets.only(left: 30, top: 20, bottom: 10),
                child: const Text(
                  'Şiddetini 0/10 Arası Seçiniz',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Slider(
                value: _siddetSlider,
                max: 10,
                divisions: 10,
                label: _siddetSlider.round().toString(),
                activeColor: const Color.fromARGB(252, 0, 208, 255),
                onChanged: (double value) {
                  setState(() {
                    _siddetSlider = value;
                  });
                },
              ),
              Container(
                margin: const EdgeInsets.only(left: 30, bottom: 20, top: 20),
                child: const Text(
                  'Ağrı Bölgesini Seçiniz',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 10, left: 20),
                      width: 300,
                      height: 300,
                      child: Image.asset('assets/kafalar_son.png'),
                    ),
                    SizedBox(
                      width: 220,
                      child: Column(
                        children: [
                          ListTile(
                            visualDensity: const VisualDensity(
                              horizontal: VisualDensity.minimumDensity,
                              vertical: VisualDensity.minimumDensity,
                            ),
                            title: const Text('1) Ön Sag'),
                            leading: Radio<BasAgrisiBolgesi>(
                              value: BasAgrisiBolgesi.onSag,
                              groupValue: _basAgrisiBolgesi,
                              activeColor:
                                  const Color.fromARGB(252, 0, 208, 255),
                              onChanged: (BasAgrisiBolgesi? value) {
                                setState(() {
                                  _basAgrisiBolgesi = value;
                                });
                              },
                            ),
                          ),
                          ListTile(
                            visualDensity: const VisualDensity(
                              horizontal: VisualDensity.minimumDensity,
                              vertical: VisualDensity.minimumDensity,
                            ),
                            title: const Text('2) Ön Sol'),
                            leading: Radio<BasAgrisiBolgesi>(
                              value: BasAgrisiBolgesi.onSol,
                              groupValue: _basAgrisiBolgesi,
                              activeColor:
                                  const Color.fromARGB(252, 0, 208, 255),
                              onChanged: (BasAgrisiBolgesi? value) {
                                setState(() {
                                  _basAgrisiBolgesi = value;
                                });
                              },
                            ),
                          ),
                          ListTile(
                            visualDensity: const VisualDensity(
                              horizontal: VisualDensity.minimumDensity,
                              vertical: VisualDensity.minimumDensity,
                            ),
                            title: const Text('3) Arka Sol'),
                            leading: Radio<BasAgrisiBolgesi>(
                              value: BasAgrisiBolgesi.arkaSol,
                              groupValue: _basAgrisiBolgesi,
                              activeColor:
                                  const Color.fromARGB(252, 0, 208, 255),
                              onChanged: (BasAgrisiBolgesi? value) {
                                setState(() {
                                  _basAgrisiBolgesi = value;
                                });
                              },
                            ),
                          ),
                          ListTile(
                            visualDensity: const VisualDensity(
                              horizontal: VisualDensity.minimumDensity,
                              vertical: VisualDensity.minimumDensity,
                            ),
                            title: const Text('4) Arka Sağ'),
                            leading: Radio<BasAgrisiBolgesi>(
                              value: BasAgrisiBolgesi.arkaSag,
                              groupValue: _basAgrisiBolgesi,
                              activeColor:
                                  const Color.fromARGB(252, 0, 208, 255),
                              onChanged: (BasAgrisiBolgesi? value) {
                                setState(() {
                                  _basAgrisiBolgesi = value;
                                });
                              },
                            ),
                          ),
                          ListTile(
                            visualDensity: const VisualDensity(
                              horizontal: VisualDensity.minimumDensity,
                              vertical: VisualDensity.minimumDensity,
                            ),
                            title: const Text('5) Üst Arka'),
                            leading: Radio<BasAgrisiBolgesi>(
                              value: BasAgrisiBolgesi.ustArka,
                              groupValue: _basAgrisiBolgesi,
                              activeColor:
                                  const Color.fromARGB(252, 0, 208, 255),
                              onChanged: (BasAgrisiBolgesi? value) {
                                setState(() {
                                  _basAgrisiBolgesi = value;
                                });
                              },
                            ),
                          ),
                          ListTile(
                            visualDensity: const VisualDensity(
                              horizontal: VisualDensity.minimumDensity,
                              vertical: VisualDensity.minimumDensity,
                            ),
                            title: const Text('6) Üst Ön'),
                            leading: Radio<BasAgrisiBolgesi>(
                              value: BasAgrisiBolgesi.ustOn,
                              groupValue: _basAgrisiBolgesi,
                              activeColor:
                                  const Color.fromARGB(252, 0, 208, 255),
                              onChanged: (BasAgrisiBolgesi? value) {
                                setState(() {
                                  _basAgrisiBolgesi = value;
                                });
                              },
                            ),
                          ),
                          ListTile(
                            visualDensity: const VisualDensity(
                              horizontal: VisualDensity.minimumDensity,
                              vertical: VisualDensity.minimumDensity,
                            ),
                            title: const Text('7) Yan Arka'),
                            leading: Radio<BasAgrisiBolgesi>(
                              value: BasAgrisiBolgesi.yanArka,
                              groupValue: _basAgrisiBolgesi,
                              activeColor:
                                  const Color.fromARGB(252, 0, 208, 255),
                              onChanged: (BasAgrisiBolgesi? value) {
                                setState(() {
                                  _basAgrisiBolgesi = value;
                                });
                              },
                            ),
                          ),
                          ListTile(
                            visualDensity: const VisualDensity(
                              horizontal: VisualDensity.minimumDensity,
                              vertical: VisualDensity.minimumDensity,
                            ),
                            title: const Text('8) Yan Ön'),
                            leading: Radio<BasAgrisiBolgesi>(
                              value: BasAgrisiBolgesi.yanOn,
                              groupValue: _basAgrisiBolgesi,
                              activeColor:
                                  const Color.fromARGB(252, 0, 208, 255),
                              onChanged: (BasAgrisiBolgesi? value) {
                                setState(() {
                                  _basAgrisiBolgesi = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 30, bottom: 20, top: 20),
                child: const Text(
                  'Bu süreçte ilaç kullandıysanız girin, veya boş bırakın.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Container(
                  margin:
                      const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: Material(
                      elevation: 2.0,
                      borderRadius: BorderRadius.circular(25.0),
                      child: TextFormField(
                        controller: ilacController,
                        decoration: InputDecoration(
                            hintStyle: const TextStyle(color: Colors.black),
                            filled: true,
                            fillColor: const Color.fromARGB(255, 255, 255, 255),
                            hintText: 'Kullanmadım, yok.',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0),
                            )),
                        validator: (String? value) {
                          return null;
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 30, bottom: 20, top: 20),
                child: const Text(
                  'Bu süreçte ortaya çıkan belirtileri (ateş, kusma vb.) girin, veya boş bırakın.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Container(
                  margin:
                      const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: Material(
                      elevation: 2.0,
                      borderRadius: BorderRadius.circular(25.0),
                      child: TextFormField(
                        controller: belirtiController,
                        decoration: InputDecoration(
                            hintStyle: const TextStyle(color: Colors.black),
                            filled: true,
                            fillColor: const Color.fromARGB(255, 255, 255, 255),
                            hintText: 'Belirti yok.',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0),
                            )),
                        validator: (String? value) {
                          return null;
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 30, bottom: 20, top: 20),
                child: const Text(
                  'Bildirim hakkında doktora iletmek istediğiniz detayları buraya girin, veya boş bırakın.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Container(
                  margin:
                      const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: Material(
                      elevation: 2.0,
                      borderRadius: BorderRadius.circular(25.0),
                      child: TextFormField(
                        controller: detayController,
                        decoration: InputDecoration(
                            hintStyle: const TextStyle(color: Colors.black),
                            filled: true,
                            fillColor: const Color.fromARGB(255, 255, 255, 255),
                            hintText: 'Detay ve notlar yok.',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0),
                            )),
                        validator: (String? value) {
                          return null;
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                  child: Container(
                margin: const EdgeInsets.only(bottom: 40, top: 10),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 104, 225, 253),
                      foregroundColor: const Color(0xFF000000),
                      fixedSize: const Size(350, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      )),
                  child: const Text(
                    'Gönder',
                    style: TextStyle(fontWeight: FontWeight.w400, fontSize: 17),
                  ),
                  onPressed: () => {
                    saveForm(
                        _date_baslangic,
                        _date_bitis,
                        _siddetSlider,
                        _basAgrisiBolgesi!.index,
                        ilacController.text,
                        belirtiController.text,
                        detayController.text,
                        token,
                        context)
                  },
                ),
              ))
            ],
          ),
        ),
      ),
    );
  }
}
