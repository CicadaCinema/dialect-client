import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'dart:ui' as ui;
import 'dart:html';
import 'dart:html' as html;

import 'package:http/http.dart' as http;
import 'package:like_button/like_button.dart';

// https://stackoverflow.com/a/66879350
// these changes were made for prototyping purposes

class ExplorePage extends StatefulWidget {
  ExplorePage({Key? key}) : super(key: key);

  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late TextEditingController _controller;
  bool _postShown = false;
  String _displayedText = "Send a note to receive one back.";
  int? _postId;
  late String _errorText;
  bool _showErrorText = false;
  bool _errorMessage = false;
  bool _canVote = false;
  String _clientCaptcha = "";
  static const _API_ENDPOINT =
      kDebugMode ? "localhost:8080" : "dialect-server.vercel.app";

  // change between:
  // Uri.https.(_API_ENDPOINT
  // Uri.http.(_API_ENDPOINT

  final IFrameElement _iframeElement = IFrameElement();
  late Widget _iframeWidget;

  Future<bool> onLikeButtonTapped(bool isLiked) async {
    if (_canVote) {
      _canVote = false;
      http.post(
        kDebugMode
            ? Uri.http(_API_ENDPOINT, '/api/vote')
            : Uri.https(_API_ENDPOINT, '/api/vote'),
        body: _postId.toString(),
        headers: {'vote-action': 'like'},
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
        kDebugMode
            ? Uri.http(_API_ENDPOINT, '/api/vote')
            : Uri.https(_API_ENDPOINT, '/api/vote'),
        body: _postId.toString(),
        headers: {'vote-action': 'dislike'},
      );
      return true;
    } else {
      return isLiked;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    // write cookie
    //document.cookie = "key=value; max-age=315569260";

    // BEGIN CAPTCHA HELL
    //_iframeElement.height = '500';
    //_iframeElement.width = '500';
    _iframeElement.src = "/recaptcha.html";
    _iframeElement.style.border = 'none';

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'iframeElement',
      (int viewId) => _iframeElement,
    );

    _iframeWidget = HtmlElementView(
      key: UniqueKey(),
      viewType: 'iframeElement',
    );

    html.window.onMessage.listen((event) {
      // load the captcha response token
      _clientCaptcha = event.data;
    });
    // END CAPTCHA HELL
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.05),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Spacer(flex: 4),
          SelectableText(
            _displayedText,
            style: TextStyle(
              fontSize: 28,
              color: _errorMessage ? Colors.red : null,
            ),
          ),
          Spacer(flex: 1),
          Row(
            children: [
              Spacer(flex: 2),
              Visibility(
                child: LikeButton(
                  size: 70,
                  onTap: onDislikeButtonTapped,
                  circleColor: CircleColor(
                      start: Color(0xff00ddff), end: Color(0xff0099cc)),
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
                visible: _postShown,
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
                visible: _postShown,
              ),
              Spacer(flex: 2),
            ],
          ),
          Spacer(flex: 4),
          TextField(
            controller: _controller,
            maxLength: 140,
            onSubmitted: (String value) {
              print('"$value" has length ${value.characters.length}');
            },
            decoration: InputDecoration(
              labelText: "Enter your note",
              errorText: _showErrorText ? _errorText : null,
            ),
          ),
          Spacer(flex: 1),
          OutlinedButton(
            onPressed: () {
              html.window.open('/recaptcha.html', 'new tab');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 32),
              child: Text(
                "Verify",
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
          ),
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
                    _showErrorText = false;
                    _errorMessage = false;
                    _displayedText = "Loading...";
                  }
                },
              );
              if (!_showErrorText) {
                http
                    .post(
                        kDebugMode
                            ? Uri.http(_API_ENDPOINT, '/api/post')
                            : Uri.https(_API_ENDPOINT, '/api/post'),
                        body: _controller.text.trim(),
                        headers: kDebugMode
                            ? {
                                "x-real-ip": "1.2.3.4",
                                "captcha-token": _clientCaptcha
                              }
                            : {"captcha-token": _clientCaptcha})
                    .then(
                      (value) => {
                        // throw away the captcha token
                        _clientCaptcha = "",
                        // DEBUG: response
                        //print(value.headers.toString()),
                        //print(value.statusCode.toString()),
                        setState(
                          () {
                            _errorMessage = value.statusCode != 200;
                            // unicode has to be decoded from bytes
                            _displayedText = _errorMessage
                                ? /*"Error code ${value.statusCode}\n${value.body}"*/ value
                                    .body
                                : utf8.decode(value.body.codeUnits);
                            _postShown = !_errorMessage;
                          },
                        ),
                        // everything is fine - no errors
                        if (!_errorMessage)
                          {
                            _postId = int.parse(value.headers["post-id"]!),
                            _canVote = true,
                            _controller.clear(),
                          }
                      },
                    );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 32),
              child: Text(
                "Submit",
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          Spacer(flex: 2),
        ],
      ),
    );
  }
}
