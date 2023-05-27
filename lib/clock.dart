import 'dart:async';

import 'package:flutter/material.dart';

import 'consts.dart';

class ClockWidget extends StatefulWidget {
  const ClockWidget({super.key});

  @override
  State<ClockWidget> createState() => ClockWidgetState();
}

class ClockWidgetState extends State<ClockWidget> {
  static const DAYS   = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  DateTime time = DateTime.now();

  late Timer timer;

  static String _padTime(String time) {
    return time.length == 1 ? '0' + time : time;
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer _) {
        setState(() {
          time = DateTime.now();      
        });
      }
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            '${_padTime(time.hour.toString())}:${_padTime(time.minute.toString())}',
            style: const TextStyle(
              fontSize: 40,
              color: COLORS.WHITE,
            ),
          ),
          Text(
            '${DAYS[time.weekday - 1]} - ${MONTHS[time.month - 1]} ${time.day}',
            style: const TextStyle(
              fontSize: 20,
              color: COLORS.WHITE,
            ),
          ),
        ],
      ),
    );
  }
}
