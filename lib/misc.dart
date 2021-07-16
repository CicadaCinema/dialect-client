import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'dart:html' as html;

// generic dialog box
Future<void> showDialogBox(
    String title, String message, BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return PointerInterceptor(
        child: AlertDialog(
          title: SelectableText(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                SelectableText(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('OK'),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    },
  );
}

// single-use dialog box for additional info about the software
Future<void> showAboutDialogBox(BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return PointerInterceptor(
        child: AlertDialog(
          title: SelectableText("About"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                SelectableText(
                    "Dialect is an open source project licensed under the GNU General Public License v3.0."),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("VIEW SOURCE"),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                html.window.open(
                    "https://github.com/dialect-org?tab=repositories",
                    'new tab');
              },
            ),
            TextButton(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("CLOSE"),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    },
  );
}

// used for adaptive UI
bool isDesktop(BuildContext context) {
  return MediaQuery.of(context).size.width > 640.0;
}