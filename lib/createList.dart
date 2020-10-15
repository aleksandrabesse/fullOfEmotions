import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dbhelper.dart';

class MultiSelectChip extends StatefulWidget {
  final List<String> reportList;
  final Function(List<String>) onSelectionChanged;
  final Function(List<String>) onDeleteChanged;

  MultiSelectChip(this.reportList,
      {this.onSelectionChanged, this.onDeleteChanged});
  @override
  _MultiSelectChipState createState() => _MultiSelectChipState();
}

class _MultiSelectChipState extends State<MultiSelectChip> {
  List<String> selectedChoices = List();

  _buildChoiceList() {
    List<Widget> choices = List();
    widget.reportList.forEach((item) {
      choices.add(Container(
        padding: const EdgeInsets.all(2.0),
        child: GestureDetector(
          onLongPress: () {
            setState(() {
              widget.reportList.remove(item);
              widget.onDeleteChanged(widget.reportList);
            });
          },
          child: FilterChip(
            label: Text(item),
            selectedColor: Colors.teal[100],
            backgroundColor: Colors.white,
            selected: selectedChoices.contains(item),
            onSelected: (selected) {
              setState(() {
                selectedChoices.contains(item)
                    ? selectedChoices.remove(item)
                    : selectedChoices.add(item);
                widget.onSelectionChanged(selectedChoices);
              });
            },
          ),
        ),
      ));
    });

    return choices;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      direction: Axis.horizontal,
      spacing: 4.0, // gap between adjacent chips
      runSpacing: 4.0, // gap between lines
      children: _buildChoiceList(),
    );
  }
}

class Problem {
  int id;
  String name;
  String category = 'Ничего';

  Problem({this.id, this.name, this.category});
  Problem.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    name = map['name'];
    category = map['category'];
  }

  Map<String, dynamic> toMap() {
    return {
      DatabaseHelper.columnId: id,
      DatabaseHelper.columnName: name,
      DatabaseHelper.columnMiles: category,
    };
  }
}

class ListOfCards extends StatefulWidget {
  final Function(Problem) onChangeMainList;
  Problem p;
  final dbHelper;
  ListOfCards(this.p, this.dbHelper, this.onChangeMainList);
  _ListOfCardsState createState() => _ListOfCardsState();
}

class _ListOfCardsState extends State<ListOfCards> {
  List<String> category = [];

  bool _allowWriteFile = false;

  @override
  void initState() {
    super.initState();
    requestWritePermission();
    getList();
  }

  Future<String> readFile() async {
    try {
      final file = await _localFile;
      String content = await file.readAsString();
      return content;
    } catch (e) {
      return '';
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  requestWritePermission() async {
    final PermissionHandler _permissionHandler = PermissionHandler();
    var result =
        await _permissionHandler.requestPermissions([PermissionGroup.storage]);
    if (result == PermissionStatus.granted) {
      setState(() {
        _allowWriteFile = true;
      });
    }
  }

  Future get _localPath async {
    // Application documents directory: /data/user/0/{package_name}/{app_name}
    final applicationDirectory = await getApplicationDocumentsDirectory();
    return applicationDirectory.path;
  }

  void getList() {
    String t;
    readFile().then((String text) {
      t = text;
      category = t.split('\n');
    });
    for (int i = 0; i < category.length; i++) {
      if (category[i] == ' ') category.removeAt(i);
      if (category[i] == '') category.removeAt(i);
      if (category[i] == '\n') category.removeAt(i);
    }
  }

  Future get _localFile async {
    final path = await _localPath;
    return File('$path/category.txt');
  }

  Future<File> writeFile(String text) async {
    print('HEY '+text);
    final file = await _localFile;
    return file.writeAsString('$text\r\n');
  }

  void update(Problem a, String category) async {
    // row to update
    a.category = category;
    final rowsAffected = await widget.dbHelper.update(a);
  }

  void delete(id) async {
    // Assuming that the number of rows is the id for the last row.
    final rowsDeleted = await widget.dbHelper.delete(id);
  }

  TextEditingController _newCategory = TextEditingController();
  List<String> selectedReportList = List();
  bool isUpdate = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        if (details.delta.dx > 0) {
          // swiping in right direction
          setState(() {
            delete(widget.p.id);
            widget.onChangeMainList(widget.p);
          });
        }
      },
      onLongPress: () {
        showDialog(
            context: context,
            builder: (context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0)),
                child: Container(
                  margin: EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Wrap(
                        alignment: WrapAlignment.center,
                        direction: Axis.horizontal,
                        spacing: 4.0, // gap between adjacent chips
                        runSpacing: 4.0, // gap between lines
                        children: [
                          MultiSelectChip(
                            category,
                            onDeleteChanged: (categoryNew) {
                              setState(() {
                                category = categoryNew;
                              });
                            },
                            onSelectionChanged: (selectedList) {
                              setState(() {
                                selectedReportList = selectedList;
                                isUpdate = true;
                                selectedReportList.forEach((element) {
                                  widget.p.category += ' ';
                                  widget.p.category += element;
                                  update(widget.p, widget.p.category);
                                });
                              });
                            },
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            width: MediaQuery.of(context).size.width / 2,
                            child: TextField(
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (String text) {
                                setState(() {
                                  if (text.isNotEmpty) {
                                    category.add(text);
                                    String p = '';
                                    category.forEach((element) {
                                      if (element != '' && element != ' ' && element!='\n') {
                                        p += element;
                                        p += '\n';
                                      }
                                    });
                                    writeFile(p);
                                  }
                                  _newCategory.clear();
                                });
                              },
                              controller: _newCategory,
                              decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Новая категория'),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            });
      },
      child: Card(
        child: ListTile(
          title: Text(widget.p.name),
          subtitle:
              isUpdate ? Text(widget.p.category) : Text(widget.p.category),
        ),
      ),
    );
  }
}
