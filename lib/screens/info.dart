import 'dart:math';

import 'package:flutter/material.dart';

import 'dart:html';
import 'dart:ui' as ui;

class InfoPage extends StatefulWidget {
  const InfoPage({Key? key}) : super(key: key);

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  // TODO: ensure HtmlElementVew doesn't get reloaded when the window is resized

  final String htmlsource = """
<!-- import the component -->
<script type="module" src="https://unpkg.com/@google/model-viewer/dist/model-viewer.min.js"></script>
<!-- Use it like any other HTML element -->
<model-viewer src="/droplet-model.glb" integrity="sha256-B6C751C345F6FD96E5E214AA763574E433A4C0784377025DD4AE70C75EEFE971" crossorigin="anonymous" alt="Droplet logo" ar ar-modes="webxr scene-viewer quick-look" environment-image="neutral" auto-rotate camera-controls></model-viewer>
<!-- Fill available space https://github.com/google/model-viewer/issues/1276#issuecomment-643548184 -->
<style>
   * {
   margin: 0;
   padding: 0;
   }
   html {
   height: 100%;
   width: 100%;
   }
   body {
   height: 100%;
   width: 100%;
   }
   model-viewer {
   height: 100%;
   width: 100%;
   }
</style>
""";

  @override
  void initState() {
    super.initState();

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
        'hello-html',
        (int viewId) => IFrameElement()
          //..width = '200'
          //..height = '200'
          ..srcdoc = htmlsource
          ..style.border = 'none');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
            padding: EdgeInsets.all(25),
            child: SizedBox(
                height: min(MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height * 0.7),
                child: HtmlElementView(viewType: 'hello-html'))),
        Center(
            child: SelectableText(
          "Welcome to Dialect!",
          style: TextStyle(fontSize: 24),
        ))
      ],
    );
  }
}
