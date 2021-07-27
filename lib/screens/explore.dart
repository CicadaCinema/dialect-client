import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'dart:html' as html;

import 'package:http/http.dart' as http;
import 'package:like_button/like_button.dart';

// https://stackoverflow.com/a/66879350
// these changes were made for prototyping purposes

class DialectServerResponse {
  final List<dynamic> contents;
  final List<dynamic> paths;
  final List<dynamic> ids;

  DialectServerResponse(this.contents, this.paths, this.ids);

  DialectServerResponse.fromJson(Map<String, dynamic> json)
      : contents = json['Contents'],
        paths = json['Paths'],
        ids = json['Ids'];

  Map<String, dynamic> toJson() => {
        'Contents': contents,
        'Paths': paths,
        'Ids': ids,
      };
}

class DialectPost {
  final String text;
  final int realId;
  final int depth;

  const DialectPost(this.text, this.realId, this.depth);
}

class ExplorePage extends StatefulWidget {
  ExplorePage({Key? key}) : super(key: key);

  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late TextEditingController _controller;
  bool _postShown = false;
  String _displayedText = "Send a note to receive one back.";
  int? _selectedPost;
  late String _errorText;
  bool _showErrorText = false;
  bool _errorMessage = false;
  bool _infoMessage = true;
  bool _isReplying = false;
  bool _canVote = false;
  String _clientCaptcha = "";
  static const _API_ENDPOINT = kDebugMode ? "localhost:8080" : "dialect.vercel.app";
  late DialectServerResponse _serverResponse;
  final List<DialectPost> _allPosts = <DialectPost>[];

  Future<bool> onLikeButtonTapped(bool isLiked) async {
    if (_canVote) {
      _canVote = false;
      http.post(
        kDebugMode ? Uri.http(_API_ENDPOINT, "/api/vote") : Uri.https(_API_ENDPOINT, "/api/vote"),
        body: _selectedPost!.toString(),
        headers: kDebugMode ? {"x-real-ip": "1.2.3.4", "vote-action": "like"} : {"vote-action": "like"},
      );
      return true;
    } else {
      return isLiked;
    }
  }

  Future<bool> onDislikeButtonTapped(bool isLiked) async {
    if (_canVote) {
      _canVote = false;
      http.post(
        kDebugMode ? Uri.http(_API_ENDPOINT, "/api/vote") : Uri.https(_API_ENDPOINT, "/api/vote"),
        body: _selectedPost!.toString(),
        headers: kDebugMode ? {"x-real-ip": "1.2.3.4", "vote-action": "dislike"} : {"vote-action": "dislike"},
      );
      return true;
    } else {
      return isLiked;
    }
  }

  // TODO: try to avoid using IntrinsicHeight somehow since it's inefficient...
  // ... or something
  // designing this widget has been such a pain
  // CARD????
  // also see this
  // https://pub.dev/packages/flutter_simple_treeview
  // ^^ probably won't help since that's not quite the layout needed
  /* original parameters for ListTile:
  tileColor: selected ? Colors.teal[100] : (shadeDark ? Colors.grey[200] : null),
  hoverColor: Colors.teal[50],
  issue:
  https://github.com/flutter/flutter/issues/86584
  this also has the ugly side effect of overflowing the original hover indicator of
  ListTile when the user scrolls fast
   */

