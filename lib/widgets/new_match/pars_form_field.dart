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
                  ShaderMask(
                    shaderCallback: (Rect rect) {
                      return LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          if (state.blurStart) Colors.white,
                          Colors.transparent,
                          Colors.transparent,
                          if (state.blurEnd) Colors.white
                        ],
                        stops: [
                          if (state.blurStart) 0.0,
                          0.1,
                          0.9,
                          if (state.blurEnd) 1.0,
                        ],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstOut,
                    child: SingleChildScrollView(
                      controller: state._scrollController,
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
                                        .headline6
                                        ?.copyWith(
                                          // Explicitly make this black
                                          // otherwise Dark theme makes it white
                                          color: Colors.black,
                                        ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      // Increase PAR for this hole
                                      if (holes[index] < _MAX_PAR) {
                                        holes[index]++;
                                        state.didChange(holes);
                                      }
                                    },
                                    icon: Icon(Icons.add),
                                    color: Colors.black,
                                  ),
                                  Text(
                                    'PAR\n${holes[index]}',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(state.context)
                                        .textTheme
                                        .bodyText2
                                        ?.copyWith(
                                          color: Colors.black,
                                        ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      // Decrease PAR for this hole
                                      if (holes[index] > _MIN_PAR) {
                                        holes[index]--;
                                        state.didChange(holes);
                                      }
                                    },
                                    icon: Icon(Icons.remove),
                                    color: Colors.black,
                                  ),
                                ],
                              ),
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
  late final ScrollController _scrollController;
  var blurStart = false;
  var blurEnd = true;

  @override
  void initState() {
    super.initState();
    _holeController = TextEditingController(text: value?.length.toString());
    _scrollController = ScrollController();
    _scrollController.addListener(_checkScrollControllerForBlur);
  }

  @override
  Widget build(BuildContext context) {
    // Check scroll controller after the widget is built. Checking afterwards is
    // important for getting the correct scroll extents.
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _checkScrollControllerForBlur();
    });
    return super.build(context);
  }

  void _checkScrollControllerForBlur() {
    final pos = _scrollController.position;

    // Blur start if the scroll position isn't at the beginning
    final shouldBlurStart = pos.extentBefore != 0.0;
    if (blurStart != shouldBlurStart) {
      setState(() {
        blurStart = shouldBlurStart;
      });
    }

    // Blur end if the scroll position isn't at the end
    final shouldBlurEnd = pos.extentAfter != 0.0;
    if (blurEnd != shouldBlurEnd) {
      setState(() {
        blurEnd = shouldBlurEnd;
      });
    }
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
    _scrollController.dispose();
    super.dispose();
  }
}
