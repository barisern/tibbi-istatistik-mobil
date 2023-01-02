import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';

import 'form_screen.dart';
import 'package:http/http.dart' as http;

List<BasAgrisi> sampleFromJson(String str) {
  final jsonData = json.decode(str);
  return new List<BasAgrisi>.from(jsonData.map((x) => BasAgrisi.fromJson(x)));
}

class BasAgrisi {
  final int id;
  final String baslangic;
  final String bitis;
  final String siddet;
  final String bolge;
  final String ilac;
  final String belirti;
  final String detay;
  final String username;

  const BasAgrisi({
    required this.id,
    required this.baslangic,
    required this.bitis,
    required this.siddet,
    required this.bolge,
    required this.ilac,
    required this.belirti,
    required this.detay,
    required this.username,
  });

  factory BasAgrisi.fromJson(Map<String, dynamic> json) {
    return BasAgrisi(
      id: json['id'],
      baslangic: json['baslangic'],
      bitis: json['bitis'],
      siddet: json['siddet'],
      bolge: json['bolge'],
      ilac: json['ilac'],
      belirti: json['belirti'],
      detay: json['detay'],
      username: json['username'],
    );
  }
}

Future<List<BasAgrisi>> fetchBasAgrisi(String token) async {
  final response = await http.get(Uri.parse('http://192.168.1.32:5000/getForm'),
      headers: {'x-access-token': token});

  if (response.statusCode == 200) {
    return sampleFromJson(response.body);
  } else {
    throw Exception('Failed to load album');
  }
}

class HastaScreen extends StatefulWidget {
  const HastaScreen({super.key});

  @override
  State<HastaScreen> createState() => _HastaEkranState();
}

class _HastaEkranState extends State<HastaScreen> {
  late Map<String, dynamic> payload;
  late FlutterSecureStorage storage;
  String token = "";
  Future<List<BasAgrisi>>? basAgrisiList;

  Future _readToken() async {
    token = await storage.read(key: "KEY") as String;
    payload = Jwt.parseJwt(token);
  }

