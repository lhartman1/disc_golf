import 'package:flutter/material.dart';

class HoleScreen extends StatelessWidget {
  final String title;

  const HoleScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            title: Text(
              title,
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.person_add_alt),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.qr_code),
              ),
            ],
            bottom: PreferredSize(
                child: Container(
                  height: kToolbarHeight,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(
                      horizontal: AppBarTheme.of(context).titleSpacing ??
                          NavigationToolbar.kMiddleSpacing),
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('HOLE '),
                          Text(
                            '2',
                            style: Theme.of(context).textTheme.headline4,
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context)
                            ..clearSnackBars()
                            ..showSnackBar(SnackBar(
                                content: Text('Long press to edit PAR')));
                        },
                        onLongPress: () {
                          ScaffoldMessenger.of(context)
                            ..clearSnackBars()
                            ..showSnackBar(SnackBar(content: Text('TODO')));
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(' PAR '),
                            Text(
                              '4',
                              style: Theme.of(context).textTheme.headline4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                preferredSize: Size.fromHeight(kToolbarHeight)),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              buildListTile(context, 'Luke', '-1 (6)', 3, true),
              buildListTile(context, 'Terry', '0 (7)', 4, false),
              buildListTile(context, 'Terry', '0 (7)', 4, false),
              buildListTile(context, 'Terry', '0 (7)', 4, false),
              buildListTile(context, 'Terry', '0 (7)', 4, false),
              buildListTile(context, 'Terry', '0 (7)', 4, false),
              buildListTile(context, 'Terry', '0 (7)', 4, false),
              buildListTile(context, 'Terry', '0 (7)', 4, false),
              buildListTile(context, 'Terry', '0 (7)', 4, false),
              buildListTile(context, 'Terry', '0 (7)', 4, false),
              SizedBox(height: 68),
            ]),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'prev_hole',
            mini: true,
            tooltip: 'Move to previous hole',
            onPressed: () {},
            child: Icon(Icons.arrow_back),
          ),
          SizedBox(
            width: 16,
          ),
          FloatingActionButton.extended(
            heroTag: 'next_hole',
            onPressed: null,
            tooltip: 'Move to next hole',
            label: Text('Next Hole'),
            icon: Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }

  Widget buildListTile(
    BuildContext context,
    String name,
    String overallScore,
    int score,
    bool isMe,
  ) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Text(name),
        subtitle: Text(overallScore),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: isMe ? () {} : null,
              icon: Icon(isMe ? Icons.remove : null),
              splashRadius: Material.defaultSplashRadius / 1.5,
              tooltip: isMe ? 'Decrement score' : null,
            ),
            Text(
              '$score',
              style: Theme.of(context).textTheme.headline5,
            ),
            IconButton(
              onPressed: isMe ? () {} : null,
              icon: Icon(isMe ? Icons.add : null),
              splashRadius: Material.defaultSplashRadius / 1.5,
              tooltip: isMe ? 'Increment score' : null,
            ),
          ],
        ),
      ),
    );
  }
}
