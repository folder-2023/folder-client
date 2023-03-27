import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:folder/protector/calendar.dart';
import 'package:intl/intl.dart';

import '../protector/fill.dart';
import 'package:folder/protector/event.dart';

class ProtectorHomeScreen extends StatefulWidget {
  final String accessToken;
  const ProtectorHomeScreen({required this.accessToken, super.key});
  @override
  State<ProtectorHomeScreen> createState() => _ProtectorHomeScreenState();
}

class _ProtectorHomeScreenState extends State<ProtectorHomeScreen> {
  List<Fill> _fills = [];
  String formatDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String? _accessToken;
  List<Event> _events = [];
  bool iseventChecked = false;
  bool isfillChecked = false;
  @override
  void initState() {
    super.initState();
    _accessToken = widget.accessToken;
    getCalendar();
    PillApi();
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
    });
  }

  Future<void> getCalendar() async {
    const String url1 = 'http://34.168.149.159:8080/calendar';
    final careurl = Uri.parse(url1);
    final headers = {
      "Authorization": "$_accessToken",
    };
    final response = await http.get(careurl, headers: headers);
    final List<dynamic> data = json.decode(response.body);
    print(data);
    setState(() {
      _events = data.map((json) => Event.fromJson(json)).toList();
    });
  }

  // final Map<String,dynamic> _calendar;
  final _eventController = TextEditingController();
  final _timeController = TextEditingController();
  DateTime selectedDate = DateTime.utc(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);

  DateTime today = DateTime.now();
  //final bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                //처음 초록색
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 63, 121, 114),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                          child: Text(
                            '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w600),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    '어르신 일정추가하기',
                    style: TextStyle(
                        color: Colors.teal.shade700,
                        fontSize: 25,
                        fontWeight: FontWeight.w700),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: CalendarWidget(
                selectedDate: selectedDate,
                onDaySelected: onDaySelected,
              ),
            ),
            FloatingActionButton(
              onPressed: (() {
                initState() {
                  _eventController;
                  _timeController;
                }

                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('일정 추가하기'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _eventController,
                          decoration: const InputDecoration(hintText: '일정 내용'),
                        ),
                        TextField(
                          controller: _timeController,
                          decoration: const InputDecoration(
                              hintText: '일정 시간( - - : - -)'),
                        )
                      ],
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('취소')),
                      ElevatedButton(
                          onPressed: () async {
                            print(selectedDate.toIso8601String().split('T')[0]);
                            print(_eventController.text);
                            print(_timeController.text);
                            final eventName = _eventController.text;
                            final eventTime = _timeController.text;
                            if (eventName.isNotEmpty && eventTime.isNotEmpty) {
                              final url = Uri.parse(
                                  'http://34.168.149.159:8080/calendar');
                              final headers = {
                                'Authorization': '$_accessToken',
                                'Content-Type': 'application/json'
                              };
                              final response = await http.post(url,
                                  headers: headers,
                                  body: jsonEncode(<String, dynamic>{
                                    'calendarDate': selectedDate
                                        .toIso8601String()
                                        .split('T')[0],
                                    'calendarTime': eventTime,
                                    'content': eventName,
                                    //'calendarCheck': false,
                                    //'calendarId': 0,
                                  }));
                              if (response.statusCode == 200) {
                                print(response.body);
                              } else {
                                print(response.body);
                              }
                            }
                            Navigator.of(context).pop();
                          },
                          child: const Text('추가하기'))
                    ],
                  ),
                );
              }),
              child: const Icon(Icons.add),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    '오늘의 일정',
                    style: TextStyle(
                        color: Colors.teal.shade700,
                        fontSize: 25,
                        fontWeight: FontWeight.w700),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _events.length,
                  itemBuilder: (BuildContext context, int index) {
                    final event = _events[index];
                    if (event.date == formatDate) {
                      return CheckboxListTile(
                        value: iseventChecked,
                        onChanged: ((value) {
                          setState(() {
                            iseventChecked = value!;
                          });
                        }),
                        title: Text(event.name),
                        subtitle: Text(event.time),
                      );
                    } else {
                      return const Text('');
                    }
                  }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    '약 복용',
                    style: TextStyle(
                        color: Colors.teal.shade700,
                        fontSize: 25,
                        fontWeight: FontWeight.w700),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _fills.length,
                  itemBuilder: (BuildContext context, int index) {
                    final fill = _fills[index];
                    return CheckboxListTile(
                      value: isfillChecked,
                      onChanged: (value) {
                        setState(() {
                          isfillChecked = value!;
                        });
                      },
                      title: Text(fill.fillName),
                      subtitle: Text(fill.fillTime),
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }

  void onDaySelected(DateTime selectedDate, DateTime focusedDate) {
    setState(() {
      this.selectedDate = selectedDate;
    });
  }
}