  String getTimeText() {
    String gun = " ";
    if (DateTime.now().hour > 6 && DateTime.now().hour < 12) {
      gun = "Günaydın, ";
    } else if (DateTime.now().hour < 19) {
      gun = "İyi Günler, ";
    } else {
      gun = "İyi Geceler, ";
    }
    return gun + payload["username"];
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 60, left: 30),
              child: Text(
                getTimeText(),
                style:
                    const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
              ),
            ),
            InkWell(
              child: Container(
                margin: const EdgeInsets.only(top: 20, left: 30, bottom: 30),
                child: const Text(
                  'Son 5 Baş Ağrısı Bildirimin',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              onTap: () async {
                basAgrisiList = fetchBasAgrisi(token);
                setState(() {});
              },
            ),
            FutureBuilder<List<BasAgrisi>>(
              future: basAgrisiList,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(
                      margin: const EdgeInsets.symmetric(vertical: 40),
                      child: const Center(child: CircularProgressIndicator()));
                }
                return snapshot.connectionState == ConnectionState.waiting
                    ? const CircularProgressIndicator()
                    : Column(
                        children: List.generate(snapshot.data!.length, (index) {
                        return Container(
                          decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 5,
                                  blurRadius: 7,
                                  offset: const Offset(
                                      0, 3), // changes position of shadow
                                )
                              ],
                              color: Colors.white70,
                              borderRadius: BorderRadius.circular(25)),
                          margin: const EdgeInsets.only(
                              left: 20, right: 20, bottom: 20),
                          height: 110,
                          width: double.infinity,
                          child: Column(
                            children: [
                              Container(
                                alignment: Alignment.center,
                                margin:
                                    const EdgeInsets.only(left: 20, top: 10),
                                child: Text(
                                  "${snapshot.data?[index].baslangic} / ${snapshot.data?[index].bitis}",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        const Text(
                                          "Şiddeti",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18),
                                        ),
                                        const SizedBox(height: 10),
                                        if (snapshot.data?[index].siddet ==
                                            '0') ...[
                                          Text(
                                            "${snapshot.data?[index].siddet}/10",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.green,
                                            ),
                                          )
                                        ] else if (snapshot
                                                .data?[index].siddet ==
                                            '1') ...[
                                          Text(
                                            "${snapshot.data?[index].siddet}/10",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.green,
                                            ),
                                          )
                                        ] else if (snapshot
                                                .data?[index].siddet ==
                                            '2') ...[
                                          Text(
                                            "${snapshot.data?[index].siddet}/10",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.green,
                                            ),
                                          )
                                        ] else if (snapshot
                                                .data?[index].siddet ==
                                            '3') ...[
                                          Text(
                                            "${snapshot.data?[index].siddet}/10",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.green,
                                            ),
                                          )
                                        ] else if (snapshot
                                                .data?[index].siddet ==
                                            '4') ...[
                                          Text(
                                            "${snapshot.data?[index].siddet}/10",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.orange,
                                            ),
                                          )
                                        ] else if (snapshot
                                                .data?[index].siddet ==
                                            '5') ...[
                                          Text(
                                            "${snapshot.data?[index].siddet}/10",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.orange,
                                            ),
                                          )
                                        ] else if (snapshot
                                                .data?[index].siddet ==
                                            '6') ...[
                                          Text(
                                            "${snapshot.data?[index].siddet}/10",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.orange,
                                            ),
                                          )
                                        ] else if (snapshot
                                                .data?[index].siddet ==
                                            '7') ...[
                                          Text(
                                            "${snapshot.data?[index].siddet}/10",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.red,
                                            ),
                                          )
                                        ] else if (snapshot
                                                .data?[index].siddet ==
                                            '8') ...[
                                          Text(
                                            "${snapshot.data?[index].siddet}/10",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.red,
                                            ),
                                          )
                                        ] else if (snapshot
                                                .data?[index].siddet ==
                                            '9') ...[
                                          Text(
                                            "${snapshot.data?[index].siddet}/10",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.red,
                                            ),
                                          )
                                        ] else if (snapshot
                                                .data?[index].siddet ==
                                            '10') ...[
                                          Text(
                                            "${snapshot.data?[index].siddet}/10",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.red,
                                            ),
                                          )
                                        ]
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        const Text(
                                          "Bölgesi",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18),
                                        ),
                                        const SizedBox(height: 10),
                                        if (snapshot.data?[index].bolge ==
                                            '0') ...[
                                          const Text("Ön Sağ",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black,
                                              ))
                                        ] else if (snapshot
                                                .data?[index].bolge ==
                                            '1') ...[
                                          const Text("Ön Sol",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black,
                                              ))
                                        ] else if (snapshot
                                                .data?[index].bolge ==
                                            '2') ...[
                                          const Text("Arka Sol",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black,
                                              ))
                                        ] else if (snapshot
                                                .data?[index].bolge ==
                                            '3') ...[
                                          const Text("Arka Sağ",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black,
                                              ))
                                        ] else if (snapshot
                                                .data?[index].bolge ==
                                            '4') ...[
                                          const Text("Üst Arka",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black,
                                              ))
                                        ] else if (snapshot
                                                .data?[index].bolge ==
                                            '5') ...[
                                          const Text("Üst Ön",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black,
                                              ))
                                        ] else if (snapshot
                                                .data?[index].bolge ==
                                            '6') ...[
                                          const Text("Yan Arka",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black,
                                              ))
                                        ] else if (snapshot
                                                .data?[index].bolge ==
                                            '7') ...[
                                          const Text("Yan Ön",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black,
                                              ))
                                        ]
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        const Text(
                                          "İlaç",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18),
                                        ),
                                        const SizedBox(height: 10),
                                        snapshot.data?[index].ilac != ""
                                            ? Text(
                                                "${snapshot.data?[index].ilac}",
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black,
                                                ))
                                            : const Text("Yok",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black,
                                                ))
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        const Text(
                                          "Belirtiler",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18),
                                        ),
                                        const SizedBox(height: 10),
                                        snapshot.data?[index].belirti != ""
                                            ? Text(
                                                "${snapshot.data?[index].belirti}",
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black,
                                                ))
                                            : const Text("Yok",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black,
                                                ))
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }));
              },
            ),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 104, 225, 253),
                    foregroundColor: const Color(0xFF000000),
                    fixedSize: const Size(350, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    )),
                child: const Text(
                  'Başım Ağrıyor !',
                  style: TextStyle(fontWeight: FontWeight.w400, fontSize: 17),
                ),
                onPressed: () => {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const FormScreen()))
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
