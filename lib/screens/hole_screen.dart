import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../db/firebase_helper.dart';
import '../models/match.dart';
import '../models/user_strokes.dart';
import '../widgets/hole/player_hole_score.dart';

class HoleScreen extends StatelessWidget {
  final Match match;

  const HoleScreen({Key? key, required this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = PageController(initialPage: 0);
    // Use this to get rid of last hole snackbar message
    controller.addListener(() {
      ScaffoldMessenger.of(context).clearSnackBars();
    });

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(match.course.name),
      ),
      body: PageView.builder(
        scrollDirection: Axis.horizontal,
        controller: controller,
        itemCount: match.course.numHoles,
        itemBuilder: (BuildContext context, int index) {
          return buildCustomScrollView(context, index);
        },
      ),
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
              if (pageNumber < (match.course.numHoles - 1)) {
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

  StreamBuilder<QuerySnapshot<Map<String, dynamic>>> buildStreamBuilder(
      int index) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .doc(match.id)
          .collection('scorecard')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          final w = Center(
            child: CircularProgressIndicator(),
          );
          return SliverList(delegate: SliverChildListDelegate([w]));
        }
        final playerData = snapshot.data?.docs;
        if (snapshot.hasData && playerData != null) {
          final List<Widget> playerTiles;

          playerTiles = playerData.map((snapshot) {
            final userStrokes = UserStrokes.fromJson(snapshot.data());
            final isMe = (FirebaseHelper.getUserId() ?? '<unknown>') ==
                userStrokes.user.id;

            return PlayerHoleScore(
              match: match,
              userStrokes: userStrokes,
              holeIndex: index,
              isMe: isMe,
            );
          }).toList();

          return SliverList(
            delegate: SliverChildListDelegate(playerTiles),
          );
        }
        final w = Text(':(');
        return SliverList(delegate: SliverChildListDelegate([w]));
      },
    );
  }

  CustomScrollView buildCustomScrollView(BuildContext context, int index) {
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
        buildStreamBuilder(index),
        SliverList(
          delegate: SliverChildListDelegate([
            SizedBox(height: 68),
          ]),
        ),
      ],
    );
  }
}
