import 'dart:async';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animated_dialog/flutter_animated_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku_solver_generator/sudoku_solver_generator.dart';

import 'alerts/all.dart';
import 'board_style.dart';
import 'splash_screen_page.dart';
import 'styles.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  static const String versionNumber = '2.4.1';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudoku',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Styles.primaryColor,
      ),
      home: const SplashScreenPage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int seconds = 0, minutes = 0, hours = 0;
  String digitSecond = "00", digitMinutes = "00", digitHours = "00";

  Timer timer;
  bool started = false;

  //Now 3 functions have been defined stop/reset/start for the functionality of Timer

  void stop() {
    timer.cancel();
    setState(() {
      started = false;
    });
  }

  void reset() {
    timer.cancel();
    setState(() {
      started = false;
      seconds = 0;
      minutes = 0;
      hours = 0;
      digitSecond = "00";
      digitMinutes = "00";
      digitHours = "00";
    });
  }

  void start() {
    started = true;
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      int localSeconds = seconds + 1;
      int localMinutes = minutes;
      int localHours = hours;

      if (localSeconds > 59) {
        if (localMinutes > 59) {
          localHours += 1;
          localMinutes = 0;
        } else {
          localMinutes += 1;
          localSeconds = 0;
        }
      }

      setState(() {
        seconds = localSeconds;
        minutes = localMinutes;
        hours = localHours;
        digitSecond = (seconds >= 10) ? "$seconds" : "0$seconds";
        digitHours = (hours >= 10) ? "$hours" : "0$hours";
        digitMinutes = (minutes >= 10) ? "$minutes" : "0$minutes";
      });
    });
  }

  bool firstRun = true;
  bool gameOver = false;
  int timesCalled = 0;
  bool isButtonDisabled = false;
  bool isFABDisabled = false;
  List<List<List<int>>> gameList;
  List<List<int>> game;
  List<List<int>> gameCopy;
  List<List<int>> gameSolved;
  static String currentDifficultyLevel;
  static String currentTheme;
  static String currentAccentColor;
  static String platform = () {
    if (kIsWeb) {
      return 'web-${defaultTargetPlatform.toString().replaceFirst("TargetPlatform.", "").toLowerCase()}';
    } else {
      return defaultTargetPlatform
          .toString()
          .replaceFirst("TargetPlatform.", "")
          .toLowerCase();
    }
  }();
  static bool isDesktop = ['windows', 'linux', 'macos'].contains(platform);

  @override
  void initState() {
    super.initState();
    start();
    try {
      doWhenWindowReady(() {
        appWindow.alignment = Alignment.bottomCenter;
        appWindow.minSize = const Size(625, 300);
      });
      // ignore: empty_catches
    } on UnimplementedError {}
    getPrefs().whenComplete(() {
      if (currentDifficultyLevel == null) {
        currentDifficultyLevel = 'easy';
        setPrefs('currentDifficultyLevel');
      }
      if (currentTheme == null) {
        if (MediaQuery.maybeOf(context)?.platformBrightness != null) {
          currentTheme =
              MediaQuery.of(context).platformBrightness == Brightness.light
                  ? 'light'
                  : 'dark';
        } else {
          currentTheme = 'dark';
        }
        setPrefs('currentTheme');
      }
      if (currentAccentColor == null) {
        currentAccentColor = 'Blue';
        setPrefs('currentAccentColor');
      }
      newGame(currentDifficultyLevel);
      changeTheme('set');
      changeAccentColor(currentAccentColor, true);
    });
  }

  Future<void> getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentDifficultyLevel = prefs.getString('currentDifficultyLevel');
      currentTheme = prefs.getString('currentTheme');
      currentAccentColor = prefs.getString('currentAccentColor');
    });
  }

  setPrefs(String property) async {
    final prefs = await SharedPreferences.getInstance();
    if (property == 'currentDifficultyLevel') {
      prefs.setString('currentDifficultyLevel', currentDifficultyLevel);
    } else if (property == 'currentTheme') {
      prefs.setString('currentTheme', currentTheme);
    } else if (property == 'currentAccentColor') {
      prefs.setString('currentAccentColor', currentAccentColor);
    }
  }

  void changeTheme(String mode) {
    setState(() {
      if (currentTheme == 'light') {
        if (mode == 'switch') {
          Styles.primaryBackgroundColor = Styles.darkGrey;
          Styles.secondaryBackgroundColor = Styles.grey;
          Styles.foregroundColor = Styles.white;
          currentTheme = 'dark';
        } else if (mode == 'set') {
          Styles.primaryBackgroundColor = Styles.white;
          Styles.secondaryBackgroundColor = Styles.white;
          Styles.foregroundColor = Styles.darkGrey;
        }
      } else if (currentTheme == 'dark') {
        if (mode == 'switch') {
          Styles.primaryBackgroundColor = Styles.white;
          Styles.secondaryBackgroundColor = Styles.white;
          Styles.foregroundColor = Styles.darkGrey;
          currentTheme = 'light';
        } else if (mode == 'set') {
          Styles.primaryBackgroundColor = Styles.darkGrey;
          Styles.secondaryBackgroundColor = Styles.grey;
          Styles.foregroundColor = Styles.white;
        }
      }
      setPrefs('currentTheme');
    });
  }

  void changeAccentColor(String color, [bool firstRun = false]) {
    setState(() {
      if (Styles.accentColors.keys.contains(color)) {
        Styles.primaryColor = Styles.accentColors[color];
      } else {
        currentAccentColor = 'Blue';
        Styles.primaryColor = Styles.accentColors[color];
      }
      if (color == 'Red') {
        Styles.secondaryColor = Styles.orange;
      } else {
        Styles.secondaryColor = Styles.lightRed;
      }
      if (firstRun) {
        setPrefs('currentAccentColor');
      }
    });
  }

  void checkResult() {
    try {
      if (SudokuUtilities.isSolved(game)) {
        isButtonDisabled = isButtonDisabled;
        gameOver = true;
        Timer(const Duration(milliseconds: 500), () {
          showAnimatedDialog<void>(
              animationType: DialogTransitionType.fadeScale,
              barrierDismissible: true,
              duration: const Duration(milliseconds: 350),
              context: context,
              builder: (_) => const AlertGameOver()).whenComplete(() {
            if (AlertGameOver.newGame) {
              newGame();
              AlertGameOver.newGame = false;
            } else if (AlertGameOver.restartGame) {
              restartGame();
              AlertGameOver.restartGame = false;
            }
          });
        });
      }
    } on InvalidSudokuConfigurationException {
      return;
    }
  }

  static Future<List<List<List<int>>>> getNewGame(
    [String difficulty = 'easy']) async {
    int emptySquares;
    switch (difficulty) {
      case 'test':
        {
          emptySquares = 2;
        }
        break;
      case 'beginner':
        {
          emptySquares = 18;
        }
        break;
      case 'easy':
        {
          emptySquares = 27;
        }
        break;
      case 'medium':
        {
          emptySquares = 36;
        }
        break;
      case 'hard':
        {
          emptySquares = 54;
        }
        break;
      default:
        {
          emptySquares = 2;
        }
        break;
    }
    SudokuGenerator generator = SudokuGenerator(emptySquares: emptySquares);
    return [generator.newSudoku, generator.newSudokuSolved];
  }

  static List<List<int>> copyGrid(List<List<int>> grid) {
    return grid.map((row) => [...row]).toList();
  }

  void setGame(int mode, [String difficulty = 'easy']) async {
    if (mode == 1) {
      game = List.filled(9, [0, 0, 0, 0, 0, 0, 0, 0, 0]);
      gameCopy = List.filled(9, [0, 0, 0, 0, 0, 0, 0, 0, 0]);
      gameSolved = List.filled(9, [0, 0, 0, 0, 0, 0, 0, 0, 0]);
    } else {
      gameList = await getNewGame(difficulty);
      game = gameList[0];
      gameCopy = copyGrid(game);
      gameSolved = gameList[1];
    }
  }

  void showSolution() {
    setState(() {
      stop();
      game = copyGrid(gameSolved);
      isButtonDisabled = isButtonDisabled ? isButtonDisabled : isButtonDisabled;
      gameOver = true;
    });
  }

  void newGame([String difficulty = 'easy']) {
    setState(() {
      reset();
      start();
      isFABDisabled = isFABDisabled;
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        setGame(2, difficulty);
        isButtonDisabled =
            isButtonDisabled ? isButtonDisabled : isButtonDisabled;
        gameOver = false;
        isFABDisabled = !isFABDisabled;
      });
    });
  }

  void restartGame() {
    setState(() {
      reset();
      start();
      game = copyGrid(gameCopy);
      isButtonDisabled =
          isButtonDisabled ? !isButtonDisabled : isButtonDisabled;
      gameOver = false;
    });
  }

  List<SizedBox> createButtons() {
    if (firstRun) {
      setGame(1);
      firstRun = false;
    }

    List<SizedBox> buttonList = List<SizedBox>.filled(9, const SizedBox());
    for (var i = 0; i <= 8; i++) {
      var k = timesCalled;
      buttonList[i] = SizedBox(
        key: Key('grid-button-$k-$i'),
        width: buttonSize(),
        height: buttonSize(),
        child: TextButton(
          onPressed: isButtonDisabled || gameCopy[k][i] != 0
              ? null
              : () {
                  showAnimatedDialog<void>(
                          animationType: DialogTransitionType.fade,
                          barrierDismissible: true,
                          duration: const Duration(milliseconds: 300),
                          context: context,
                          builder: (_) => const AlertNumbersState())
                      .whenComplete(() {
                    callback([k, i], AlertNumbersState.number);
                    AlertNumbersState.number = null;
                  });
                },
          onLongPress: isButtonDisabled || gameCopy[k][i] != 0
              ? null
              : () => callback([k, i], 0),
          style: ButtonStyle(
            backgroundColor:
                MaterialStateProperty.all<Color>(buttonColor(k, i)),
            foregroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
              if (states.contains(MaterialState.disabled)) {
                return gameCopy[k][i] == 0
                    ? emptyColor(gameOver)
                    : Styles.foregroundColor;
              }
              return game[k][i] == 0
                  ? buttonColor(k, i)
                  : Styles.secondaryColor;
            }),
            shape: MaterialStateProperty.all<OutlinedBorder>(
                RoundedRectangleBorder(
              borderRadius: buttonEdgeRadius(k, i),
            )),
            side: MaterialStateProperty.all<BorderSide>(BorderSide(
              color: Styles.foregroundColor,
              width: 1,
              style: BorderStyle.solid,
            )),
          ),
          child: Text(
            game[k][i] != 0 ? game[k][i].toString() : ' ',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: buttonFontSize()),
          ),
        ),
      );
    }
    timesCalled++;
    if (timesCalled == 9) {
      timesCalled = 0;
    }
    return buttonList;
  }

  Row oneRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: createButtons(),
    );
  }

  List<Row> createRows() {
    List<Row> rowList = List<Row>.generate(9, (i) => oneRow());
    return rowList;
  }

  bool callback(List<int> index, int number) {
    setState(() {
      if (number == null) {
        return;
      } else if (number == 0) {
        game[index[0]][index[1]] = number;
      } else {
        game[index[0]][index[1]] = number;
        checkResult();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          if (kIsWeb) {
            return false;
          } else {
            showAnimatedDialog<void>(
                animationType: DialogTransitionType.fadeScale,
                barrierDismissible: true,
                duration: const Duration(milliseconds: 350),
                context: context,
                builder: (_) => const AlertExit());
          }
          return true;
        },
        child: Scaffold(
          backgroundColor: Styles.primaryBackgroundColor,
          appBar: PreferredSize(
              preferredSize: const Size.fromHeight(56.0),
              child: isDesktop
                  ? MoveWindow(
                      onDoubleTap: () => appWindow.maximizeOrRestore(),
                      child: AppBar(
                        centerTitle: true,
                        title: const Text('Sudoku'),
                        backgroundColor: Styles.primaryColor,
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.minimize_outlined),
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 15),
                            onPressed: () {
                              appWindow.minimize();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                            onPressed: () {
                              showAnimatedDialog<void>(
                                  animationType: DialogTransitionType.fadeScale,
                                  barrierDismissible: true,
                                  duration: const Duration(milliseconds: 350),
                                  context: context,
                                  builder: (_) => const AlertExit());
                            },
                          ),
                        ],
                      ),
                    )
                  : AppBar(
                      centerTitle: true,
                      title: const Text('Sudoku'),
                      backgroundColor: Styles.primaryColor,
                    )),
          body: Builder(builder: (builder) {
            return Container(
              child: Stack(
                children: [
                  Positioned(
                      left: 120,
                      top: 20,
                      // width:40,
                      height: 40,
                      child: Row(
                        children: [
                          Text(
                            "$digitHours : $digitMinutes : $digitSecond",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 196, 50, 40),
                            ),
                          ),
                        ],
                      )),
                  Positioned(
                    top: 70,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: createRows(),
                    ),
                  ),
                  Positioned(
                    bottom: 190,
                    // left: 10,
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            showAnimatedDialog<void>(
                                    animationType: DialogTransitionType.fade,
                                    barrierDismissible: true,
                                    duration: const Duration(milliseconds: 300),
                                    context: context,
                                    builder: (_) => const AlertNumbersState())
                                .whenComplete(() {
                              callback([1, 1], AlertNumbersState.number);
                              AlertNumbersState.number = null;
                            });
                          },
                          child: textItem(1),
                        ),
                        TextButton(
                          child: textItem(2),
                        ),
                        TextButton(
                          child: textItem(3),
                        ),
                        TextButton(
                          child: textItem(4),
                        ),
                        TextButton(
                          child: textItem(5),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 100,
                    left: 30,
                    child: Row(
                      children: [
                        TextButton(
                          child: textItem(6),
                        ),
                        TextButton(
                          child: textItem(7),
                        ),
                        TextButton(
                          child: textItem(8),
                        ),
                        TextButton(
                          child: textItem(9),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            InkWell(
                                child: Column(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.refresh,
                                    color: Colors.black,
                                  ),
                                  iconSize: 60,
                                  onPressed: () {
                                    // Navigator.pop(context);
                                    Timer(const Duration(milliseconds: 200),
                                        () => restartGame());
                                  },
                                ),
                                Text(
                                  "Restart",
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 20),
                                )
                              ],
                            )),
                            SizedBox(width: 49),
                            InkWell(
                                child: Column(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.add_rounded,
                                    color: Colors.black,
                                  ),
                                  iconSize: 60,
                                  onPressed: () {
                                    // Navigator.pop(context);
                                    Timer(const Duration(milliseconds: 200),
                                        () => newGame(currentDifficultyLevel));
                                  },
                                ),
                                Text(
                                  "New Game",
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 20),
                                )
                              ],
                            )),
                            SizedBox(width: 35),
                            InkWell(
                                child: Column(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.lightbulb_outline_rounded,
                                    color: Colors.black,
                                  ),
                                  iconSize: 60,
                                  onPressed: () {
                                    // Navigator.pop(context);
                                    Timer(const Duration(milliseconds: 200),
                                        () => showSolution());
                                  },
                                ),
                                Text("Show Solution",
                                    style: TextStyle(
                                        color: Colors.black, fontSize: 20))
                              ],
                            )),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          }),
        ));
  }

  Widget textItem(int number) {
    return Container(
      height: 60,
      width: 60,
      child: Container(
          decoration: BoxDecoration(
              color: Color.fromARGB(29, 230, 140, 140),
              borderRadius: BorderRadius.all(Radius.circular(10.0))),
          child: new Center(
            child: new Text(
              "$number",
              style: TextStyle(fontSize: 22, color: Colors.black),
              textAlign: TextAlign.center,
            ),
          )),
    );
  }
}