  Widget postTile(DialectPost postContent, int postId) {
    bool isSelected = _selectedPost == postContent.realId;
    bool isShadedDark = postId % 2 == 0;
    bool isOP = postId == 0;

    List<Widget> myList = List.filled(
        postContent.depth,
        VerticalDivider(
          thickness: 3,
          color: Colors.teal[800],
        ),
        growable: true);
    myList.add(
      Expanded(
        child: Padding(
          padding: EdgeInsets.all(
            4,
          ),
          child: Text(
            postContent.text,
            style: TextStyle(
              fontWeight: isOP ? FontWeight.bold : null,
            ),
          ),
        ),
      ),
    );
    if (isSelected) {
      myList.add(
        Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.keyboard_return, color: Colors.teal),
        ),
      );
    }
    return Container(
      color: isSelected ? Colors.teal[100] : (isShadedDark ? Colors.grey[200] : null),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: Colors.teal[100],
          hoverColor: Colors.teal[50],
          onTap: () {
            setState(() {
              _selectedPost = (_selectedPost == postContent.realId) ? null : postContent.realId;
              _isReplying = _selectedPost != null;
            });
          },
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: myList),
          ),
        ),
      ),
    );
  }

  void postResponse(var value) {
    // throw away the captcha token
    _clientCaptcha = "";
    setState(
      () {
        _errorMessage = value.statusCode != 200;
        _postShown = !_errorMessage;
        _selectedPost = null;
        // everything is fine - no errors
        if (!_errorMessage) {
          _canVote = true;
          _controller.clear();
          _infoMessage = false;
          _allPosts.clear();

          _serverResponse = DialectServerResponse.fromJson(jsonDecode(value.body));
          for (var i = 0; i < _serverResponse.paths.length; i++) {
            // unicode has to be decoded from bytes
            _allPosts.add(DialectPost(utf8.decode(_serverResponse.contents[i].codeUnits), _serverResponse.ids[i], "/".allMatches(_serverResponse.paths[i]).length));
          }
        } else {
          _displayedText = value.body;
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    html.window.onMessage.listen((event) {
      // load the captcha response token
      _clientCaptcha = event.data;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Spacer(flex: 12),
          _infoMessage
              ? SelectableText(
                  _displayedText,
                  style: TextStyle(
                    fontSize: 28,
                    color: _errorMessage ? Colors.red : null,
                  ),
                )
              : Container(
                  height: min(MediaQuery.of(context).size.height * 0.4, 6 * 50 + 16),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _allPosts.length,
                    itemBuilder: (BuildContext context, int index) {
                      return postTile(_allPosts[index], index);
                    },
                  ),
                ),
          Spacer(flex: 3),
          Row(
            children: [
              Spacer(flex: 2),
              Visibility(
                child: LikeButton(
                  size: 70,
                  onTap: onDislikeButtonTapped,
                  circleColor: CircleColor(
                    start: Color(0xff00ddff),
                    end: Color(0xff0099cc),
                  ),
                  bubblesColor: BubblesColor(
                    dotPrimaryColor: Color(0xff33b5e5),
                    dotSecondaryColor: Color(0xff0099cc),
                  ),
                  likeBuilder: (bool isLiked) {
                    return Icon(
                      isLiked ? Icons.thumb_down : Icons.thumb_down_outlined,
                      color: isLiked ? Colors.blueAccent : Colors.grey,
                      size: 70,
                    );
                  },
                ),
                visible: _canVote && _postShown && _selectedPost != null,
              ),
              Spacer(flex: 3),
              Visibility(
                child: LikeButton(
                  size: 70,
                  onTap: onLikeButtonTapped,
                  likeBuilder: (bool isLiked) {
                    return Icon(
                      isLiked ? Icons.favorite : Icons.favorite_outline,
                      color: isLiked ? Colors.pinkAccent : Colors.grey,
                      size: 70,
                    );
                  },
                ),
                visible: _canVote && _postShown && _selectedPost != null,
              ),
              Spacer(flex: 2),
            ],
          ),
          Spacer(flex: 12),
          TextField(
            controller: _controller,
            maxLength: 140,
            decoration: InputDecoration(
              labelText: "Enter your note",
              errorText: _showErrorText ? _errorText : null,
            ),
          ),
          Spacer(flex: 3),
          Spacer(flex: 1),
          Row(
            //mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(flex: 5),
              OutlinedButton(
                onPressed: () {
                  html.window.open("/recaptcha.html", "new tab", "height=600, width=620,");
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 32),
                  child: Text(
                    "Verify",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              Spacer(flex: 1),
              ElevatedButton(
                onPressed: () {
                  setState(
                    () {
                      if (_controller.text.trim().isEmpty) {
                        _errorText = "Write a note";
                        _showErrorText = true;
                      } else if (_clientCaptcha == "") {
                        _errorText = "Complete verification before posting";
                        _showErrorText = true;
                      } else {
                        _infoMessage = true;
                        _showErrorText = false;
                        _errorMessage = false;
                        _displayedText = "Loading...";
                      }
                    },
                  );
                  if (!_showErrorText) {
                    http.post(kDebugMode ? Uri.http(_API_ENDPOINT, '/api/post') : Uri.https(_API_ENDPOINT, '/api/post'), body: _controller.text.trim(), headers: kDebugMode ? {"x-real-ip": "1.2.3.4", "reply-id": _selectedPost == null ? "" : _selectedPost!.toString(), "captcha-token": _clientCaptcha} : {"reply-id": _selectedPost == null ? "" : _selectedPost!.toString(), "captcha-token": _clientCaptcha}).then(postResponse);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 32),
                  child: Text(
                    _isReplying ? "Reply" : "Submit",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              Spacer(flex: 5),
            ],
          ),
          Spacer(flex: 6),
        ],
      ),
    );
  }
}
