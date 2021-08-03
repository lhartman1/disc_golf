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

  @override
  void didUpdateWidget(covariant PlayerHoleScore oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldHoleStrokes = oldWidget.userStrokes.strokes[oldWidget.holeIndex];
    final newHoleStrokes = widget.userStrokes.strokes[widget.holeIndex];

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
    final holeStrokes = widget.userStrokes.strokes[widget.holeIndex];
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
            IconButton(
              onPressed: widget.editable && holeStrokes > 0
                  ? () {
                      // Guard against scores less than 0 in case somehow this
                      // widget didn't get rebuilt with onPressed blocking this
                      if (widget.userStrokes.strokes[widget.holeIndex] <= 0)
                        return;

                      widget.userStrokes.strokes[widget.holeIndex]--;
                      FirebaseHelper.updateScore(widget.userStrokes.user.id,
                          widget.userStrokes.strokes, widget.match.id);
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
            IconButton(
              onPressed: widget.editable
                  ? () {
                      widget.userStrokes.strokes[widget.holeIndex]++;
                      FirebaseHelper.updateScore(widget.userStrokes.user.id,
                          widget.userStrokes.strokes, widget.match.id);
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
