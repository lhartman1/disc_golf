import 'package:flutter/material.dart';

import '../db/firebase_helper.dart';
import '../models/match.dart';
import '../models/user_strokes.dart';
import '../widgets/hole/player_hole_score.dart';

class HoleScreen extends StatelessWidget {
  final Match _match;
  final int initialPage;

  const HoleScreen(
    this._match, {
    Key? key,
    this.initialPage = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = PageController(initialPage: initialPage);
    // Use this to get rid of last hole snackbar message
    controller.addListener(() {
      ScaffoldMessenger.of(context).clearSnackBars();
    });

    final body = StreamBuilder<Match>(
      stream: FirebaseHelper.getMatch(_match.id),
      builder: (context, matchSnapshot) {
        return StreamBuilder<Iterable<UserStrokes>>(
          stream: FirebaseHelper.getUserStrokesForMatch(_match.id),
          builder: (context, userStrokesSnapshot) {
            if (matchSnapshot.connectionState == ConnectionState.waiting ||
                userStrokesSnapshot.connectionState ==
                    ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            final match = matchSnapshot.data;
            final userStrokesIterable = userStrokesSnapshot.data;
            if (match == null || userStrokesIterable == null) {
              return Center(child: Text(':('));
            }

            return PageView.builder(
              scrollDirection: Axis.horizontal,
              controller: controller,
              itemCount: match.course.numHoles,
              itemBuilder: (BuildContext context, int index) {
                return _buildCustomScrollView(
                    context, match, userStrokesIterable, index);
              },
            );
          },
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(_match.course.name),
      ),
      body: body,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'prev_hole',
            mini: true,
            tooltip: 'Move to previous hole',
            onPressed: () {
              final pageNumber = controller.page?.round() ?? 0;
              if (pageNumber > 0) {
                controller.previousPage(
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeIn);
              } else {
                // Go back to scorecard when on the first hole
                Navigator.of(context).pop();
              }
            },
            child: Icon(Icons.arrow_back),
          ),
          SizedBox(
            width: 16,
          ),
          FloatingActionButton.extended(
            heroTag: 'next_hole',
            onPressed: () {
              // Clear existing snackbars on page turn
              final scaffoldMessenger = ScaffoldMessenger.of(context)
                ..clearSnackBars();
              final pageNumber = controller.page?.round() ?? 0;
              if (pageNumber < (_match.course.numHoles - 1)) {
                controller.nextPage(
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeIn);
              } else {
                scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('This is the last hole!')));
              }
            },
            tooltip: 'Move to next hole',
            label: Text('Next Hole'),
            icon: Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }

  SliverList _buildPlayerHoleScores(
    Iterable<UserStrokes> userStrokesIterable,
    Match match,
    int index,
  ) {
    final playerHoleScores = userStrokesIterable.map((e) {
      final isMe = FirebaseHelper.getUserId() == e.user.id;

      return PlayerHoleScore(
        match: match,
        userStrokes: e,
        holeIndex: index,
        isMe: isMe,
      );
    }).toList();

    return SliverList(delegate: SliverChildListDelegate(playerHoleScores));
  }

  CustomScrollView _buildCustomScrollView(
    BuildContext context,
    Match match,
    Iterable<UserStrokes> userStrokesIterable,
    int index,
  ) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          leading: Container(),
          leadingWidth: 0,
          pinned: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'HOLE ',
                    style: Theme.of(context).textTheme.bodyText2,
                  ),
                  Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.headline4,
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    ' PAR ',
                    style: Theme.of(context).textTheme.bodyText2,
                  ),
                  Text(
                    match.course.pars[index].toString(),
                    style: Theme.of(context).textTheme.headline4,
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildPlayerHoleScores(userStrokesIterable, match, index),
        SliverList(
          delegate: SliverChildListDelegate([
            SizedBox(height: 68),
          ]),
        ),
      ],
    );
  }
}
