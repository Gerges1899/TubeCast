import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:tube_cast/constants.dart';
import 'package:youtube_api/youtube_api.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:youtube_data_api/models/playlist.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:math' as math;
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:rxdart/rxdart.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:youtube_data_api/youtube_data_api.dart' as ytu;
import 'package:searchfield/searchfield.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:focused_menu_custom/focused_menu.dart';
import 'package:focused_menu_custom/modals.dart';

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
  List<YouTubeVideo> nowVideo = [];
  YouTubeVideo? playingNow = null;
  bool clicked = false;
  bool _isLoading = true;
  bool _isAudioLoading = false;
  bool _isAudioDownloading = false;
  bool trending = true;
  bool play = false;
  bool dplay = false;
  bool playing = false;
  int current = -1;
  double height = 80;
  bool notFound = false;
  bool visible = true;
  bool downloads = false;
  ConcatenatingAudioSource? Playlist = null;

  String title = '';
  ConnectivityResult connected = ConnectivityResult.none;
  Stream<DurationState>? _durationState;

  List<String> suggestions = [];
  var yt = YoutubeExplode();
  final playerr = AudioPlayer();

  AudioOnlyStreamInfo? stream = null;
  Widget playicon = Icon(Icons.pause);
  Directory? dir;
  List<FileSystemEntity> files = [];
  @override
  void initState() {
    controller.addListener(
      () async {
        try {
          if (!downloads) {
            suggestions =
                await youtubeDataApi.fetchSuggestions(controller.text);
          } else {
            files = dir!
                .listSync()
                .where((element) => element.path
                    .split('/')
                    .last
                    .toLowerCase()
                    .contains(controller.text.toLowerCase()))
                .toList();
          }
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
          downloads = true;
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
    playerr.sequenceStateStream.listen((event) {
      title = event!.currentSource!.tag.title;
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    playerr.dispose();
    yt.close();
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
                      downloads = false;
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
                  onPressed: () async {
                    setState(() {
                      downloads = false;
                      ff.unfocus();
                      Scaffold.of(context).closeDrawer();
                      clicked = false;
                      height = 80;
                      notFound = false;
                    });
                  },
                  icon: Icon(
                    Icons.search,
                    size: 30,
                  ),
                  label: Text(
                    'Search results',
                    style: TextStyle(fontSize: 20, fontFamily: 'Gotham'),
                  )),
              Padding(padding: EdgeInsets.only(top: 15)),
              ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      backgroundColor: Colors.transparent),
                  onPressed: () async {
                    await _createFolder();
                    setState(() {
                      ff.unfocus();
                      controller.clear();
                      height = 80;
                      clicked = false;
                      downloads = true;
                      Scaffold.of(context).closeDrawer();
                    });
                    setState(() {});
                  },
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
                            suggestions: downloads
                                ? []
                                : suggestions
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
                              downloads = false;
                              initSearch();
                            },
                            hasOverlay: true,
                            suggestionAction: SuggestionAction.unfocus,
                            textInputAction: TextInputAction.done,
                            onSubmit: (value) async {
                              if (!downloads) {
                                setState(() {
                                  downloads = false;
                                  clicked = !clicked;
                                  _isLoading = true;
                                  trending = false;
                                  notFound = false;
                                });

                                String query = controller.text;
                                try {
                                  videoResult =
                                      await ytApi.search(query, type: 'video');
                                } catch (err) {
                                  _isLoading = false;
                                  notFound = true;
                                  setState(() {});
                                }

                                setState(() {
                                  _isLoading = false;
                                });
                              } else {
                                files = files
                                    .where((element) => element.path
                                        .split('/')
                                        .last
                                        .replaceAll('.mp3', '')
                                        .toLowerCase()
                                        .contains(
                                            controller.text.toLowerCase()))
                                    .toList();
                                clicked = false;
                                setState(() {});
                              }
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
                    if (!downloads) ...[
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
                                      padding:
                                          EdgeInsets.fromLTRB(28, 20, 28, 0),
                                      child: Text(
                                        'Your Search Results ..',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Gotham'),
                                      ))
                                ] else ...[
                                  Padding(
                                      padding:
                                          EdgeInsets.fromLTRB(28, 20, 28, 0),
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
                                for (int i = 0;
                                    i < videoResult.length;
                                    i++) ...[
                                  Container(
                                      height: 285,
                                      padding:
                                          EdgeInsets.fromLTRB(28, 15, 28, 0),
                                      child: GestureDetector(
                                          onTap: () async {
                                            setState(() {
                                              _isAudioDownloading = false;
                                              _isAudioLoading = true;
                                              current = i;
                                              playingNow = videoResult[current];
                                              playerr.stop();
                                              nowVideo = videoResult;
                                              dplay = false;
                                              play = true;
                                            });
                                            var manifest = await yt
                                                .videos.streamsClient
                                                .getManifest(
                                                    videoResult[i].url);
                                            var streamInfo = manifest.audioOnly
                                                .withHighestBitrate();
                                            setState(() {
                                              _isAudioLoading = false;
                                              playing = true;
                                            });
                                            stream = streamInfo;
                                            playerr.setAudioSource(
                                                ConcatenatingAudioSource(
                                                    children: [
                                                  AudioSource.uri(
                                                      streamInfo.url,
                                                      tag: MediaItem(
                                                          id: videoResult[i]
                                                              .id!,
                                                          title:
                                                              removeUnicodeApostrophes(
                                                                  videoResult[i]
                                                                      .title),
                                                          artist: removeUnicodeApostrophes(
                                                              videoResult[i]
                                                                  .channelTitle),
                                                          artUri: Uri.parse(
                                                              videoResult[i]
                                                                  .thumbnail
                                                                  .medium
                                                                  .url!)))
                                                ]));

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
                                                                            fit:
                                                                                BoxFit.fitHeight)),
                                                                    Center(
                                                                        child:
                                                                            CircleAvatar(
                                                                      radius:
                                                                          27,
                                                                      backgroundColor:
                                                                          Color(
                                                                              0xff1DB954),
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .play_arrow,
                                                                        color: Colors
                                                                            .white,
                                                                        size:
                                                                            40,
                                                                      ),
                                                                    )),
                                                                  ]),
                                                              Container(
                                                                alignment: Alignment
                                                                    .centerRight,
                                                                padding: EdgeInsets
                                                                    .only(
                                                                        bottom:
                                                                            5,
                                                                        right:
                                                                            5),
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
                                                            offset:
                                                                Offset(0, 8),
                                                            child: Divider(
                                                              color: Color(
                                                                  0xff1DB954),
                                                              thickness: 3,
                                                            ))
                                                      ]),
                                                  Flex(
                                                      direction:
                                                          Axis.horizontal,
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
                                                                      locale: Locale(
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
                          ])))
                    ] else ...[
                      Container(
                        color: Colors.black,
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(28, 0, 28, 0),
                          children: [
                            Padding(
                                padding: EdgeInsets.fromLTRB(0, 10, 0, 15),
                                child: Text(
                                  'Your Downloads.',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Gotham',
                                      height: 1.5),
                                )),
                            for (var i in files) ...[
                              FocusedMenuHolder(
                                  menuItemExtent: 45,
                                  menuWidth:
                                      MediaQuery.of(context).size.width * 0.50,
                                  animateMenuItems: true,
                                  blurSize: 0.25,
                                  blurBackgroundColor: Colors.black54,
                                  menuOffset: -20,
                                  borderColor: Color(0xff252525),
                                  openWithTap: false,
                                  onPressed: () {},
                                  menuItems: <FocusedMenuItem>[
                                    FocusedMenuItem(
                                        backgroundColor: Color(0xff252525),
                                        title: Text(
                                          "Delete",
                                          style: TextStyle(
                                              color: Colors.redAccent),
                                        ),
                                        trailingIcon: Icon(
                                          Icons.delete,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () {
                                          Playlist!.removeAt(files.indexOf(i));
                                          File(i.path).delete();
                                          files = dir!.listSync();
                                          playerr.pause();
                                          setState(() {});
                                        }),
                                  ],
                                  child: GestureDetector(
                                      onTap: () async {
                                        if (!dplay) {
                                          await playerr
                                              .setAudioSource(Playlist!);
                                          setState(() {
                                            play = false;
                                            title = i.path.split('/').last;
                                            playerr.seek(Duration.zero,
                                                index: files.indexOf(i));
                                            playerr.play();
                                            dplay = true;
                                          });
                                        } else {
                                          title = i.path.split('/').last;
                                          playerr.seek(Duration.zero,
                                              index: files.indexOf(i));
                                          playerr.play();
                                        }
                                      },
                                      child: Card(
                                          margin: EdgeInsets.only(bottom: 15),
                                          color: dplay &&
                                                  playerr
                                                          .sequenceState!
                                                          .currentSource!
                                                          .tag
                                                          .title ==
                                                      i.path.split('/').last
                                              ? Color(0xff1DB954)
                                              : Color(0xff252525),
                                          child: Padding(
                                              padding: EdgeInsets.all(20),
                                              child: Wrap(
                                                  spacing: 20,
                                                  crossAxisAlignment:
                                                      WrapCrossAlignment.center,
                                                  children: [
                                                    CircleAvatar(
                                                        radius: 25,
                                                        backgroundColor: dplay &&
                                                                playerr
                                                                        .sequenceState!
                                                                        .currentSource!
                                                                        .tag
                                                                        .title ==
                                                                    i.path
                                                                        .split(
                                                                            '/')
                                                                        .last
                                                            ? Color(0xff252525)
                                                            : Color(0xff1DB954),
                                                        child: Icon(
                                                          Icons.music_note,
                                                          color: Colors.white,
                                                          size: 40,
                                                        )),
                                                    SizedBox(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            (1.7 / 3),
                                                        child: Flex(
                                                            direction:
                                                                Axis.horizontal,
                                                            children: [
                                                              Expanded(
                                                                  child:
                                                                      RichText(
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                maxLines: 2,
                                                                text: TextSpan(
                                                                    locale:
                                                                        Locale(
                                                                            'en'),
                                                                    text: i.path
                                                                        .split(
                                                                            '/')
                                                                        .last,
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        height:
                                                                            1.5)),
                                                              ))
                                                            ]))
                                                  ])))))
                            ]
                          ],
                        ),
                      )
                    ],
                    play
                        ? player()
                        : dplay
                            ? player2()
                            : SizedBox.shrink()
                  ]));
        }));
  }

  String removeUnicodeApostrophes(String strInput) {
    // First remove the single slash.
    String strModified = strInput.replaceAll('&#39;', "\'");
    strModified = strModified.replaceAll('&quot;', "");

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
                                StreamBuilder<DurationState>(
                                    stream: _durationState,
                                    builder: (context, snapshot) {
                                      final durationState = snapshot.data;
                                      final progress =
                                          durationState?.progress ??
                                              Duration.zero;
                                      final buffered =
                                          durationState?.buffered ??
                                              Duration.zero;
                                      final total = durationState?.total ??
                                          playerr.duration ??
                                          Duration.zero;

                                      return Wrap(
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          spacing: !_isAudioLoading ? 30 : 45,
                                          children: [
                                            if (current - 1 >= 0) ...[
                                              IconButton(
                                                onPressed: () async {
                                                  if (progress <
                                                      Duration(seconds: 5)) {
                                                    setState(() {
                                                      current--;
                                                      playingNow =
                                                          nowVideo[current];
                                                    });
                                                    setState(() {
                                                      _isAudioLoading = true;
                                                      current = current;
                                                      playerr.stop();
                                                    });
                                                    var manifest = await yt
                                                        .videos.streamsClient
                                                        .getManifest(
                                                            playingNow!.url);
                                                    var streamInfo = manifest
                                                        .audioOnly
                                                        .withHighestBitrate();
                                                    stream = streamInfo;
                                                    setState(() {
                                                      _isAudioLoading = false;
                                                      playing = true;
                                                      _isAudioDownloading =
                                                          false;
                                                    });
                                                    playerr.setAudioSource(
                                                        ConcatenatingAudioSource(
                                                            children: [
                                                          AudioSource.uri(
                                                              streamInfo.url,
                                                              tag: MediaItem(
                                                                  id: playingNow!
                                                                      .id!,
                                                                  title: removeUnicodeApostrophes(
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
                                                  } else {
                                                    playerr.seek(Duration.zero);
                                                  }
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
                                                        icon: Icon(
                                                            Icons.play_arrow),
                                                        color: Colors.white,
                                                        iconSize: 50,
                                                      )
                                                : CircularProgressIndicator(
                                                    strokeWidth: 5,
                                                    color: Colors.white,
                                                  ),
                                            if (current + 1 <
                                                nowVideo.length) ...[
                                              IconButton(
                                                onPressed: () async {
                                                  setState(() {
                                                    current++;
                                                    playingNow =
                                                        nowVideo[current];
                                                  });
                                                  setState(() {
                                                    _isAudioLoading = true;
                                                    current = current;
                                                    playerr.stop();
                                                  });
                                                  var manifest = await yt
                                                      .videos.streamsClient
                                                      .getManifest(
                                                          playingNow!.url);
                                                  var streamInfo = manifest
                                                      .audioOnly
                                                      .withHighestBitrate();
                                                  stream = streamInfo;

                                                  setState(() {
                                                    _isAudioLoading = false;
                                                    _isAudioDownloading = false;
                                                    playing = true;
                                                  });
                                                  playerr.setAudioSource(
                                                      ConcatenatingAudioSource(
                                                          children: [
                                                        AudioSource.uri(
                                                            streamInfo.url,
                                                            tag: MediaItem(
                                                                id: playingNow!
                                                                    .id!,
                                                                title: removeUnicodeApostrophes(
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
                                          ]);
                                    })
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
                            !_isAudioDownloading
                                ? IconButton(
                                    onPressed: () async {
                                      setState(() {
                                        _isAudioDownloading = true;
                                      });
                                      var streams =
                                          yt.videos.streamsClient.get(stream!);
                                      var filee = File(
                                          'storage/emulated/0/Download/Tubify/' +
                                              removeUnicodeApostrophes(
                                                  playingNow!.title) +
                                              ".mp3");
                                      filee.create();
                                      var fileStream = filee.openWrite();
                                      await streams.pipe(fileStream);
                                      await fileStream.flush();
                                      await fileStream.close();
                                      setState(() {
                                        _isAudioDownloading = false;
                                      });
                                    },
                                    icon: Icon(Icons.download),
                                    color: Colors.white,
                                    iconSize: 30,
                                  )
                                : Padding(
                                    padding: EdgeInsets.only(right: 11),
                                    child: SizedBox(
                                        height: 25,
                                        width: 25,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ))),
                          ],
                        ))
                  ])));
  }

  Widget player2() {
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
                    padding: EdgeInsets.only(right: 28, left: 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                            backgroundColor: Colors.black,
                            radius: 25,
                            child: Icon(
                              Icons.music_note,
                              size: 30,
                              color: Colors.white,
                            )),
                        Spacer(),
                        Expanded(
                            flex: 6,
                            child: RichText(
                              maxLines: 3,
                              text: TextSpan(
                                  locale: Locale('en'),
                                  text: title,
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
                                Container(
                                    height: MediaQuery.of(context).size.height *
                                        (1.3 / 3),
                                    padding: EdgeInsets.only(
                                        top: 120, right: 20, left: 20),
                                    child: CircleAvatar(
                                        radius: 120,
                                        backgroundColor: Color(0xff252525),
                                        child: Icon(
                                          Icons.music_note,
                                          color: Colors.white,
                                          size: 120,
                                        ))),
                                Transform.translate(
                                    offset: Offset(0, 40),
                                    child: SizedBox(
                                        width: 340,
                                        child: RichText(
                                          text: TextSpan(
                                              locale: Locale('en'),
                                              text: title,
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
                                    final buffered = Duration.zero;
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
                                StreamBuilder<DurationState>(
                                    stream: _durationState,
                                    builder: (context, snapshot) {
                                      final durationState = snapshot.data;
                                      final progress =
                                          durationState?.progress ??
                                              Duration.zero;
                                      final buffered = Duration.zero;
                                      final total = durationState?.total ??
                                          playerr.duration ??
                                          Duration.zero;

                                      return Wrap(
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          spacing: 30,
                                          children: [
                                            if (playerr.hasPrevious) ...[
                                              IconButton(
                                                onPressed: () {
                                                  if (progress <
                                                      Duration(seconds: 5)) {
                                                    playerr.seekToPrevious();
                                                  } else {
                                                    playerr.seek(Duration.zero);
                                                  }
                                                },
                                                icon: Icon(Icons.skip_previous),
                                                color: Colors.white,
                                                iconSize: 50,
                                              ),
                                            ] else ...[
                                              SizedBox(
                                                width: 66,
                                              )
                                            ],
                                            playing
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
                                                    icon:
                                                        Icon(Icons.play_arrow),
                                                    color: Colors.white,
                                                    iconSize: 50,
                                                  ),
                                            if (playerr.hasNext) ...[
                                              IconButton(
                                                onPressed: () async {
                                                  playerr.seekToNext();
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
                                          ]);
                                    })
                              ])),
                        ]),
                    Padding(
                        padding: EdgeInsets.only(right: 5, left: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
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
                          ],
                        ))
                  ])));
  }

  getFiles() async {
    dir = Directory('storage/emulated/0/Download/Tubify');
    files = dir!.listSync();
    Playlist = ConcatenatingAudioSource(children: []);
    files.forEach((element) {
      Playlist!.add(AudioSource.uri(Uri.file(element.path),
          tag: MediaItem(
              id: element.path, title: element.path.split('/').last)));
    });
    setState(() {});
    // playerr.setAudioSource(ConcatenatingAudioSource(children: Playlist));
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

  _createFolder() async {
    final path = Directory('storage/emulated/0/Download/Tubify');
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => AlertDialog(
          actionsAlignment: MainAxisAlignment.spaceBetween,
          backgroundColor: Color(0xff252525),
          title: const Text(
            "Allow \"Tubify\" to access your files while using the app",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          titleTextStyle: TextStyle(fontFamily: 'Gotham', fontSize: 18),
          content: const Text(
            "the app will access the files to be able to play your downloaded audios.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          actions: [
            TextButton(
                child: const Text("Deny Access"),
                onPressed: () async {
                  Navigator.pop(context);
                }),
            TextButton(
                child: const Text("Allow Access"),
                onPressed: () async {
                  Navigator.pop(context);
                  await Permission.manageExternalStorage.request();
                  getFiles();
                  setState(() {});
                }),
          ],
        ),
      );
    } else {
      getFiles();
      setState(() {});
    }

    if ((await path.exists())) {
      return path.path;
    } else {
      path.create();
      return path.path;
    }
  }
}

class DurationState {
  const DurationState(
      {required this.progress, required this.buffered, this.total});
  final Duration progress;
  final Duration buffered;
  final Duration? total;
}
