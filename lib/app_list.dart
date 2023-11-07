import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:collection/collection.dart';

import 'consts.dart';

class AppList extends StatefulWidget {
  const AppList({super.key});

  @override
  State<AppList> createState() => AppListState();
}

class AppListState extends State<AppList> {
  final FocusNode focus = FocusNode();

  List<App> edits = [];
  List<App> apps = [];

  int selected = -1;

  void saveEdits() {
    String str = edits.isEmpty ? '' : edits.map((x) => x.toString()).fold('', (x, y) => '$x\n$y').replaceFirst('\n', '');

    PLAT.invokeMethod('setSavedEdits', str);
  }

  Future<void> getEdits() async {
    String str = (await PLAT.invokeMethod<String>('getSavedEdits'))!;

    if (str == '') return;

    edits = str
      .split('\n')
      .map((x) => App.fromString(x))
      .toList();
  }

  Future<void> getAppList() async {
    List<List<String>> appNames = [];

    try {
      appNames = IterableZip([
        (await PLAT.invokeListMethod<String>('getAppNames'))!, 
        (await PLAT.invokeListMethod<String>('getAppPackages'))!,
      ]).toList();
    } on PlatformException catch (_) { }

    apps = appNames
      .mapIndexed((i, n) => App(key: GlobalKey(), name: n[0], package: n[1]))
      .where((x) => !edits.contains(x)).toList() + edits;
  }

  void sortAppList() {
    List<App> positioned = apps.where((x) => x.pos != null).toList();

    positioned.sort((x, y) => x.orderCompare(y));

    apps = apps.where((x) => x.pos == null).toList();
    apps.sortBy((x) => x.name);

    apps = positioned + apps;
  }

  void appEditCallBack(App app) {
    if (!edits.contains(app)) 
      edits.add(app);

    saveEdits();

    setState(() {
      sortAppList();
    });
  }

  KeyEventResult handleKeyEvent(FocusNode node, RawKeyEvent event) {
    if (event is RawKeyUpEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      // Select Button
      case LogicalKeyboardKey.enter:
        apps[selected].launch();
        
        return KeyEventResult.handled;
      // Up Arrow
      case LogicalKeyboardKey.arrowUp:
        selected--;
        break;
      // Down Arrow
      case LogicalKeyboardKey.arrowDown:
        selected++;        
        break;
      default:
        return KeyEventResult.ignored;
    }

    setState(() {
      selected = selected < -1 ? -1 : (selected > apps.length - 1 ? apps.length -1 : selected);   
    });

    if (selected > -1) {
      RenderBox btnBox = (apps[selected].key.currentContext?.findRenderObject()! as RenderBox);
      double btnY = btnBox.localToGlobal(Offset.zero).dy;

      if (
        btnY + btnBox.size.height * 0.7 > MediaQuery.of(context).size.height || 
        btnY < (context.findRenderObject()! as RenderBox).localToGlobal(Offset.zero).dy) {
        Scrollable.ensureVisible(
          apps[selected].key.currentContext!,
          duration: const Duration(milliseconds: 450)
        );
      }
    }

    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    getEdits().then((_) => {
      getAppList().then((_) => {
        setState(() {
          sortAppList();
        })
      })
    });


    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focus,
      onKey: handleKeyEvent,
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: apps.map(
            (x) => AppSection(key: x.key, app: x, selected: selected >= 0 && apps[selected].name == x.name, appEditCallBack: appEditCallBack)
          ).toList(),
        ),
      ),
    );
  }
}

class App {
  App({required this.key, required this.name, required this.package, this.pos});

  final GlobalKey key;

  String name;
  final String package;

  int? pos;

  static App fromString(String str) {
    List<String> split = str.split('|');

    return App(key: GlobalKey(), name: split[0], package: split[1], pos: int.tryParse(split[2]));
  }

  @override
  String toString() {
    return '$name|$package|${pos.toString()}';
  }

  @override
  bool operator ==(Object other) {
    if (other is! App) return false;

    return package == (other as App).package;
  }

  int orderCompare(App other) {
    if (pos == null && other.pos == null) return 0;

    if (pos == null || other.pos == null) throw ArgumentError();

    return pos! - other.pos!;
  }

  Future<void> launch() async {
    await PLAT.invokeMethod('launchApp', package);
  }
}

class AppSection extends StatefulWidget {
  const AppSection({required super.key, required this.app, required this.selected, required this.appEditCallBack});

  final App app;

  final bool selected;

  final void Function(App) appEditCallBack;

  @override
  State<StatefulWidget> createState() => AppSectionState(app: app);
}

class AppSectionState extends State<AppSection> {
  AppSectionState({required this.app});

  App app;

  bool editing = false;

  void toggleEditCallBack() {
    setState(() {
      if (editing) {
        widget.appEditCallBack(app);
      }

      editing = !editing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return editing ? 
      EditSection(app: app, toggleEditCallBack: toggleEditCallBack) : 
      AppButton(app: app, selected: widget.selected, toggleEditCallBack: toggleEditCallBack);
  }
}

class AppButton extends StatelessWidget {
  const AppButton({super.key, required this.app, required this.selected, required this.toggleEditCallBack});

  final App app;

  final bool selected;

  final VoidCallback toggleEditCallBack; 

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => PLAT.invokeMethod('launchApp', app.package), 
      onLongPress: toggleEditCallBack,
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(selected ? COLORS.GREY : COLORS.BLACK),
        foregroundColor: MaterialStateProperty.all(COLORS.WHITE),
        shape: MaterialStateProperty.all(const ContinuousRectangleBorder()),
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 30.0),
          child: Text(
            app.name,
            style: const TextStyle(
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class EditSection extends StatelessWidget {
  const EditSection({super.key, required this.app, required this.toggleEditCallBack});

  final App app;

  final VoidCallback toggleEditCallBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
          child: SizedBox(
            width: 22.0,
            child: TextFormField(
              onChanged: (pos) => app.pos = int.tryParse(pos),
              style: const TextStyle(
                color: COLORS.WHITE,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.all(4.0),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: COLORS.WHITE),
                ),
              ),
              initialValue: app.pos == null ? '' : app.pos.toString(),
            ),
          ),
        ),
        Flexible(
          child: TextFormField(
            onChanged: (name) => app.name = name,
            style: const TextStyle(
              color: COLORS.WHITE,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.all(4.0),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: COLORS.WHITE),
              ),
            ),
            initialValue: app.name,
          ),
        ),
        TextButton(
          onPressed: toggleEditCallBack,
          child: const Text(
            'X',
            style: TextStyle(color: COLORS.WHITE),
          ),
        ),
      ],
    );
  }
}
