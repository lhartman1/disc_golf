import 'package:flutter/material.dart';

import 'pars_form_field.dart';

class NewCourseCard extends StatefulWidget {
  final Function(String?) onNameFieldSaved;
  final Function(List<int>?) onParsFieldSaved;

  const NewCourseCard({
    Key? key,
    required this.onNameFieldSaved,
    required this.onParsFieldSaved,
  }) : super(key: key);

  @override
  _NewCourseCardState createState() => _NewCourseCardState();
}

class _NewCourseCardState extends State<NewCourseCard> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: EdgeInsets.all(16),
        width: double.infinity,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null)
                  return 'Course Name cannot be null (how\'d that happen?)';
                if (value.isEmpty) return 'Course Name cannot be empty';
              },
              decoration: InputDecoration(
                labelText: 'Course Name',
              ),
              onSaved: widget.onNameFieldSaved,
            ),
            ParsFormField(onSaved: widget.onParsFieldSaved),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
