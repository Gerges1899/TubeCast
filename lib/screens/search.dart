import 'package:flutter/material.dart';
import 'package:tube_cast/constants.dart';
import 'package:youtube_api/youtube_api.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:math' as math;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController controller = TextEditingController();
  YoutubeAPI ytApi =
      new YoutubeAPI(constants.strictKey, maxResults: 500, type: "video");
  List<YouTubeVideo> videoResult = [];
  bool clicked = false;
  bool _isLoading = true;
  bool _isAudioLoading = false;
  bool trending = true;
  bool play = false;
  bool playing = true;
  YouTubeVideo? current = null;

  var yt = YoutubeExplode();
  // final audioplayer = AudioPlayer();
  final playerr = AudioPlayer();

  Widget playicon = Icon(Icons.pause);
  @override
  void initState() {
    // TODO: implement initState
    initresult();
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    playerr.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    // TODO: implement reassemble
    playerr.pause();
    playing = !playing;

    super.reassemble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            leading: Icon(
              Icons.menu,
              size: 30,
            ),
            centerTitle: true,
            actions: [
              clicked
                  ? IconButton(
                      iconSize: 30,
                      icon: Icon(
                        Icons.close,
                        size: 30,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          clicked = !clicked;
                        });
                      },
                    )
                  : IconButton(
                      iconSize: 30,
                      icon: Icon(
                        Icons.search,
                        size: 30,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          clicked = !clicked;
                        });
                      },
                    )
            ],
            backgroundColor: Color(0xff252525),
            title: SvgPicture.asset(
              'assets/tubifylogo.svg',
              height: 28,
              width: 150,
            ),
            bottom: clicked
                ? PreferredSize(
                    preferredSize: Size.fromHeight(90.0),
                    child: Padding(
                        padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                        child: TextField(
                            style: TextStyle(color: Colors.white),
                            cursorColor: Colors.white,
                            onEditingComplete: () async {
                              setState(() {
                                _isLoading = true;
                                trending = false;
                              });
                              videoResult.clear();
                              String query = controller.text;
                              videoResult =
                                  await ytApi.search(query, type: 'video');
                              clicked = false;
                              setState(() {
                                _isLoading = false;
                              });
                            },
                            onChanged: (value) {
                              setState(() {});
                            },
                            controller: controller,
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(width: 1, color: Colors.white),
                              ),
                              fillColor: Color(0xff252525),
                              filled: true,
                              hintText: 'Search',
                              hintStyle: TextStyle(color: Colors.white),
                              constraints: BoxConstraints(maxHeight: 100),
                              border: const OutlineInputBorder(),
                              suffixIcon: controller.text.isEmpty
                                  ? null
                                  : IconButton(
                                      color: Colors.white,
                                      onPressed: () async {
                                        videoResult = videoResult = await ytApi
                                            .getTrends(regionCode: 'US');
                                        setState(
                                          () {
                                            trending = true;
                                            controller.clear();
                                          },
                                        );
                                      },
                                      icon: const Icon(Icons.clear)),
                            ))),
                  )
                : PreferredSize(
                    preferredSize:
                        Size.fromHeight(0), // here the desired height
                    child: SizedBox.shrink())),
        body: Stack(alignment: AlignmentDirectional.bottomCenter, children: [
          Container(
              color: Colors.black,
              child: Center(
                  child: ListView(children: [
                trending
                    ? Padding(
                        padding: EdgeInsets.fromLTRB(28, 20, 28, 0),
                        child: Text(
                          'Trending Right Now ..',
                          style: TextStyle(
                              color: Colors.white, fontFamily: 'Gotham'),
                        ))
                    : Padding(
                        padding: EdgeInsets.fromLTRB(28, 20, 28, 0),
                        child: Text(
                          'Your Search Results ..',
                          style: TextStyle(
                              color: Colors.white, fontFamily: 'Gotham'),
                        )),
                if (!_isLoading) ...[
                  for (YouTubeVideo i in videoResult) ...[
                    Container(
                        height: 285,
                        padding: EdgeInsets.fromLTRB(28, 15, 28, 0),
                        child: GestureDetector(
                            onTap: () async {
                              setState(() {
                                _isAudioLoading = true;
                                play = true;
                                current = i;
                                playerr.stop();
                              });
                              var manifest = await yt.videos.streamsClient
                                  .getManifest(i.url);
                              var streamInfo =
                                  manifest.audioOnly.withHighestBitrate();
                              setState(() {
                                _isAudioLoading = false;
                                playing = true;
                              });
                              playerr.setUrl(
                                streamInfo.url.toString(),
                              );
                              playerr.play();
                            },
                            child: Card(
                                elevation: 50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                color: Color(0xff252525),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                        alignment: AlignmentDirectional.center,
                                        children: [
                                          ClipRRect(
                                              borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(5),
                                                  topRight: Radius.circular(5)),
                                              child: Image.network(
                                                  i.thumbnail.medium.url!,
                                                  height: 180,
                                                  fit: BoxFit.fitHeight)),
                                          CircleAvatar(
                                            radius: 27,
                                            backgroundColor: Color(0xff1DB954),
                                            child: Icon(
                                              Icons.play_arrow,
                                              color: Colors.white,
                                              size: 40,
                                            ),
                                          ),
                                        ]),
                                    Transform.translate(
                                      offset: Offset(-6, -18),
                                      child: Container(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          i.duration.toString(),
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    Transform.translate(
                                        offset: Offset(0, -20),
                                        child: Divider(
                                          color: Color(0xff1DB954),
                                          thickness: 2.5,
                                        )),
                                    Transform.translate(
                                        offset: Offset(0, -16),
                                        child: Flex(
                                            direction: Axis.horizontal,
                                            children: [
                                              Expanded(
                                                  child: Padding(
                                                      padding:
                                                          EdgeInsets.fromLTRB(
                                                              20, 0, 20, 2),
                                                      child: RichText(
                                                        maxLines: 2,
                                                        text: TextSpan(
                                                            locale:
                                                                Locale('en'),
                                                            text:
                                                                removeUnicodeApostrophes(
                                                                    i.title),
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                height: 1.5)),
                                                      )))
                                            ]))
                                  ],
                                ))))
                  ]
                ] else ...[
                  Center(
                      child: Transform.translate(
                          offset:
                              Offset(0, MediaQuery.of(context).size.height / 3),
                          child: CircularProgressIndicator())),
                ]
              ]))),
          play ? player() : SizedBox.shrink()
        ]));
  }

  String removeUnicodeApostrophes(String strInput) {
    // First remove the single slash.
    String strModified = strInput.replaceAll('&#39;', "\'");
    strModified = strModified.replaceAll('&quot;', "\"");

    // Now, we can replace the rest of the unicode with a proper apostrophe.
    return strModified;
  }

  initresult() async {
    videoResult = await ytApi.getTrends(regionCode: 'US');
    _isLoading = false;
    setState(() {});
  }

  Widget player() {
    return GestureDetector(
        onPanUpdate: (details) {
          if (details.delta.dx.abs() > 10)
            setState(() {
              play = false;
              playerr.stop();
              current = null;
            });
        },
        child: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xff1db976),
                Color(0xff252525),
              ],
            )),
            padding: EdgeInsets.only(right: 28, left: 28),
            height: 90,
            // width: MediaQuery.of(context).size.width - 56,

            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage:
                      NetworkImage(current!.thumbnail.medium.url ?? ''),
                ),
                Spacer(),
                Expanded(
                    flex: 5,
                    child: RichText(
                      maxLines: 3,
                      text: TextSpan(
                          locale: Locale('en'),
                          text: removeUnicodeApostrophes(current!.title),
                          style: TextStyle(color: Colors.white, height: 1.5)),
                    )),
                Spacer(),
                !_isAudioLoading
                    ? playing
                        ? IconButton(
                            onPressed: () {
                              setState(() {
                                playerr.pause();
                                playing = !playing;
                              });
                            },
                            icon: Icon(Icons.pause),
                            color: Colors.white,
                            iconSize: 30,
                          )
                        : IconButton(
                            onPressed: () {
                              setState(() {
                                playerr.play();
                                playing = !playing;
                              });
                            },
                            icon: Icon(Icons.play_arrow),
                            color: Colors.white,
                            iconSize: 30,
                          )
                    : CircularProgressIndicator(
                        color: Colors.white,
                      ),
              ],
            )));
  }
}
