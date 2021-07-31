import 'package:flutter/material.dart';

import '../../db/firebase_helper.dart';
import '../../models/match.dart';
import '../../models/user_strokes.dart';

class PlayerHoleScore extends StatefulWidget {
  final Match match;
  final UserStrokes userStrokes;
  final int holeIndex;
  final bool isMe;

  const PlayerHoleScore({
    Key? key,
    required this.match,
    required this.userStrokes,
    required this.holeIndex,
    required this.isMe,
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

    if (!widget.isMe && oldHoleStrokes != newHoleStrokes) {
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

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          // child: Icon(Icons.person),
          backgroundImage:
              NetworkImage(widget.userStrokes.user.imageUri.toString()),
        ),
        title: Text(widget.userStrokes.user.username),
        subtitle: Text(widget.userStrokes.getScoreSummary(widget.match)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: widget.isMe && holeStrokes > 0
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
              icon: Icon(widget.isMe ? Icons.remove : null),
              splashRadius: Material.defaultSplashRadius / 1.5,
              tooltip: widget.isMe ? 'Decrement score' : null,
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
              onPressed: widget.isMe
                  ? () {
                      widget.userStrokes.strokes[widget.holeIndex]++;
                      FirebaseHelper.updateScore(widget.userStrokes.user.id,
                          widget.userStrokes.strokes, widget.match.id);
                    }
                  : null,
              icon: Icon(widget.isMe ? Icons.add : null),
              splashRadius: Material.defaultSplashRadius / 1.5,
              tooltip: widget.isMe ? 'Increment score' : null,
            ),
          ],
        ),
      ),
    );
  }
}
