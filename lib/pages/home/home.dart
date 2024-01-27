import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quickbackup/custom/adb.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

Timer? timer;

class _HomepageState extends State<Homepage> {
  String deviceID = "Not Connected";
  String connctionStatus = "Not Connected";
  Color connStatusColor = const Color(0xffcd3550);

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      print(await pt().getAppVersion("com.gokadzev.musify"));
      var res = await pt().checkConnection();
      if (res.error == ptConnectionError.none) {
        setState(() {
          deviceID = res.deviceID;
          connctionStatus = "Connected";
          connStatusColor = const Color(0xff35cd60);
        });
      } else if (res.error == ptConnectionError.noAuth) {
        setState(() {
          deviceID = res.deviceID;
          connStatusColor = const Color(0xffcda560);
          connctionStatus = "Unauthorized";
        });
      } else if (res.state == ptConnectionState.disconnected) {
        if (res.error == ptConnectionError.noDeviceConn) {
          setState(() {
            deviceID = "Not Connected";
            connctionStatus = "Not Connected";
            connStatusColor = const Color(0xffcd3550);
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff202020),
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: const Color(0xff202020),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Text("Connection Status: "),
                  Text(
                    connctionStatus,
                    style: TextStyle(
                      color: connStatusColor,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [const Text("Device ID:  "), Text(deviceID)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
