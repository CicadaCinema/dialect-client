import 'package:dialect/screens/explore.dart';
import 'package:dialect/screens/info.dart';
import 'package:flutter/material.dart';

import 'adaptive.dart';
import 'misc.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dialect',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      debugShowCheckedModeBanner: false,
      home: MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  MainLayout({Key? key}) : super(key: key);

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: Text('Dialect'),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextButton(
            style: TextButton.styleFrom(primary: Colors.white),
            onPressed: () {
              showDialogBox(
                  "What's new",
                  "The layout of the site has been revamped!",
                  context);
            },
            child: Text("What's new"),
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (String value) async {
            switch (value) {
              case "About":
                {
                  await showAboutDialogBox(context);
                }
                break;

              default:
                {
                  print("Invalid context menu choice.");
                }
                break;
            }
          },
          itemBuilder: (BuildContext context) {
            return {"About"}.map(
              (String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              },
            ).toList();
          },
        ),
      ],
      currentIndex: _pageIndex,
      destinations: [
        AdaptiveScaffoldDestination(
            title: 'About', icon: Icons.info_outline, selectedIcon: Icons.info),
        AdaptiveScaffoldDestination(
            title: 'Dialect',
            icon: Icons.explore_outlined,
            selectedIcon: Icons.explore),
        AdaptiveScaffoldDestination(
            title: 'Settings',
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings),
      ],
      body: _pageAtIndex(_pageIndex),
      onNavigationIndexChange: (newIndex) {
        setState(() {
          _pageIndex = newIndex;
        });
      },
    );
  }

  static Widget _pageAtIndex(int index) {
    switch (index) {
      case 0:
        {
          return InfoPage();
        }
      case 1:
        {
          return ExplorePage();
        }
      case 2:
        {
          return Center(child: Text('Coming soon!'));
        }
      default:
        {
          return Center(child: Text('Page not found.'));
        }
    }
  }
}
