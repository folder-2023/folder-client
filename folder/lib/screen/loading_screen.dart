import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:folder/services/networking.dart';
import 'package:folder/services/weathermodel.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../main.dart';
import '../protector/fill.dart';
import '../services/location.dart';
import 'package:http/http.dart' as http;

const apiKey = 'b56387afa1f8e32ae9fca47abdbf86e8';

class LoadingScreen extends StatefulWidget {
  final String accessToken;
  const LoadingScreen({super.key, required this.accessToken});
  // final locationWeather;
  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  //약정보띄우는 api
  List<Fill> _fills = [];
  late FlutterLocalNotificationsPlugin _localNotificationsPlugin;
  String? _accessToken;
  DateTime selectedDate = DateTime.utc(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);
  WeatherModel weather = WeatherModel();
  int? temperature;
  Icon? weatherIcon;
  String? weatherexplain;
  var isListening = false;
  var text = '버튼을 꾹 누르고 말해보세요';
  String resulttext = "";
  SpeechToText speechToText = SpeechToText();

  Location location = Location();
  Map<String, dynamic> weatherData = {};

  Future<bool> checkIfPermissionGranted() async {
    PermissionStatus status = await Permission.microphone.request();

    if (!status.isGranted) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: const Text('권한 설정을 확인해주세요'),
              actions: [
                TextButton(
                    onPressed: () {
                      openAppSettings();
                    },
                    child: const Text('설정하기'))
              ],
            );
          });
      return false;
    }
    return true;
  }

  Future<void> PillApi() async {
    const String url1 = 'http://34.168.149.159:8080/my-page/fillInfo/';
    final careurl = Uri.parse(url1);
    final headers = {
      "accept": "*/*",
      "Authorization": "$_accessToken",
    };
    final response = await http.get(careurl, headers: headers);
    final List<dynamic> data = json.decode(response.body);
    print(data);
    setState(() {
      _fills = data.map((json) => Fill.fromJson(json)).toList();
      print("pillapi 성공");
      print(_fills);
    });
  }

  @override
  void initState() {
    PillApi();
    getLocationData();
    setState(() {
      getLocationData();
    });
    _accessToken = widget.accessToken;
    init();
    PostFcm();
    super.initState();
    _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
    FirebaseMessaging.instance
        .getToken()
        .then((value) => print('Token:$value'));
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {}
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showNotification(message);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // Handle notification message when app is open
    });
  }

  Future<void> showNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = AndroidNotificationDetails(channel.id, channel.name,
        priority: Priority.high, importance: Importance.high, showWhen: false);
    final platform = NotificationDetails(android: android);
    await _localNotificationsPlugin.show(notification.hashCode,
        notification?.title, notification?.body, platform,
        payload: message.data.toString());
  }

  String? devicetoken;
  //get device token
  Future getDeviceToken() async {
    FirebaseMessaging FirebaseMessage = FirebaseMessaging.instance;
    String? deviceToken = await FirebaseMessage.getToken();
    return deviceToken;
  }

  init() async {
    devicetoken = await getDeviceToken();
    print("### PRINT DEVICE TOKEN ####");
    print(devicetoken);
  }

  Future<void> PostFcm() async {
    await init();
    if (devicetoken == null) {
      print('device token is null');
      return;
    }
    String url = 'http://34.168.149.159:8080/auth/fcm';
    final headers = {
      "Authorization": "$_accessToken",
      "Content-Type": "application/json"
    };
    final response = await http.post(Uri.parse(url),
        headers: headers, body: jsonEncode(devicetoken).replaceAll('"', ''));
    print(devicetoken);

    if (response.statusCode == 200) {
      print('fcmtoken 저장 완료');
      print(response.body);
    } else {
      print('fcmtoken 저장 실패');
      print(response.body);
    }
  }

  void getLocationData() async {
    print("geolocation호출");
    await location.getCurrentLocation();
    NetworkHelper networkHelper = NetworkHelper(
        'https://api.openweathermap.org/data/2.5/weather?lat=${location.latitude}&lon=${location.longitude}&appid=$apiKey&units=metric');
    var fetchedData = await networkHelper.getData();
    setState(() {
      weatherData = fetchedData;
    });
    updatedUI(weatherData);
    //decodedData 를 weatherData가 받음
    // return weatherData;
  }

  void updatedUI(dynamic weatherData) {
    print("updatedUI호출");
    double temp = weatherData['main']['temp'];
    temperature = temp.floor();
    var condition = weatherData['weather'][0]['id'];
    weatherIcon = weather.getWeatherIcon(condition);
    weatherexplain = weather.getMessage(condition);
    print(temperature);
    print(weatherIcon);
    print(weatherexplain);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일',
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 30,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      const Text(
                        '오늘의 일정',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    ],
                  )
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: const [
                  Text(
                    '헤이 부르기',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 38,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Column(
                children: [
                  const Text('답변하기'),
                  FloatingActionButton(
                    child: GestureDetector(
                      onTapDown: (details) async {
                        if (!isListening) {
                          var available = await speechToText.initialize();
                          if (available) {
                            isListening = true;
                            speechToText.listen(
                              onResult: (result) {
                                setState(() {
                                  text = result.recognizedWords;
                                  resulttext = text;
                                });
                                print("onpressed");
                              },
                            );
                          }
                        }
                      },
                      onTapUp: (details) {
                        setState(() {
                          isListening = false;
                        });
                        speechToText.stop();
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.teal.shade700,
                        radius: 35,
                        child: Icon(isListening ? Icons.mic : Icons.mic_none,
                            color: Colors.white),
                      ),
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: const [
                  Text(
                    '오늘의 날씨',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 38,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                decoration: BoxDecoration(
                    color: Colors.teal.shade900,
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Transform.scale(
                        scale: 1.3,
                        child: Transform.translate(
                          offset: const Offset(-7, -13),
                          child: weatherIcon,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$temperature 도', //날씨데이터
                              style: const TextStyle(
                                  fontSize: 28,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '$weatherexplain', //날씨에따른 멘트
                              style: const TextStyle(
                                  fontSize: 25,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: const [
                  Text(
                    '약복용',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _fills.length,
                  itemBuilder: (context, index) {
                    return Flexible(
                        child: ListTile(
                      title: Text(_fills[index].fillName),
                      subtitle: Text(_fills[index].fillTime),
                    ));
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
