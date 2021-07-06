import 'package:disc_golf/db/firebase_helper.dart';
import 'package:disc_golf/models/course.dart';
import 'package:disc_golf/models/match.dart';
import 'package:flutter/material.dart';

import '../utils/utils.dart' as utils;

const _DEFAULT_PAR = 3;
const _DEFAULT_HOLES = 18;
const _MAX_HOLES = 36;

class NewMatchScreen extends StatefulWidget {
  const NewMatchScreen({Key? key}) : super(key: key);

  @override
  _NewMatchScreenState createState() => _NewMatchScreenState();
}

class _NewMatchScreenState extends State<NewMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedValue;
  late DateTime _selectedDateTime;
  late TextEditingController _nameController;
  late TextEditingController _holeController;
  late FocusNode _focusNode;
  List<int> _holes = List.generate(_MAX_HOLES, (index) => _DEFAULT_PAR);

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _selectedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );

    _focusNode = FocusNode();

    _nameController = TextEditingController();
    _holeController = TextEditingController(text: _DEFAULT_HOLES.toString());
  }

  @override
  Widget build(BuildContext context) {
    const box8 = const SizedBox(width: 8, height: 8);
    const box16 = const SizedBox(width: 16, height: 16);

    return Scaffold(
      appBar: AppBar(
        title: Text('New Match Screen'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Course:',
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  box8,
                  // TODO: add existing matches
                  DropdownButton(
                    onChanged: (value) async {
                      setState(() {
                        _selectedValue = value as String;
                      });
                    },
                    value: _selectedValue,
                    items: [
                      DropdownMenuItem(
                        child: Row(
                          children: [
                            Icon(null),
                            box8,
                            Text('Hello World!'),
                          ],
                        ),
                        value: '1',
                      ),
                      DropdownMenuItem(
                        child: Row(
                          children: [
                            Icon(Icons.add_circle_outline),
                            box8,
                            Text('New Course!'),
                          ],
                        ),
                        value: 'new-course',
                      ),
                    ],
                  ),
                ],
              ),
              if (_selectedValue == 'new-course') ...[
                Form(
                  key: _formKey,
                  child: Card(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      width: double.infinity,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            focusNode: _focusNode,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value == null)
                                return 'Course Name cannot be null (how\'d that happen?)';
                              if (value.isEmpty)
                                return 'Course Name cannot be empty';
                            },
                            decoration: InputDecoration(
                              labelText: 'Course Name',
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: TextField(
                                  enabled: false,
                                  controller: _holeController,
                                  decoration: InputDecoration(
                                      labelText: 'Number of Holes'),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  _changeFocus();
                                  var value =
                                      int.tryParse(_holeController.text);

                                  if (value != null && value > 1) {
                                    value--;
                                    setState(() {
                                      _holeController.text = value.toString();
                                    });
                                  }
                                },
                                icon: Icon(Icons.remove),
                              ),
                              IconButton(
                                onPressed: () {
                                  _changeFocus();
                                  var value =
                                      int.tryParse(_holeController.text);

                                  if (value != null && value < _MAX_HOLES) {
                                    value++;
                                    setState(() {
                                      _holeController.text = value.toString();
                                    });
                                  }
                                },
                                icon: Icon(Icons.add),
                              ),
                            ],
                          ),
                          box8,
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(
                                int.parse(_holeController.text),
                                (index) => Card(
                                  color: Colors.amberAccent,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(8, 16, 8, 0),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Hole ${index + 1}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline6,
                                        ),
                                        IconButton(
                                            onPressed: () {
                                              _changeFocus();
                                              if (_holes[index] < 10) {
                                                setState(() {
                                                  _holes[index]++;
                                                });
                                              }
                                            },
                                            icon: Icon(Icons.add)),
                                        Text('PAR'),
                                        Text(_holes[index].toString()),
                                        IconButton(
                                            onPressed: () {
                                              _changeFocus();
                                              if (_holes[index] > 1) {
                                                setState(() {
                                                  _holes[index]--;
                                                });
                                              }
                                            },
                                            icon: Icon(Icons.remove)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
              box16,
              Row(
                children: [
                  Text(
                    'Date:',
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  box8,
                  GestureDetector(
                    onTap: () async {
                      _changeFocus();
                      final result = await showDatePicker(
                        context: context,
                        initialDate: _selectedDateTime,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100, 12, 31),
                      );

                      if (result != null) {
                        setState(() {
                          _selectedDateTime = DateTime(
                            result.year,
                            result.month,
                            result.day,
                            _selectedDateTime.hour,
                            _selectedDateTime.minute,
                          );
                        });
                      }
                    },
                    child: Chip(
                      label:
                          Text(utils.dateFormatter.format(_selectedDateTime)),
                    ),
                  ),
                  box8,
                  GestureDetector(
                    onTap: () async {
                      _changeFocus();
                      final result = await showTimePicker(
                          context: context,
                          initialTime:
                              TimeOfDay.fromDateTime(_selectedDateTime));

                      if (result != null) {
                        setState(() {
                          _selectedDateTime = DateTime(
                            _selectedDateTime.year,
                            _selectedDateTime.month,
                            _selectedDateTime.day,
                            result.hour,
                            result.minute,
                          );
                        });
                      }
                    },
                    child: Chip(
                      label:
                          Text(utils.timeFormatter.format(_selectedDateTime)),
                    ),
                  ),
                ],
              ),
              box16,
              ElevatedButton(
                onPressed: () {
                  _focusNode.unfocus();
                  print('onPressed w/ value: $_selectedValue');
                  if (_selectedValue == 'new-course') {
                    if (!_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(SnackBar(
                          content: Text('You must provide a Course Name!'),
                        ));
                      return;
                    }
                    final name = _nameController.text;
                    final pars = _holes
                        .getRange(0, int.parse(_holeController.text))
                        .toList();
                    var course = Course('<placeholder>', name, pars);
                    course = FirebaseHelper.createCourse(course).item1;

                    final match = Match(
                      id: '<placeholder>',
                      course: course,
                      datetime: _selectedDateTime,
                      players: [
                        FirebaseHelper.getUserId()!,
                      ],
                    );

                    FirebaseHelper.createMatch(match);
                  }
                },
                child: Text('Submit'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32.0)),
                  textStyle: Theme.of(context).textTheme.headline5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _changeFocus() {
    if (_focusNode.hasFocus) {
      _formKey.currentState?.validate();
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _nameController.dispose();
    _holeController.dispose();
    _focusNode.dispose();
  }
}
