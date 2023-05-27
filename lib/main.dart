import 'package:flutter/material.dart';

import 'consts.dart';
import 'clock.dart';
import 'app_list.dart';

void main() {
  runApp(const Main());
}

class Main extends StatelessWidget {
  const Main({super.key});

  @override
  Widget build(BuildContext context) {
    //PLAT.invokeMethod('setSavedEdits', '');

    return const MaterialApp(
      title: 'Lornch',
      home: Lornch(),
    );
  }
}

class Lornch extends StatefulWidget {
  const Lornch({super.key});

  @override
  State<Lornch> createState() => LornchState();
}

class LornchState extends State<Lornch> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: COLORS.BLACK,
      body: Padding(
        padding: EdgeInsets.only(top: 50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 20.0),
              child: ClockWidget(),
            ),
            Expanded(
              child: AppList(),
            )
          ],
        ),
      ),
    );
  }
}
