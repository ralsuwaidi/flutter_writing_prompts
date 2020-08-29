import 'reddit.dart';
import 'story.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Add this line.
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Name Generator',
      theme: ThemeData.dark(),
      home: RedditWritingPrompts(),
    );
  }
}

class RedditWritingPrompts extends StatefulWidget {
  @override
  _RedditWritingPromptsState createState() => _RedditWritingPromptsState();
}

class _RedditWritingPromptsState extends State<RedditWritingPrompts> {
  String _period = 'week';
  Future<List<RedditPost>> _listFuture;
  List<RedditPost> _favPostList;
  @override
  void initState() {
    _listFuture = RedditPost().updateRedditList('week');
    _loadCounter();
    super.initState();
  }

  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return _buildWP(_listFuture);
  }

  Widget _buildWP(Future<List<RedditPost>> wpList) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: Text('  WP: ' +
            _period.replaceFirst(_period[0], _period[0].toUpperCase())),
        actions: [
          IconButton(
              icon: Icon(Icons.favorite_border),
              onPressed: () {
                setState(() {
                  _period = 'Saved';
                  _listFuture = RedditPost().getSavedPostList();
                });
              }),
          PopupMenuButton<int>(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 1,
                child: Text("Daily"),
              ),
              PopupMenuItem(
                value: 2,
                child: Text("Weekly"),
              ),
              PopupMenuItem(
                value: 3,
                child: Text("Monthly"),
              ),
            ],
            onSelected: (value) {
              if (value == 1) {
                _period = 'day';
                _select(_period);
              }
              if (value == 2) {
                _period = 'week';
                _select(_period);
              }
              if (value == 3) {
                _period = 'month';
                _select(_period);
              }

              Fluttertoast.showToast(
                  msg: 'Top of the ' + _period,
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 16.0);
            },
          )
        ],
      ),
      body: FutureBuilder(
          future: wpList,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              return _buildWPList(snapshot.data);
            }

            return Center(
              child: CircularProgressIndicator(),
            );
          }),
    );
  }

  // build list of stories
  Widget _buildWPList(List<RedditPost> postList) {
    return Scrollbar(
        child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: postList.length * 2,
            itemBuilder: (BuildContext _context, int i) {
              if (i.isOdd) {
                return Divider();
              }
              final int index = i ~/ 2;

              return _buildRow(postList[index], index, postList);
            }));
  }

  void _updateSavedList(RedditPost post) {
    setState(() {
      if (RedditPost().isSaved(_favPostList, post)) {
        _favPostList.remove(post);
      } else {
        _favPostList.add(post);
      }
    });
  }

  /// story widget after it is clicked
  Widget _buildStory(RedditPost post) {
    final theStory = RedditPost().getStory(post.url);
    return FutureBuilder(
      future: theStory,
      builder: (_context, snapshot) {
        if (snapshot.hasData) {
          return _storyTextWidget(snapshot.data, post);
        }

        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  /// return story as a widget inside a dragable sheet
  /// under story is the favourite widget
  Widget _storyTextWidget(String story, RedditPost post) {
    return NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (overscroll) {
          overscroll.disallowGlow();
          return null;
        },
        child: SizedBox.expand(
            child: DraggableScrollableSheet(
                initialChildSize: 1,
                builder: (context, scrollController) {
                  return Story(
                    story: story,
                    post: post,
                    onPress: _updateSavedList,
                    favPostList: _favPostList,
                  );
                })));
  }

  /// one row from list of prompts
  Widget _buildRow(RedditPost post, int index, postList) {
    return Container(
        child: ListTile(
      title: Text(
        post.title.replaceAll('[WP] ', ''),
      ),
      subtitle: Column(
        children: <Widget>[
          Row(
            children: [
              if (post.awards != 0) _printAwards(post.awards, size: 12),
              // if (_savedUrlList.contains(post.url)) Icon(Icons.favorite,size: 15,)
            ],
          )
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
      onTap: () {
        _pushStory(postList[index]);
      },
    ));
  }

  /// page with story and large header
  void _pushStory(RedditPost post) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.grey[900],
            ),
            child: Scaffold(
              // appBar: AppBar(
              //   title: Text("Story"),
              // ),
              // body: _buildStory(_redditList[index].url),
              body: NestedScrollView(
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      expandedHeight: 200.0,
                      floating: false,
                      pinned: false,
                      backgroundColor: Colors.grey[850],
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                            margin: const EdgeInsets.fromLTRB(15, 80, 15, 9),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  post.title,
                                  style: TextStyle(fontSize: 14),
                                ),
                                if (post.awards != 0)
                                  _printAwards(post.awards, size: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    RichText(
                                      text: TextSpan(
                                          text: 'Score: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                          children: <TextSpan>[
                                            TextSpan(
                                                text: post.score.toString(),
                                                style: TextStyle(
                                                    color: post.score >
                                                            10000 // high score
                                                        ? Color(
                                                            0xFFff5733) // upvote color
                                                        : null,
                                                    fontWeight:
                                                        FontWeight.normal)),
                                          ]),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                          text: 'Date: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                          children: <TextSpan>[
                                            TextSpan(
                                                text: DateFormat('dd-MM-yyyy ')
                                                    .format(DateTime
                                                        .fromMillisecondsSinceEpoch(
                                                            post.date.toInt() *
                                                                1000))
                                                    .toString(),
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal)),
                                          ]),
                                    ),
                                  ],
                                ),
                              ],
                            )),
                      ),
                    ),
                  ];
                },
                body: Center(
                  child: _buildStory(post),
                ),
              ),
            ));
      },
    ));
  }

  Widget _printAwards(int awardNumber, {double size = 15}) {
    if (awardNumber == 1) {
      return Row(children: <Widget>[
        Icon(Icons.stars, size: size, color: Colors.yellow)
      ]);
    } else {
      return Row(children: <Widget>[
        Icon(
          Icons.stars,
          size: size,
          color: Colors.yellow,
        ),
        Text(
          awardNumber.toString(),
          style: TextStyle(fontSize: size),
        )
      ]);
    }
  }

  void _select(String period) {
    setState(() {
      _listFuture = RedditPost().updateRedditList(period);
    });
  }

  //Loading counter value on start
  _loadCounter() async {
    List<RedditPost> savedList = await RedditPost().getSavedPostList();
    setState(() {
      _favPostList = savedList;
    });
  }
}
