import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../db/firebase_helper.dart';
import '../models/course.dart';
import '../models/match.dart';
import '../utils/utils.dart' as utils;
import '../widgets/new_match/new_course_card.dart';

class NewMatchScreen extends StatefulWidget {
  const NewMatchScreen({Key? key}) : super(key: key);

  @override
  _NewMatchScreenState createState() => _NewMatchScreenState();
}

class _NewMatchScreenState extends State<NewMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedValue;
  late DateTime _selectedDateTime;
  var _isLoading = false;
  String? _newCourseName;
  List<int>? _newCoursePars;

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
          child: Form(
            key: _formKey,
            child: StreamBuilder<Iterable<Course>>(
              stream: FirebaseHelper.getCourses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final existingCourses = snapshot.data;
                if (existingCourses == null) {
                  return Center(child: Text(':('));
                }
                return Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Course:',
                          style: Theme.of(context).textTheme.headline5,
                        ),
                        box8,
                        IntrinsicWidth(
                          child: DropdownButtonFormField(
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value == null) return 'Select a course';
                            },
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
                                    Icon(Icons.add_circle_outline),
                                    box8,
                                    Text('New Course!'),
                                  ],
                                ),
                                value: 'new-course',
                              ),
                              ...existingCourses.map(
                                (e) {
                                  print(e.name);
                                  return DropdownMenuItem(
                                    child: Text(e.name),
                                    value: e.id,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_selectedValue == 'new-course') ...[
                      box16,
                      NewCourseCard(
                        onNameFieldSaved: (newName) {
                          _newCourseName = newName;
                        },
                        onParsFieldSaved: (newPars) {
                          _newCoursePars = newPars;
                        },
                      ),
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
                            label: Text(
                                utils.dateFormatter.format(_selectedDateTime)),
                          ),
                        ),
                        box8,
                        GestureDetector(
                          onTap: () async {
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
                            label: Text(
                                utils.timeFormatter.format(_selectedDateTime)),
                          ),
                        ),
                      ],
                    ),
                    box16,
                    ElevatedButton(
                      onPressed: () => _submit(existingCourses),
                      child: _isLoading
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(
                                color: Theme.of(context).accentColor,
                              ),
                            )
                          : Text('Submit'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0)),
                        textStyle: Theme.of(context).textTheme.headline5,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _submit(Iterable<Course> courseIterable) {
    print('debug');
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    final Course course;

    // New match with new course
    if (_selectedValue == 'new-course') {
      // There shouldn't be a valid path for either of these to be null, but
      // check just in case
      if (_newCourseName == null || _newCoursePars == null) {
        print('Error: _newCourseName and _newCoursePars must not be null');
        return;
      }

      final tempCourse =
          Course('<placeholder>', _newCourseName!, _newCoursePars!);

      // Update course to get correct id
      course = FirebaseHelper.createCourse(tempCourse).item1;
    }
    // New match with existing course
    else {
      final tempCourse = courseIterable
          .firstWhereOrNull((element) => element.id == _selectedValue);
      if (tempCourse == null) {
        print('Could not find course with id "$_selectedValue"');
        return;
      }
      course = tempCourse;
    }

    final match = Match(
      id: '<placeholder>',
      course: course,
      datetime: _selectedDateTime,
      players: [
        FirebaseHelper.getUserId()!,
      ],
    );

    final result = FirebaseHelper.createMatch(match);

    result.item2.then((_) {
      Navigator.of(context).pop(result.item1);
    }).catchError((err) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(err),
        ));
      print(err);
      setState(() {
        _isLoading = false;
      });
    });
  }
}
