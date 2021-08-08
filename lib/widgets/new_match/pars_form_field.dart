import 'package:flutter/material.dart';

const _DEFAULT_PAR = 3;
const _DEFAULT_HOLES = 18;
const _MAX_HOLES = 36;
const _MIN_HOLES = 1;
const _MAX_PAR = 10;
const _MIN_PAR = 1;

class ParsFormField extends FormField<List<int>> {
  @override
  _ParsFormFieldState createState() => _ParsFormFieldState();

  ParsFormField({
    FormFieldSetter<List<int>>? onSaved,
    FormFieldValidator<List<int>>? validator,
    bool autovalidate = false,
    AutovalidateMode? autovalidateMode,
  }) : super(
            onSaved: onSaved,
            validator: validator,
            initialValue: List.generate(_DEFAULT_HOLES, (_) => _DEFAULT_PAR),
            autovalidateMode: autovalidateMode,
            builder: (FormFieldState<List<int>> state) {
              final holes = state.value;
              if (holes == null) return Text(':(');

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller:
                              (state as _ParsFormFieldState)._holeController,
                          enabled: false,
                          decoration:
                              InputDecoration(labelText: 'Number of Holes'),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (holes.length > _MIN_HOLES) {
                            holes.removeLast();
                            state.didChange(holes);
                          }
                        },
                        icon: Icon(Icons.remove),
                      ),
                      IconButton(
                        onPressed: () {
                          if (holes.length < _MAX_HOLES) {
                            holes.add(_DEFAULT_PAR);
                            state.didChange(holes);
                          }
                        },
                        icon: Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8, height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        state.value?.length ?? 0,
                        (index) => Card(
                          color: Colors.amberAccent,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
                            child: Column(
                              children: [
                                Text(
                                  'Hole ${index + 1}',
                                  style: Theme.of(state.context)
                                      .textTheme
                                      .headline6,
                                ),
                                IconButton(
                                    onPressed: () {
                                      // Increase PAR for this hole
                                      if (holes[index] < _MAX_PAR) {
                                        holes[index]++;
                                        state.didChange(holes);
                                      }
                                    },
                                    icon: Icon(Icons.add)),
                                Text('PAR'),
                                Text(holes[index].toString()),
                                IconButton(
                                    onPressed: () {
                                      // Decrease PAR for this hole
                                      if (holes[index] > _MIN_PAR) {
                                        holes[index]--;
                                        state.didChange(holes);
                                      }
                                    },
                                    icon: Icon(Icons.remove)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            });
}

class _ParsFormFieldState extends FormFieldState<List<int>> {
  late final TextEditingController _holeController;

  @override
  void initState() {
    super.initState();
    _holeController = TextEditingController(text: value?.length.toString());
  }

  @override
  void didChange(List<int>? value) {
    super.didChange(value);
    final length = value?.length;
    if (length != null) {
      _holeController.text = length.toString();
    }
  }

  @override
  void dispose() {
    _holeController.dispose();
    super.dispose();
  }
}
