import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:tube_cast/constants.dart';
import 'package:youtube_api/youtube_api.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:math' as math;
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:rxdart/rxdart.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:youtube_data_api/youtube_data_api.dart' as ytu;
// import 'package:dropdown_pro/dropdown_pro.dart';
import 'package:searchfield/searchfield.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController controller = TextEditingController();
  YoutubeAPI ytApi =
      new YoutubeAPI(constants.strictKey, maxResults: 500, type: "video");
  ytu.YoutubeDataApi youtubeDataApi = ytu.YoutubeDataApi();
  FocusNode ff = FocusNode();
  List<YouTubeVideo> videoResult = [];
  YouTubeVideo? playingNow = null;

  bool clicked = false;
  bool _isLoading = true;
  bool _isAudioLoading = false;
  bool trending = true;
  bool play = false;
  bool playing = false;
  int current = -1;
  double height = 80;
  bool notFound = false;
  bool visible = true;
  ConnectivityResult connected = ConnectivityResult.none;
  Stream<DurationState>? _durationState;
  List<String> suggestions = [];

  var yt = YoutubeExplode();
  // final audioplayer = AudioPlayer();
  final playerr = AudioPlayer();

  Widget playicon = Icon(Icons.pause);
  @override
  void initState() {
    // TODO: implement initState
    controller.addListener(
      () async {
        try {
          suggestions = await youtubeDataApi.fetchSuggestions(controller.text);
        } catch (err) {}
        setState(() {});
      },
    );
    initconnectinvity();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      connected = result;
      if (connected == ConnectivityResult.wifi ||
          connected == ConnectivityResult.mobile) {
        if (trending) {
          initresult();
        } else {
          initSearch();
        }
      } else {
        if (play) {
          play = !play;
          playerr.stop();
        }
      }
      setState(() {});
    });
    _durationState = Rx.combineLatest2<Duration, PlaybackEvent, DurationState>(
        playerr.positionStream,
        playerr.playbackEventStream,
        (position, playbackEvent) => DurationState(
              progress: position,
              buffered: playbackEvent.bufferedPosition,
              total: playbackEvent.duration,
            )).asBroadcastStream();
    playing = playerr.playing;
    playerr.playerStateStream.listen(
      (event) {
        playing = event.playing;
        setState(() {});
      },
    );
    // if (connected == ConnectivityResult.wifi ||
    //     connected == ConnectivityResult.mobile) initresult();
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
    playing = false;
    super.reassemble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: Builder(builder: (BuildContext context) {
          return Drawer(
            backgroundColor: Colors.black,
            child: ListView(padding: EdgeInsets.zero, children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Color(0xff252525)),
                child: Container(
                    padding: EdgeInsets.all(20),
                    child: SvgPicture.asset(
                      'assets/Horizontal.svg',
                      fit: BoxFit.scaleDown,
                    )),
              ),
              Transform.translate(
                  offset: Offset(0, -15),
                  child: Divider(
                    color: Colors.white,
                    thickness: 3,
                  )),
              ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      backgroundColor: Colors.transparent),
                  onPressed: () async {
                    setState(() {
                      ff.unfocus();
                      Scaffold.of(context).closeDrawer();
                      clicked = false;
                      _isLoading = true;
                      height = 80;
                      notFound = false;
                    });

                    videoResult = await ytApi.getTrends(regionCode: 'US');

                    setState(
                      () {
                        _isLoading = false;
                        trending = true;
                        controller.clear();
                        suggestions.clear();
                      },
                    );
                  },
                  icon: Icon(
                    Icons.trending_up,
                    size: 30,
                  ),
                  label: Text(
                    'Trending',
                    style: TextStyle(fontSize: 20, fontFamily: 'Gotham'),
                  )),
              Padding(padding: EdgeInsets.only(top: 15)),
              ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      backgroundColor: Colors.transparent),
                  onPressed: () {},
                  icon: Icon(
                    Icons.file_download_sharp,
                    size: 30,
                  ),
                  label: Text(
                    'Downloads',
                    style: TextStyle(fontSize: 20, fontFamily: 'Gotham'),
                  ))
            ]),
          );
        }),
        appBar: AppBar(
            leading: Builder(
              builder: (BuildContext context) {
                return IconButton(
                  iconSize: 30,
                  icon: const Icon(
                    Icons.menu,
                  ),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                );
              },
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
                          ff.unfocus();
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
                          height = 80;
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
                    preferredSize: Size.fromHeight(90),
                    child: Padding(
                        padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                        child: SearchField<String>(
                            focusNode: ff,
                            marginColor: Color(0xff252525),
                            suggestions: suggestions
                                .map((e) => SearchFieldListItem<String>(e,
                                    child: Padding(
                                        padding: EdgeInsets.only(left: 10),
                                        child: Text(
                                          e,
                                          style: TextStyle(
                                              height: 1.5,
                                              color: Color(0xff252525),
                                              fontFamily: 'Gotham'),
                                        ))))
                                .toList(),
                            searchStyle: TextStyle(color: Colors.white),
                            itemHeight: 50,
                            onSuggestionTap: (value) {
                              initSearch();
                            },
                            hasOverlay: true,
                            suggestionAction: SuggestionAction.unfocus,
                            textInputAction: TextInputAction.done,
                            onSubmit: (value) async {
                              setState(() {
                                clicked = !clicked;
                                _isLoading = true;
                                trending = false;
                                notFound = false;
                              });
                              videoResult.clear();
                              String query = controller.text;
                              try {
                                videoResult =
                                    await ytApi.search(query, type: 'video');
                              } catch (err) {
                                _isLoading = false;
                                notFound = true;
                                setState(() {});
                              }
                              clicked = false;
                              setState(() {
                                _isLoading = false;
                              });
                            },
                            controller: controller,
                            searchInputDecoration: InputDecoration(
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
                                        setState(() {
                                          _isLoading = true;
                                          height = 80;
                                          notFound = false;
                                        });

                                        setState(
                                          () {
                                            _isLoading = false;
                                            controller.clear();
                                            suggestions.clear();
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
        body: Builder(builder: (BuildContext context) {
          return GestureDetector(
              onPanUpdate: (details) {
                if (details.delta.dx > 10) {
                  Scaffold.of(context).openDrawer();
                }
              },
              child: Stack(
                  alignment: AlignmentDirectional.bottomCenter,
                  children: [
                    Container(
                        color: Colors.black,
                        child: Center(
                            child: ListView(children: [
                          if (connected == ConnectivityResult.wifi ||
                              connected == ConnectivityResult.mobile) ...[
                            if (trending && !_isLoading) ...[
                              Padding(
                                  padding: EdgeInsets.fromLTRB(28, 20, 28, 0),
                                  child: Text(
                                    'Trending Right Now ..',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Gotham'),
                                  ))
                            ] else if (!trending && !_isLoading) ...[
                              if (!notFound) ...[
                                Padding(
                                    padding: EdgeInsets.fromLTRB(28, 20, 28, 0),
                                    child: Text(
                                      'Your Search Results ..',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Gotham'),
                                    ))
                              ] else ...[
                                Padding(
                                    padding: EdgeInsets.fromLTRB(28, 20, 28, 0),
                                    child: Text(
                                      'No Results was found.\nTry searching with different key words, Sorry.',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Gotham',
                                          height: 1.5),
                                    ))
                              ]
                            ]
                          ] else ...[
                            Padding(
                                padding: EdgeInsets.fromLTRB(28, 20, 28, 0),
                                child: Text(
                                  'No Internet Connection..\nBut you can still enjoy your downloaded videos.',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Gotham',
                                      height: 1.5),
                                ))
                          ],
                          if (connected == ConnectivityResult.wifi ||
                              connected == ConnectivityResult.mobile) ...[
                            if (!_isLoading &&
                                [
                                  ConnectivityResult.wifi,
                                  ConnectivityResult.mobile
                                ].contains(connected)) ...[
                              for (int i = 0; i < videoResult.length; i++) ...[
                                Container(
                                    height: 285,
                                    padding: EdgeInsets.fromLTRB(28, 15, 28, 0),
                                    child: GestureDetector(
                                        onTap: () async {
                                          setState(() {
                                            _isAudioLoading = true;
                                            current = i;
                                            playingNow = videoResult[current];
                                            playerr.stop();
                                          });
                                          var manifest = await yt
                                              .videos.streamsClient
                                              .getManifest(videoResult[i].url);
                                          var streamInfo = manifest.audioOnly
                                              .withHighestBitrate();
                                          setState(() {
                                            _isAudioLoading = false;
                                            playing = true;
                                          });

                                          playerr.setAudioSource(
                                              ConcatenatingAudioSource(
                                                  children: [
                                                AudioSource.uri(streamInfo.url,
                                                    tag: MediaItem(
                                                        id: videoResult[i].id!,
                                                        title:
                                                            removeUnicodeApostrophes(
                                                                videoResult[i]
                                                                    .title),
                                                        artist:
                                                            removeUnicodeApostrophes(
                                                                videoResult[i]
                                                                    .channelTitle),
                                                        artUri: Uri.parse(
                                                            videoResult[i]
                                                                .thumbnail
                                                                .medium
                                                                .url!)))
                                              ]));

                                          setState(() {
                                            play = true;
                                          });
                                          playerr.play();
                                        },
                                        child: Card(
                                            elevation: 50,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            color: Color(0xff252525),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Stack(
                                                    alignment:
                                                        AlignmentDirectional
                                                            .bottomCenter,
                                                    children: [
                                                      Stack(
                                                          alignment:
                                                              AlignmentDirectional
                                                                  .bottomStart,
                                                          children: [
                                                            Stack(
                                                                alignment:
                                                                    AlignmentDirectional
                                                                        .center,
                                                                children: [
                                                                  ClipRRect(
                                                                      borderRadius: BorderRadius.only(
                                                                          topLeft: Radius.circular(
                                                                              5),
                                                                          topRight: Radius.circular(
                                                                              5)),
                                                                      child: FadeInImage.assetNetwork(
                                                                          image: videoResult[i]
                                                                              .thumbnail
                                                                              .medium
                                                                              .url!,
                                                                          placeholder:
                                                                              'assets/placeholder.png',
                                                                          height:
                                                                              180,
                                                                          fit: BoxFit
                                                                              .fitHeight)),
                                                                  Center(
                                                                      child:
                                                                          CircleAvatar(
                                                                    radius: 27,
                                                                    backgroundColor:
                                                                        Color(
                                                                            0xff1DB954),
                                                                    child: Icon(
                                                                      Icons
                                                                          .play_arrow,
                                                                      color: Colors
                                                                          .white,
                                                                      size: 40,
                                                                    ),
                                                                  )),
                                                                ]),
                                                            Container(
                                                              alignment: Alignment
                                                                  .centerRight,
                                                              padding: EdgeInsets
                                                                  .only(
                                                                      bottom: 5,
                                                                      right: 5),
                                                              child: Text(
                                                                videoResult[i]
                                                                    .duration
                                                                    .toString(),
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                            ),
                                                          ]),
                                                      Transform.translate(
                                                          offset: Offset(0, 8),
                                                          child: Divider(
                                                            color: Color(
                                                                0xff1DB954),
                                                            thickness: 3,
                                                          ))
                                                    ]),
                                                Flex(
                                                    direction: Axis.horizontal,
                                                    children: [
                                                      Expanded(
                                                          child: Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .fromLTRB(
                                                                          20,
                                                                          15,
                                                                          20,
                                                                          2),
                                                              child: RichText(
                                                                maxLines: 2,
                                                                text: TextSpan(
                                                                    locale:
                                                                        Locale(
                                                                            'en'),
                                                                    text: removeUnicodeApostrophes(
                                                                        videoResult[i]
                                                                            .title),
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        height:
                                                                            1.5)),
                                                              )))
                                                    ])
                                              ],
                                            ))))
                              ]
                            ] else ...[
                              Center(
                                  child: Transform.translate(
                                      offset: Offset(0, 25),
                                      child: CircularProgressIndicator())),
                            ]
                          ]
                        ]))),
                    play ? player() : SizedBox.shrink()
                  ]));
        }));
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
        onTap: () async {
          clicked = false;
          ff.unfocus();
          await Future.delayed(const Duration(milliseconds: 150));
          setState(() {
            height = MediaQuery.of(context).size.height;
          });
        },
        onPanUpdate: (details) {
          if (details.delta.dy > 10) {
            setState(() {
              height = 80;
            });
          }
        },
        child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
                gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: height == 80 ? [0.0, 1] : [0.0, 0.5, 1],
              colors: height == 80
                  ? [
                      Color(0xff252525),
                      // Color(0xff1DB954),
                      Colors.blueGrey,
                    ]
                  : [
                      Color(0xff252525),
                      Color(0xff1DB954),
                      Colors.blueGrey,
                    ],
            )),
            height: height,
            child: height == 80
                ? Padding(
                    padding: EdgeInsets.only(right: 28),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.network(playingNow!.thumbnail.small.url!),
                        Spacer(),
                        Expanded(
                            flex: 5,
                            child: RichText(
                              maxLines: 3,
                              text: TextSpan(
                                  locale: Locale('en'),
                                  text: removeUnicodeApostrophes(
                                      playingNow!.title),
                                  style: TextStyle(
                                      color: Colors.white,
                                      height: 1.5,
                                      fontSize: 11)),
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
                    ))
                : Stack(alignment: AlignmentDirectional.topCenter, children: [
                    Stack(
                        alignment: AlignmentDirectional.bottomCenter,
                        children: [
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                    padding: EdgeInsets.only(
                                        top: 120, right: 20, left: 20),
                                    child: Image.network(
                                      playingNow!.thumbnail.high.url!,
                                      fit: BoxFit.fitWidth,
                                    )),
                                Transform.translate(
                                    offset: Offset(0, 40),
                                    child: SizedBox(
                                        width: 340,
                                        child: RichText(
                                          text: TextSpan(
                                              locale: Locale('en'),
                                              text: removeUnicodeApostrophes(
                                                  playingNow!.title),
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  height: 1.5,
                                                  fontSize: 16)),
                                        ))),
                              ]),
                          Container(
                              height: 240,
                              child: Column(children: [
                                StreamBuilder<DurationState>(
                                  stream: _durationState,
                                  builder: (context, snapshot) {
                                    final durationState = snapshot.data;
                                    final progress = durationState?.progress ??
                                        Duration.zero;
                                    final buffered = durationState?.buffered ??
                                        Duration.zero;
                                    final total = durationState?.total ??
                                        playerr.duration ??
                                        Duration.zero;

                                    return Padding(
                                        padding: EdgeInsets.only(
                                            left: 20, right: 20, bottom: 25),
                                        child: ProgressBar(
                                          timeLabelPadding: 5,
                                          timeLabelTextStyle:
                                              TextStyle(color: Colors.white),
                                          progress: progress,
                                          buffered: buffered,
                                          total: total,
                                          progressBarColor: Color(0xff252525),
                                          baseBarColor:
                                              Colors.white.withOpacity(0.24),
                                          bufferedBarColor:
                                              Colors.white.withOpacity(0.24),
                                          thumbColor: Colors.white,
                                          barHeight: 5.0,
                                          thumbRadius: 7,
                                          onSeek: (duration) {
                                            playerr.seek(duration);
                                          },
                                        ));
                                  },
                                ),
                                Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: !_isAudioLoading ? 30 : 45,
                                    children: [
                                      if (current - 1 >= 0) ...[
                                        IconButton(
                                          onPressed: () async {
                                            setState(() {
                                              current--;
                                              playingNow = videoResult[current];
                                            });
                                            setState(() {
                                              _isAudioLoading = true;
                                              current = current;
                                              playerr.stop();
                                            });
                                            var manifest = await yt
                                                .videos.streamsClient
                                                .getManifest(playingNow!.url);
                                            var streamInfo = manifest.audioOnly
                                                .withHighestBitrate();
                                            setState(() {
                                              _isAudioLoading = false;
                                              playing = true;
                                            });
                                            playerr.setAudioSource(
                                                ConcatenatingAudioSource(
                                                    children: [
                                                  AudioSource.uri(
                                                      streamInfo.url,
                                                      tag: MediaItem(
                                                          id: playingNow!.id!,
                                                          title:
                                                              removeUnicodeApostrophes(
                                                                  videoResult[
                                                                          current]
                                                                      .title),
                                                          artist: removeUnicodeApostrophes(
                                                              videoResult[
                                                                      current]
                                                                  .channelTitle),
                                                          artUri: Uri.parse(
                                                              playingNow!
                                                                  .thumbnail
                                                                  .medium
                                                                  .url!)))
                                                ]));

                                            setState(() {
                                              play = true;
                                            });
                                            playerr.play();
                                          },
                                          icon: Icon(Icons.skip_previous),
                                          color: Colors.white,
                                          iconSize: 50,
                                        )
                                      ] else ...[
                                        SizedBox(
                                          width: 66,
                                        )
                                      ],
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
                                                  iconSize: 50,
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
                                                  iconSize: 50,
                                                )
                                          : CircularProgressIndicator(
                                              strokeWidth: 5,
                                              color: Colors.white,
                                            ),
                                      if (current + 1 < videoResult.length) ...[
                                        IconButton(
                                          onPressed: () async {
                                            setState(() {
                                              current++;
                                              playingNow = videoResult[current];
                                            });
                                            setState(() {
                                              _isAudioLoading = true;
                                              current = current;
                                              playerr.stop();
                                            });
                                            var manifest = await yt
                                                .videos.streamsClient
                                                .getManifest(playingNow!.url);
                                            var streamInfo = manifest.audioOnly
                                                .withHighestBitrate();
                                            setState(() {
                                              _isAudioLoading = false;
                                              playing = true;
                                            });
                                            playerr.setAudioSource(
                                                ConcatenatingAudioSource(
                                                    children: [
                                                  AudioSource.uri(
                                                      streamInfo.url,
                                                      tag: MediaItem(
                                                          id: playingNow!.id!,
                                                          title:
                                                              removeUnicodeApostrophes(
                                                                  videoResult[
                                                                          current]
                                                                      .title),
                                                          artist: removeUnicodeApostrophes(
                                                              videoResult[
                                                                      current]
                                                                  .channelTitle),
                                                          artUri: Uri.parse(
                                                              playingNow!
                                                                  .thumbnail
                                                                  .medium
                                                                  .url!)))
                                                ]));

                                            setState(() {
                                              play = true;
                                            });
                                            playerr.play();
                                          },
                                          icon: Icon(Icons.skip_next),
                                          color: Colors.white,
                                          iconSize: 50,
                                        )
                                      ] else ...[
                                        SizedBox(
                                          width: 66,
                                        )
                                      ],
                                    ])
                              ])),
                        ]),
                    Padding(
                        padding: EdgeInsets.only(right: 5, left: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  height = 80;
                                });
                              },
                              icon: Icon(Icons.keyboard_arrow_down),
                              color: Colors.white,
                              iconSize: 40,
                            ),
                            Spacer(),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  height = 80;
                                });
                              },
                              icon: Icon(Icons.download),
                              color: Colors.white,
                              iconSize: 30,
                            ),
                          ],
                        ))
                  ])));
  }

  Duration parseDuration(String s) {
    int hours = 0;
    int minutes = 0;
    int micros;
    List<String> parts = s.split(':');
    if (parts.length > 2) {
      hours = int.parse(parts[parts.length - 3]);
    }
    if (parts.length > 1) {
      minutes = int.parse(parts[parts.length - 2]);
    }
    micros = (double.parse(parts[parts.length - 1]) * 1000000).round();
    return Duration(hours: hours, minutes: minutes, microseconds: micros);
  }

  initconnectinvity() async {
    connected = await Connectivity().checkConnectivity();
    if (connected == ConnectivityResult.wifi ||
        connected == ConnectivityResult.mobile) {
      if (trending) {
        initresult();
      } else {
        initSearch();
      }
    } else {
      if (play) {
        play = !play;
        playerr.stop();
      }
    }
    setState(() {});
  }

  initSearch() async {
    setState(() {
      clicked = !clicked;
      _isLoading = true;
      trending = false;
      notFound = false;
    });
    videoResult.clear();
    String query = controller.text;
    try {
      videoResult = await ytApi.search(query, type: 'video');
    } catch (err) {
      _isLoading = false;
      notFound = true;
      setState(() {});
    }
    clicked = false;
    setState(() {
      _isLoading = false;
    });
  }
}

class DurationState {
  const DurationState(
      {required this.progress, required this.buffered, this.total});
  final Duration progress;
  final Duration buffered;
  final Duration? total;
}
