import 'package:flutter/material.dart';
import 'dbhelper.dart';
import 'createList.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final dbHelper = DatabaseHelper.instance;
  List<Problem> problems = [];
  void getProblems() {
    setState(() {
      dbHelper.queryAllRows().then((value) => value.forEach((element) {
            print(element);
            problems.insert(
                0,
                Problem(
                    id: element['id'],
                    name: element['name'],
                    category: element['category']));
          }));
    });
  }

  void initState() {
    getProblems();
    super.initState();
  }

  void add() async {
    Problem newP =
        Problem(name: first.text, id: await _insert(first.text), category: 'Y');
    setState(() {
      problems.add(newP);
    });
  }

  TextEditingController first = TextEditingController();
  TextEditingController second = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.grey,
      ),
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                flex: 10,
                child: SingleChildScrollView(
                  child: Column(
                    children: problems.map((p) {
                      return ListOfCards(p, dbHelper, (Problem p) {
                        setState(() {
                          problems.remove(p);
                        });
                      });
                    }).toList(),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Container(
                          margin: const EdgeInsets.only(left: 4.0),
                          child: TextField(
                            onEditingComplete: () {
                              _insert(first.text);
                              first.clear();
                            },
                            controller: first,
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Почему ты грустишь?'),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                        flex: 1,
                        child: IconButton(
                            icon: Icon(
                              Icons.done,
                              color: Colors.teal[300],
                            ),
                            onPressed: () {
                              add();
                              first.clear();
                            })),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<int> _insert(String name) async {
    // row to insert
    Map<String, dynamic> row = {
      DatabaseHelper.columnName: name,
      DatabaseHelper.columnMiles: 'Y'
    };
    Problem car = Problem.fromMap(row);
    final id = await dbHelper.insert(car);
    return id;
  }

  // void _queryAll() async {
  //   final allRows = await dbHelper.queryAllRows();
  //   cars.clear();
  //   allRows.forEach((row) => cars.add(Car.fromMap(row)));
  //   setState(() {});
  // }

  // void _query(name) async {
  //   final allRows = await dbHelper.queryRows(name);
  //   carsByName.clear();
  //   allRows.forEach((row) => carsByName.add(Car.fromMap(row)));
  // }

}
