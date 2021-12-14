import 'package:flutter/material.dart';

import '../../db/firebase_helper.dart';
import '../../models/match.dart';
import '../../models/user_strokes.dart';

class PlayerHoleScore extends StatefulWidget {
  final Match match;
  final UserStrokes userStrokes;
  final int holeIndex;
  final bool editable;

  const PlayerHoleScore({
    Key? key,
    required this.match,
    required this.userStrokes,
    required this.holeIndex,
    required this.editable,
  }) : super(key: key);

  @override
  _PlayerHoleScoreState createState() => _PlayerHoleScoreState();
}

class _PlayerHoleScoreState extends State<PlayerHoleScore> {
  var orangeText = false;

  // Provide getters for some widget variables to improve readability
  int get holeIndex => widget.holeIndex;

  List<int> get strokes => widget.userStrokes.strokes;

  int get holeStrokes => strokes[holeIndex];

  set holeStrokes(int newValue) => strokes[holeIndex] = newValue;

  List<int> get pars => widget.match.course.pars;

  int get par => pars[holeIndex];

  @override
  void didUpdateWidget(covariant PlayerHoleScore oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldHoleStrokes = oldWidget.userStrokes.strokes[oldWidget.holeIndex];
    final newHoleStrokes = strokes[holeIndex];

    // FIXME: this is not showing orange text for offline players
    if (!widget.editable && oldHoleStrokes != newHoleStrokes) {
      orangeText = true;
      Future.delayed(Duration(milliseconds: 500), () {
        setState(() {
          orangeText = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUri = widget.userStrokes.user.imageUri;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: imageUri == null ? Icon(Icons.person) : null,
          backgroundImage:
              imageUri == null ? null : NetworkImage(imageUri.toString()),
        ),
        title: Text(widget.userStrokes.user.username),
        subtitle: Text(widget.userStrokes.getScoreSummary(widget.match)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Button to decrement score
            IconButton(
              onPressed: widget.editable// && holeStrokes > 0
                  ? () {
                      // Guard against scores less than 0 in case somehow this
                      // widget didn't get rebuilt with onPressed blocking this
                      if (holeStrokes < 0) return;

                      // Set to (par - 1) if the score is 0, otherwise decrement.
                      if (holeStrokes == 0) {
                        holeStrokes = pars[holeIndex] - 1;
                      } else {
                        holeStrokes--;
                      }

                      FirebaseHelper.updateScore(
                          widget.userStrokes.user.id, strokes, widget.match.id);
                    }
                  : null,
              icon: Icon(widget.editable ? Icons.remove : null),
              splashRadius: Material.defaultSplashRadius / 1.5,
              tooltip: widget.editable ? 'Decrement score' : null,
            ),
            AnimatedDefaultTextStyle(
              child: Text('$holeStrokes'),
              style: orangeText
                  ? Theme.of(context)
                      .textTheme
                      .headline5!
                      .copyWith(color: Theme.of(context).primaryColor)
                  : Theme.of(context).textTheme.headline5!,
              duration:
                  orangeText ? Duration.zero : Duration(milliseconds: 500),
            ),
            // Button to increment score
            IconButton(
              onPressed: widget.editable
                  ? () {
                      // Set to par if the score is 0, otherwise increment.
                      if (holeStrokes == 0) {
                        holeStrokes = pars[holeIndex];
                      } else {
                        holeStrokes++;
                      }

                      FirebaseHelper.updateScore(
                          widget.userStrokes.user.id, strokes, widget.match.id);
                    }
                  : null,
              icon: Icon(widget.editable ? Icons.add : null),
              splashRadius: Material.defaultSplashRadius / 1.5,
              tooltip: widget.editable ? 'Increment score' : null,
            ),
          ],
        ),
      ),
    );
  }
}
