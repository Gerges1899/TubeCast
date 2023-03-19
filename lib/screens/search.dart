// ignore_for_file: depend_on_referenced_packages, non_constant_identifier_names, use_build_context_synchronously, empty_catches, prefer_interpolation_to_compose_strings

import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:tube_cast/constants.dart';
import 'package:youtube_api/youtube_api.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:rxdart/rxdart.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:youtube_data_api/youtube_data_api.dart' as ytu;
import 'package:searchfield/searchfield.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:focused_menu_custom/focused_menu.dart';
import 'package:focused_menu_custom/modals.dart';
import 'package:ionicons/ionicons.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
import 'package:flutter_flushbar/flutter_flushbar.dart';
import 'package:path/path.dart' as p;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController controller = TextEditingController();
  YoutubeAPI ytApi =
      YoutubeAPI(constants.strictKey, maxResults: 500, type: "video");
  ytu.YoutubeDataApi youtubeDataApi = ytu.YoutubeDataApi();
  FocusNode ff = FocusNode();
  List<YouTubeVideo> videoResult = [];
  List<YouTubeVideo> nowVideo = [];
  YouTubeVideo? playingNow;
  bool clicked = false;
  bool _isLoading = true;
  bool _isAudioLoading = false;
  bool _isAudioDownloading = false;
  bool trending = true;
  bool play = false;
  bool dplay = false;
  bool playing = false;
  int current = -1;
  int downloadIndex = -1;
  double height = 80;
  bool notFound = false;
  bool visible = true;
  bool downloads = false;
  bool playlist = false;
  ConcatenatingAudioSource? Playlist;
  final ReceivePort _port = ReceivePort();
  String title = '';
  ConnectivityResult connected = ConnectivityResult.none;
  Stream<DurationState>? _durationState;
  List<String> suggestions = [];
  var yt = YoutubeExplode();
  final playerr = AudioPlayer();
  AudioOnlyStreamInfo? stream;
  Widget playicon = const Icon(Icons.pause);
  Directory? dir;
  List<FileSystemEntity> files = [];
  List<Directory> playlists = [];
  @override
  void initState() {
    _createFolder();
    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      // if (status == DownloadTaskStatus.complete) {
      //   try {
      //     Playlist!.add(AudioSource.uri(
      //         Uri.parse('${dir!.path}/Tubify/' +
      //             removeUnicodeApostrophes(videoResult[downloadIndex].title) +
      //             ".mp3"),
      //         tag: MediaItem(
      //             id: '${dir!.path}/Tubify/' +
      //                 removeUnicodeApostrophes(
      //                     videoResult[downloadIndex].title) +
      //                 ".mp3",
      //             title:
      //                 "${removeUnicodeApostrophes(videoResult[downloadIndex].title)}.mp3")));
      //     files = dir!.listSync();
      //   } catch (err) {}
      // }
      setState(() {});
    });

    FlutterDownloader.registerCallback(downloadCallback);
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
      if (event!.currentSource != null) {
        title = event.currentSource!.tag.title;
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    playerr.dispose();
    yt.close();
    super.dispose();
  }

  @pragma('vm:entry-point')
  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort? send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send!.send([id, status, progress]);
  }

  Future download(String url, String name, String playlist) async {
    await FlutterDownloader.enqueue(
      timeout: 3000,
      url: url,
      fileName: name,
      headers: {},
      savedDir: playlist.isEmpty ? dir!.path : dir!.path + '/${playlist}',
      showNotification: true,
      openFileFromNotification: false,
    );
  }

  @override
  void reassemble() {
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
                decoration: const BoxDecoration(color: Colors.black),
                child: Container(
                    padding: const EdgeInsets.all(20),
                    child: SvgPicture.asset(
                      'assets/Horizontal.svg',
                      fit: BoxFit.scaleDown,
                    )),
              ),
              Transform.translate(
                  offset: const Offset(0, -15),
                  child: const Divider(
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
                  icon: const Icon(
                    Ionicons.trending_up_outline,
                    size: 30,
                  ),
                  label: const Text(
                    'Trending Music',
                    style: TextStyle(fontSize: 20, fontFamily: 'Gotham'),
                  )),
              const Padding(padding: EdgeInsets.only(top: 15)),
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
                  icon: const Icon(
                    Ionicons.search_outline,
                    size: 30,
                  ),
                  label: const Text(
                    'Search results',
                    style: TextStyle(fontSize: 20, fontFamily: 'Gotham'),
                  )),
              const Padding(padding: EdgeInsets.only(top: 15)),
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
                      playlist = false;
                      Scaffold.of(context).closeDrawer();
                    });
                    setState(() {});
                  },
                  icon: const Icon(
                    Ionicons.cloud_download_outline,
                    size: 30,
                  ),
                  label: const Text(
                    'Downloads',
                    style: TextStyle(fontSize: 20, fontFamily: 'Gotham'),
                  ))
            ]),
          );
        }),
        appBar: AppBar(
            toolbarHeight: kToolbarHeight + 3,
            leading: Builder(
              builder: (BuildContext context) {
                return IconButton(
                  iconSize: 40,
                  icon: const Icon(
                    Ionicons.reorder_two_outline,
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
                      icon: const Icon(
                        Ionicons.close_outline,
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
                      iconSize: 25,
                      icon: const Icon(
                        Ionicons.search,
                        size: 28,
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
            backgroundColor: Colors.black,
            title: SvgPicture.asset(
              'assets/tubifylogo.svg',
              height: 32,
              width: 200,
            ),
            bottom: clicked
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(90),
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                        child: SearchField<String>(
                            focusNode: ff,
                            marginColor: const Color(0xff141414),
                            suggestions: downloads
                                ? []
                                : suggestions
                                    .map((e) => SearchFieldListItem<String>(e,
                                        child: Padding(
                                            padding:
                                                const EdgeInsets.only(left: 10),
                                            child: Text(
                                              e,
                                              style: const TextStyle(
                                                  height: 1.5,
                                                  color: Color(0xff141414),
                                                  fontFamily: 'Gotham'),
                                            ))))
                                    .toList(),
                            searchStyle: const TextStyle(color: Colors.white),
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
                              enabledBorder: const OutlineInputBorder(
                                borderSide:
                                    BorderSide(width: 1, color: Colors.white),
                              ),
                              fillColor: Colors.transparent,
                              filled: true,
                              hintText: 'Search',
                              hintStyle: const TextStyle(color: Colors.white),
                              constraints: const BoxConstraints(maxHeight: 100),
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
                                      icon: const Icon(Ionicons.close)),
                            ))),
                  )
                : const PreferredSize(
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
                                const Padding(
                                    padding: EdgeInsets.fromLTRB(28, 20, 28, 0),
                                    child: Text(
                                      'Trending music Right Now ..',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Gotham'),
                                    ))
                              ] else if (!trending && !_isLoading) ...[
                                if (!notFound) ...[
                                  const Padding(
                                      padding:
                                          EdgeInsets.fromLTRB(28, 20, 28, 0),
                                      child: Text(
                                        'Your Search Results ..',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Gotham'),
                                      ))
                                ] else ...[
                                  const Padding(
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
                              const Padding(
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
                                  FocusedMenuHolder(
                                      widthBorder: 0,
                                      menuItemExtent: 45,
                                      menuWidth:
                                          MediaQuery.of(context).size.width,
                                      animateMenuItems: true,
                                      blurSize: 0.25,
                                      blurBackgroundColor: Colors.black54,
                                      menuOffset: -20,
                                      borderColor: const Color(0xff141414),
                                      openWithTap: false,
                                      onPressed: () {},
                                      menuItems: <FocusedMenuItem>[
                                        FocusedMenuItem(
                                            backgroundColor:
                                                const Color(0xff141414),
                                            title: const Text(
                                              "Download",
                                              style: TextStyle(
                                                  color: Color(0xff3e4da0)),
                                            ),
                                            trailingIcon: const Icon(
                                              Ionicons.cloud_download_outline,
                                              color: Color(0xff3e4da0),
                                            ),
                                            onPressed: () async {
                                              setState(() {
                                                _isAudioDownloading = true;
                                                downloadIndex = i;
                                              });
                                              await _createFolder();
                                              var manifest = await yt
                                                  .videos.streamsClient
                                                  .getManifest(
                                                      videoResult[i].url);
                                              var streamInfo = manifest
                                                  .audioOnly
                                                  .withHighestBitrate();
                                              stream = streamInfo;

                                              await download(
                                                  stream!.url.toString(),
                                                  "${removeUnicodeApostrophes2(videoResult[i].title)}.mp3",
                                                  '');
                                              Flushbar(
                                                duration:
                                                    const Duration(seconds: 2),
                                                backgroundColor:
                                                    const Color(0xff141414),
                                                flushbarPosition:
                                                    FlushbarPosition.TOP,
                                                title: "Tubify",
                                                message:
                                                    "\naudio is started to download.",
                                              ).show(context);
                                              setState(() {
                                                _isAudioDownloading = false;
                                              });
                                            }),
                                        FocusedMenuItem(
                                            backgroundColor:
                                                const Color(0xff141414),
                                            title: const Text(
                                              "Download to an existing Playlist",
                                              style: TextStyle(
                                                  color: Color(0xff3e4da0)),
                                            ),
                                            trailingIcon: const Icon(
                                              Ionicons.cloud_download_outline,
                                              color: Color(0xff3e4da0),
                                            ),
                                            onPressed: () async {
                                              String playlist = '';
                                              showDialog(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                        backgroundColor:
                                                            Color(0xff141414),
                                                        title: Text(
                                                          'your playlists.',
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.white),
                                                        ),
                                                        content:
                                                            StatefulBuilder(
                                                          // You need this, notice the parameters below:
                                                          builder: (BuildContext
                                                                  ctx,
                                                              StateSetter
                                                                  _setState) {
                                                            return Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                for (var j
                                                                    in playlists) ...[
                                                                  RadioListTile(
                                                                    activeColor:
                                                                        Color(
                                                                            0xff3e4da0),
                                                                    toggleable:
                                                                        true,
                                                                    title: Text(
                                                                      j.path
                                                                          .split(
                                                                              '/')
                                                                          .last,
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white,
                                                                          fontSize:
                                                                              12),
                                                                    ),
                                                                    value: j
                                                                        .path
                                                                        .split(
                                                                            '/')
                                                                        .last,
                                                                    groupValue:
                                                                        playlist,
                                                                    onChanged:
                                                                        (value) {
                                                                      _setState(
                                                                          () {
                                                                        playlist =
                                                                            value.toString();
                                                                      });
                                                                    },
                                                                  )
                                                                ],
                                                              ],
                                                            );
                                                          },
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                              child: const Text(
                                                                  "Done"),
                                                              onPressed:
                                                                  () async {
                                                                Navigator.pop(
                                                                    ctx);
                                                                setState(() {
                                                                  _isAudioDownloading =
                                                                      true;
                                                                  downloadIndex =
                                                                      i;
                                                                });
                                                                await _createFolder();
                                                                var manifest = await yt
                                                                    .videos
                                                                    .streamsClient
                                                                    .getManifest(
                                                                        videoResult[i]
                                                                            .url);
                                                                var streamInfo =
                                                                    manifest
                                                                        .audioOnly
                                                                        .withHighestBitrate();
                                                                stream =
                                                                    streamInfo;

                                                                await download(
                                                                    stream!.url
                                                                        .toString(),
                                                                    "${removeUnicodeApostrophes2(videoResult[i].title)}.mp3",
                                                                    playlist);
                                                                Flushbar(
                                                                  duration:
                                                                      const Duration(
                                                                          seconds:
                                                                              2),
                                                                  backgroundColor:
                                                                      const Color(
                                                                          0xff141414),
                                                                  flushbarPosition:
                                                                      FlushbarPosition
                                                                          .TOP,
                                                                  title:
                                                                      "Tubify",
                                                                  message:
                                                                      "\naudio is started to download.",
                                                                ).show(context);
                                                                setState(() {
                                                                  _isAudioDownloading =
                                                                      false;
                                                                });
                                                              }),
                                                        ],
                                                      ));
                                            }),
                                        FocusedMenuItem(
                                            backgroundColor:
                                                const Color(0xff141414),
                                            title: const Text(
                                              "Download to new Playlist",
                                              style: TextStyle(
                                                  color: Color(0xff3e4da0)),
                                            ),
                                            trailingIcon: const Icon(
                                              Ionicons.cloud_download_outline,
                                              color: Color(0xff3e4da0),
                                            ),
                                            onPressed: () async {
                                              String playlist = '';
                                              final GlobalKey<FormState>
                                                  _formKey =
                                                  GlobalKey<FormState>();
                                              showDialog(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                        backgroundColor:
                                                            Color(0xff141414),
                                                        title: Text(
                                                          'Add new Playlist',
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.white),
                                                        ),
                                                        content:
                                                            StatefulBuilder(
                                                          builder: (BuildContext
                                                                  ctx,
                                                              StateSetter
                                                                  _setState) {
                                                            return Form(
                                                                key: _formKey,
                                                                child:
                                                                    TextFormField(
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white),
                                                                  validator: (value) =>
                                                                      value!.isEmpty
                                                                          ? 'please enter playlist name'
                                                                          : null,
                                                                  onChanged:
                                                                      (value) {
                                                                    playlist =
                                                                        value;
                                                                    _setState(
                                                                        () {});
                                                                  },
                                                                  decoration:
                                                                      InputDecoration(
                                                                    hintText:
                                                                        'playlist name',
                                                                    hintStyle: TextStyle(
                                                                        color: Colors
                                                                            .grey,
                                                                        fontSize:
                                                                            12),
                                                                    enabledBorder:
                                                                        const OutlineInputBorder(
                                                                      borderSide: BorderSide(
                                                                          width:
                                                                              1,
                                                                          color:
                                                                              Colors.white),
                                                                    ),
                                                                    focusedBorder:
                                                                        const OutlineInputBorder(
                                                                      borderSide: BorderSide(
                                                                          width:
                                                                              1,
                                                                          color:
                                                                              Color(0xff3e4da0)),
                                                                    ),
                                                                    focusedErrorBorder:
                                                                        const OutlineInputBorder(
                                                                      borderSide: BorderSide(
                                                                          width:
                                                                              1,
                                                                          color:
                                                                              Colors.red),
                                                                    ),
                                                                  ),
                                                                ));
                                                          },
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                              child: const Text(
                                                                  "Done"),
                                                              onPressed:
                                                                  () async {
                                                                if (_formKey
                                                                    .currentState!
                                                                    .validate()) {
                                                                  Navigator.pop(
                                                                      ctx);
                                                                  if (!await Directory(
                                                                          dir!.path +
                                                                              '/${playlist}')
                                                                      .exists()) {
                                                                    Directory(dir!.path +
                                                                            '/${playlist}')
                                                                        .create()
                                                                        .then(
                                                                            (value) async {
                                                                      setState(
                                                                          () {
                                                                        _isAudioDownloading =
                                                                            true;
                                                                        downloadIndex =
                                                                            i;
                                                                      });
                                                                      await _createFolder();
                                                                      var manifest = await yt
                                                                          .videos
                                                                          .streamsClient
                                                                          .getManifest(
                                                                              videoResult[i].url);
                                                                      var streamInfo = manifest
                                                                          .audioOnly
                                                                          .withHighestBitrate();
                                                                      stream =
                                                                          streamInfo;

                                                                      await download(
                                                                          stream!
                                                                              .url
                                                                              .toString(),
                                                                          "${removeUnicodeApostrophes2(videoResult[i].title)}.mp3",
                                                                          playlist);
                                                                      Flushbar(
                                                                        duration:
                                                                            const Duration(seconds: 2),
                                                                        backgroundColor:
                                                                            const Color(0xff141414),
                                                                        flushbarPosition:
                                                                            FlushbarPosition.TOP,
                                                                        title:
                                                                            "Tubify",
                                                                        message:
                                                                            "\naudio is started to download.",
                                                                      ).show(
                                                                          context);
                                                                      setState(
                                                                          () {
                                                                        _isAudioDownloading =
                                                                            false;
                                                                      });
                                                                    });
                                                                  } else {
                                                                    setState(
                                                                        () {
                                                                      _isAudioDownloading =
                                                                          true;
                                                                      downloadIndex =
                                                                          i;
                                                                    });
                                                                    await _createFolder();
                                                                    var manifest = await yt
                                                                        .videos
                                                                        .streamsClient
                                                                        .getManifest(
                                                                            videoResult[i].url);
                                                                    var streamInfo =
                                                                        manifest
                                                                            .audioOnly
                                                                            .withHighestBitrate();
                                                                    stream =
                                                                        streamInfo;

                                                                    await download(
                                                                        stream!
                                                                            .url
                                                                            .toString(),
                                                                        "${removeUnicodeApostrophes2(videoResult[i].title)}.mp3",
                                                                        playlist);
                                                                    Flushbar(
                                                                      duration: const Duration(
                                                                          seconds:
                                                                              2),
                                                                      backgroundColor:
                                                                          const Color(
                                                                              0xff141414),
                                                                      flushbarPosition:
                                                                          FlushbarPosition
                                                                              .TOP,
                                                                      title:
                                                                          "Tubify",
                                                                      message:
                                                                          "\naudio is started to download.",
                                                                    ).show(
                                                                        context);
                                                                    setState(
                                                                        () {
                                                                      _isAudioDownloading =
                                                                          false;
                                                                    });
                                                                  }
                                                                }
                                                              }),
                                                        ],
                                                      ));
                                            }),
                                      ],
                                      child: Container(
                                          height: 285,
                                          padding: const EdgeInsets.fromLTRB(
                                              28, 15, 28, 0),
                                          child: GestureDetector(
                                              onTap: () async {
                                                setState(() {
                                                  _isAudioDownloading = false;
                                                  _isAudioLoading = true;
                                                  current = i;
                                                  playingNow =
                                                      videoResult[current];
                                                  playerr.stop();
                                                  nowVideo = videoResult;
                                                  dplay = false;
                                                  play = true;
                                                });
                                                var manifest = await yt
                                                    .videos.streamsClient
                                                    .getManifest(
                                                        videoResult[i].url);
                                                var streamInfo = manifest
                                                    .audioOnly
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
                                                              title: removeUnicodeApostrophes(
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
                                                        BorderRadius.circular(
                                                            5),
                                                  ),
                                                  color:
                                                      const Color(0xff141414),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
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
                                                                            borderRadius:
                                                                                const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
                                                                            child: FadeInImage.assetNetwork(image: videoResult[i].thumbnail.medium.url!, placeholder: 'assets/placeholder.png', height: 180, fit: BoxFit.fitHeight)),
                                                                        Center(
                                                                            child:
                                                                                CircleAvatar(
                                                                          radius:
                                                                              27,
                                                                          backgroundColor:
                                                                              const Color(0xff3e4da0),
                                                                          child: _isAudioDownloading && downloadIndex == i
                                                                              ? const SizedBox(
                                                                                  height: 20,
                                                                                  width: 20,
                                                                                  child: CircularProgressIndicator(
                                                                                    color: Colors.white,
                                                                                  ))
                                                                              : const Padding(
                                                                                  padding: EdgeInsets.only(bottom: 4, left: 5),
                                                                                  child: Icon(
                                                                                    Ionicons.play_outline,
                                                                                    color: Colors.white,
                                                                                    size: 35,
                                                                                  )),
                                                                        )),
                                                                      ]),
                                                                  Container(
                                                                    alignment:
                                                                        Alignment
                                                                            .centerRight,
                                                                    padding: const EdgeInsets
                                                                            .only(
                                                                        bottom:
                                                                            5,
                                                                        right:
                                                                            5),
                                                                    child: Text(
                                                                      videoResult[
                                                                              i]
                                                                          .duration
                                                                          .toString(),
                                                                      style: const TextStyle(
                                                                          color:
                                                                              Colors.white),
                                                                    ),
                                                                  ),
                                                                ]),
                                                            Transform.translate(
                                                                offset:
                                                                    const Offset(
                                                                        0, 8),
                                                                child:
                                                                    const Divider(
                                                                  color: Color(
                                                                      0xff3e4da0),
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
                                                                        const EdgeInsets.fromLTRB(
                                                                            20,
                                                                            15,
                                                                            20,
                                                                            2),
                                                                    child:
                                                                        RichText(
                                                                      maxLines:
                                                                          2,
                                                                      text: TextSpan(
                                                                          locale: const Locale(
                                                                              'en'),
                                                                          text: removeUnicodeApostrophes(videoResult[i]
                                                                              .title),
                                                                          style: const TextStyle(
                                                                              color: Colors.white,
                                                                              height: 1.5)),
                                                                    )))
                                                          ])
                                                    ],
                                                  )))))
                                ],
                                if (play || dplay) ...[
                                  SizedBox(
                                    height: 80,
                                  )
                                ]
                              ] else ...[
                                Center(
                                    child: Transform.translate(
                                        offset: const Offset(0, 25),
                                        child:
                                            const CircularProgressIndicator())),
                              ]
                            ]
                          ])))
                    ] else if (downloads && !playlist) ...[
                      Container(
                        color: Colors.black,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
                          children: [
                            const Padding(
                                padding: EdgeInsets.fromLTRB(0, 10, 0, 15),
                                child: Text(
                                  'Your playlists.',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Gotham',
                                      height: 1.5),
                                )),
                            for (var i in playlists) ...[
                              FocusedMenuHolder(
                                  menuItemExtent: 45,
                                  menuWidth:
                                      MediaQuery.of(context).size.width * 0.50,
                                  animateMenuItems: true,
                                  blurSize: 0.25,
                                  blurBackgroundColor: Colors.black54,
                                  menuOffset: -20,
                                  borderColor: const Color(0xff141414),
                                  openWithTap: false,
                                  onPressed: () {},
                                  menuItems: <FocusedMenuItem>[
                                    FocusedMenuItem(
                                        backgroundColor:
                                            const Color(0xff141414),
                                        title: const Text(
                                          "Delete",
                                          style: TextStyle(
                                              color: Colors.redAccent),
                                        ),
                                        trailingIcon: const Icon(
                                          Icons.delete,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () async {
                                          if (Directory(i.path)
                                                  .listSync()
                                                  .length >
                                              0) {
                                            Directory(i.path)
                                                .listSync()
                                                .forEach((element) async {
                                              await File(element.path).rename(dir!
                                                      .path +
                                                  '/${element.path.split('/').last}');
                                            });
                                          }
                                          await Directory(i.path).delete();
                                          await getFiles();
                                          playerr.setAudioSource(Playlist!);
                                          dplay = play = false;
                                          playerr.stop();
                                          setState(() {});
                                        }),
                                  ],
                                  child: GestureDetector(
                                      onTap: () async {
                                        // if (!dplay) {
                                        //   await playerr
                                        //       .setAudioSource(Playlist!);
                                        //   setState(() {
                                        //     play = false;
                                        //     title = i.path.split('/').last;
                                        //     playerr.seek(Duration.zero,
                                        //         index: files.indexOf(i));
                                        //     playerr.play();
                                        //     dplay = true;
                                        //   });
                                        // } else {
                                        //   title = i.path.split('/').last;
                                        //   playerr.seek(Duration.zero,
                                        //       index: files.indexOf(i));
                                        //   playerr.play();
                                        // }
                                      },
                                      child: Card(
                                          margin:
                                              const EdgeInsets.only(bottom: 15),
                                          color: const Color(0xff141414),
                                          child: Padding(
                                              padding: const EdgeInsets.all(20),
                                              child: Wrap(
                                                  spacing: 20,
                                                  crossAxisAlignment:
                                                      WrapCrossAlignment.center,
                                                  children: [
                                                    const CircleAvatar(
                                                        radius: 25,
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        child: Icon(
                                                          Icons
                                                              .my_library_music,
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
                                                                        const Locale(
                                                                            'en'),
                                                                    text: i.path
                                                                        .split(
                                                                            '/')
                                                                        .last,
                                                                    style: const TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        height:
                                                                            1.5)),
                                                              ))
                                                            ]))
                                                  ]))))),
                            ],
                            const Padding(
                                padding: EdgeInsets.fromLTRB(0, 10, 0, 15),
                                child: Text(
                                  'All Downloads.',
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
                                  borderColor: const Color(0xff141414),
                                  openWithTap: false,
                                  onPressed: () {},
                                  menuItems: <FocusedMenuItem>[
                                    FocusedMenuItem(
                                        backgroundColor:
                                            const Color(0xff141414),
                                        title: const Text(
                                          "Delete",
                                          style: TextStyle(
                                              color: Colors.redAccent),
                                        ),
                                        trailingIcon: const Icon(
                                          Icons.delete,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () {
                                          bool pl = false;
                                          if (playerr.sequenceState != null) {
                                            pl = i.path.split('/').last ==
                                                playerr.sequenceState!
                                                    .currentSource!.tag.title;
                                            if (pl) {
                                              playerr.stop();
                                              dplay = false;
                                            }
                                            Playlist!
                                                .removeAt(files.indexOf(i));
                                          }
                                          File(i.path).delete();
                                          files = [];
                                          playlists = [];
                                          dir!
                                              .listSync(recursive: true)
                                              .forEach((element) {
                                            if (p.extension(element.path) ==
                                                '.mp3') {
                                              files.add(element);
                                            } else if (element is Directory) {
                                              playlists.add(element);
                                            }
                                          });

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
                                          margin:
                                              const EdgeInsets.only(bottom: 15),
                                          color: dplay &&
                                                  playerr
                                                          .sequenceState!
                                                          .currentSource!
                                                          .tag
                                                          .title ==
                                                      i.path.split('/').last
                                              ? const Color(0xff3e4da0)
                                              : const Color(0xff141414),
                                          child: Padding(
                                              padding: const EdgeInsets.all(20),
                                              child: Wrap(
                                                  spacing: 20,
                                                  crossAxisAlignment:
                                                      WrapCrossAlignment.center,
                                                  children: [
                                                    const CircleAvatar(
                                                        radius: 25,
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        child: Icon(
                                                          Ionicons
                                                              .musical_notes_outline,
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
                                                                        const Locale(
                                                                            'en'),
                                                                    text: i.path
                                                                        .split(
                                                                            '/')
                                                                        .last,
                                                                    style: const TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        height:
                                                                            1.5)),
                                                              ))
                                                            ]))
                                                  ]))))),
                            ],
                            if (dplay || play) ...[
                              SizedBox(
                                height: 80,
                              )
                            ]
                          ],
                        ),
                      )
                    ] else if (downloads && playlist)
                      ...[],
                    play
                        ? player()
                        : dplay
                            ? player2()
                            : const SizedBox.shrink()
                  ]));
        }));
  }

  String removeUnicodeApostrophes(String strInput) {
    String strModified = strInput.replaceAll('&#39;', "\'");
    strModified = strModified.replaceAll('&quot;', "");
    strModified = strModified.replaceAll('&amp;', "&");
    return strModified;
  }

  String removeUnicodeApostrophes2(String strInput) {
    String strModified = strInput.replaceAll('&#39;', "\'");
    strModified = strModified.replaceAll('&quot;', "");
    strModified = strModified.replaceAll('&amp;', "&");
    strModified = strModified.replaceAll('/', "-");
    strModified = strModified.replaceAll('|', "-");
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
                      Colors.black,
                      const Color(0xff3e4da0),
                    ]
                  : [
                      Colors.black,
                      const Color(0xff3e4da0),
                      Colors.blueGrey,
                    ],
            )),
            height: height,
            child: height == 80
                ? Padding(
                    padding: const EdgeInsets.only(right: 28),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.network(playingNow!.thumbnail.small.url!),
                        const Spacer(),
                        Expanded(
                            flex: 5,
                            child: RichText(
                              maxLines: 3,
                              text: TextSpan(
                                  locale: const Locale('en'),
                                  text: removeUnicodeApostrophes(
                                      playingNow!.title),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      height: 1.5,
                                      fontSize: 11)),
                            )),
                        const Spacer(),
                        !_isAudioLoading
                            ? playing
                                ? IconButton(
                                    onPressed: () {
                                      setState(() {
                                        playerr.pause();
                                        playing = !playing;
                                      });
                                    },
                                    icon: const Icon(Ionicons.pause_outline),
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
                                    icon: const Icon(Ionicons.play_outline),
                                    color: Colors.white,
                                    iconSize: 30,
                                  )
                            : const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                      ],
                    ))
                : Container(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    alignment: Alignment.topCenter,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      // mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                            padding: const EdgeInsets.only(right: 5, left: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      height = 80;
                                    });
                                  },
                                  icon:
                                      const Icon(Ionicons.chevron_down_outline),
                                  color: Colors.white,
                                  iconSize: 30,
                                ),
                                !_isAudioDownloading
                                    ? IconButton(
                                        onPressed: () async {
                                          setState(() {
                                            _isAudioDownloading = true;
                                            downloadIndex = current;
                                          });
                                          await _createFolder();
                                          await download(
                                              stream!.url.toString(),
                                              "${removeUnicodeApostrophes2(playingNow!.title)}.mp3",
                                              '');
                                          Flushbar(
                                            duration:
                                                const Duration(seconds: 2),
                                            backgroundColor:
                                                const Color(0xff141414),
                                            flushbarPosition:
                                                FlushbarPosition.TOP,
                                            title: "Tubify",
                                            message:
                                                "\naudio is started to download.",
                                          ).show(context);
                                          setState(() {
                                            _isAudioDownloading = false;
                                          });
                                        },
                                        icon: const Icon(
                                            Ionicons.cloud_download_outline),
                                        color: Colors.white,
                                        iconSize: 30,
                                      )
                                    : const Padding(
                                        padding: EdgeInsets.only(right: 11),
                                        child: SizedBox(
                                            height: 25,
                                            width: 25,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ))),
                              ],
                            )),
                        Padding(
                            padding: EdgeInsets.only(
                                top: MediaQuery.of(context).size.height / 20,
                                right: 20,
                                left: 20),
                            child: Image.network(
                              playingNow!.thumbnail.high.url!,
                              fit: BoxFit.fitWidth,
                            )),
                        Container(
                            padding: EdgeInsets.only(
                                top: MediaQuery.of(context).size.height / 20,
                                right: 20,
                                left: 20),
                            width: 340,
                            child: RichText(
                              text: TextSpan(
                                  locale: const Locale('en'),
                                  text: removeUnicodeApostrophes(
                                      playingNow!.title),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      height: 1.5,
                                      fontSize: 16)),
                            )),
                        StreamBuilder<DurationState>(
                          stream: _durationState,
                          builder: (context, snapshot) {
                            final durationState = snapshot.data;
                            final progress =
                                durationState?.progress ?? Duration.zero;
                            final buffered =
                                durationState?.buffered ?? Duration.zero;
                            final total = durationState?.total ??
                                playerr.duration ??
                                Duration.zero;

                            return Padding(
                                padding: EdgeInsets.only(
                                    top:
                                        MediaQuery.of(context).size.height / 20,
                                    left: 20,
                                    right: 20),
                                child: ProgressBar(
                                  timeLabelPadding: 5,
                                  timeLabelTextStyle:
                                      const TextStyle(color: Colors.white),
                                  progress: progress,
                                  buffered: buffered,
                                  total: total,
                                  progressBarColor: const Color(0xff141414),
                                  baseBarColor: Colors.white.withOpacity(0.24),
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
                                  durationState?.progress ?? Duration.zero;
                              final buffered =
                                  durationState?.buffered ?? Duration.zero;
                              final total = durationState?.total ??
                                  playerr.duration ??
                                  Duration.zero;

                              return Padding(
                                  padding: EdgeInsets.only(
                                      top: MediaQuery.of(context).size.height /
                                          20,
                                      left: 40,
                                      right: 40),
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      // spacing: !_isAudioLoading ? 30 : 45,
                                      children: [
                                        if (current - 1 >= 0) ...[
                                          IconButton(
                                            onPressed: () async {
                                              if (progress <
                                                  const Duration(seconds: 5)) {
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
                                                  _isAudioDownloading = false;
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
                                            icon: const Icon(Ionicons
                                                .play_skip_back_outline),
                                            color: Colors.white,
                                            iconSize: 50,
                                          )
                                        ] else ...[
                                          const SizedBox(
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
                                                    icon: const Icon(
                                                        Ionicons.pause_outline),
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
                                                    icon: const Icon(
                                                        Ionicons.play_outline),
                                                    color: Colors.white,
                                                    iconSize: 50,
                                                  )
                                            : const CircularProgressIndicator(
                                                strokeWidth: 5,
                                                color: Colors.white,
                                              ),
                                        if (current + 1 < nowVideo.length) ...[
                                          IconButton(
                                            onPressed: () async {
                                              setState(() {
                                                current++;
                                                playingNow = nowVideo[current];
                                              });
                                              setState(() {
                                                _isAudioLoading = true;
                                                current = current;
                                                playerr.stop();
                                              });
                                              var manifest = await yt
                                                  .videos.streamsClient
                                                  .getManifest(playingNow!.url);
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
                                                            id: playingNow!.id!,
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
                                            icon: const Icon(Ionicons
                                                .play_skip_forward_outline),
                                            color: Colors.white,
                                            iconSize: 50,
                                          )
                                        ] else ...[
                                          const SizedBox(
                                            width: 66,
                                          )
                                        ],
                                      ]));
                            })
                      ],
                    ))));
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
                      Colors.black,
                      // Color(0xff1DB954),
                      const Color(0xff3e4da0),
                    ]
                  : [
                      Colors.black,
                      const Color(0xff3e4da0),
                      Colors.blueGrey,
                    ],
            )),
            height: height,
            child: height == 80
                ? Padding(
                    padding: const EdgeInsets.only(right: 28, left: 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                            backgroundColor: Colors.transparent,
                            radius: 25,
                            child: Icon(
                              Ionicons.musical_notes_outline,
                              size: 30,
                              color: Colors.white,
                            )),
                        const Spacer(),
                        Expanded(
                            flex: 6,
                            child: RichText(
                              maxLines: 3,
                              text: TextSpan(
                                  locale: const Locale('en'),
                                  text: title,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      height: 1.5,
                                      fontSize: 11)),
                            )),
                        const Spacer(),
                        playing
                            ? IconButton(
                                onPressed: () {
                                  setState(() {
                                    playerr.pause();
                                    playing = !playing;
                                  });
                                },
                                icon: const Icon(Ionicons.pause_outline),
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
                                icon: const Icon(Ionicons.play_outline),
                                color: Colors.white,
                                iconSize: 30,
                              )
                      ],
                    ))
                : Container(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    alignment: Alignment.topCenter,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                              padding: const EdgeInsets.only(right: 5, left: 5),
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
                                    icon: const Icon(
                                        Ionicons.chevron_down_outline),
                                    color: Colors.white,
                                    iconSize: 30,
                                  ),
                                ],
                              )),
                          Padding(
                              padding: EdgeInsets.only(
                                  top: MediaQuery.of(context).size.height / 20,
                                  left: 20,
                                  right: 20),
                              child: const CircleAvatar(
                                  radius: 120,
                                  backgroundColor: Colors.transparent,
                                  child: Icon(
                                    Ionicons.musical_notes_outline,
                                    color: Colors.white,
                                    size: 120,
                                  ))),
                          Padding(
                              padding: EdgeInsets.only(
                                  top: MediaQuery.of(context).size.height / 20,
                                  left: 20,
                                  right: 20),
                              child: SizedBox(
                                  width: 340,
                                  child: RichText(
                                    text: TextSpan(
                                        locale: const Locale('en'),
                                        text: title,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            height: 1.5,
                                            fontSize: 16)),
                                  ))),
                          StreamBuilder<DurationState>(
                            stream: _durationState,
                            builder: (context, snapshot) {
                              final durationState = snapshot.data;
                              final progress =
                                  durationState?.progress ?? Duration.zero;
                              final buffered = Duration.zero;
                              final total = durationState?.total ??
                                  playerr.duration ??
                                  Duration.zero;

                              return Padding(
                                  padding: EdgeInsets.only(
                                      top: MediaQuery.of(context).size.height /
                                          20,
                                      left: 20,
                                      right: 20),
                                  child: ProgressBar(
                                    timeLabelPadding: 5,
                                    timeLabelTextStyle:
                                        const TextStyle(color: Colors.white),
                                    progress: progress,
                                    buffered: buffered,
                                    total: total,
                                    progressBarColor: const Color(0xff141414),
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
                                    durationState?.progress ?? Duration.zero;
                                final buffered = Duration.zero;
                                final total = durationState?.total ??
                                    playerr.duration ??
                                    Duration.zero;

                                return Padding(
                                    padding: EdgeInsets.only(
                                        top:
                                            MediaQuery.of(context).size.height /
                                                20,
                                        right: 40,
                                        left: 40),
                                    child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (playerr.hasPrevious) ...[
                                            IconButton(
                                              onPressed: () {
                                                if (progress <
                                                    const Duration(
                                                        seconds: 5)) {
                                                  playerr.seekToPrevious();
                                                } else {
                                                  playerr.seek(Duration.zero);
                                                }
                                              },
                                              icon: const Icon(Ionicons
                                                  .play_skip_back_outline),
                                              color: Colors.white,
                                              iconSize: 50,
                                            ),
                                          ] else ...[
                                            const SizedBox(
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
                                                  icon: const Icon(
                                                      Ionicons.pause_outline),
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
                                                  icon: const Icon(
                                                      Ionicons.play_outline),
                                                  color: Colors.white,
                                                  iconSize: 50,
                                                ),
                                          if (playerr.hasNext) ...[
                                            IconButton(
                                              onPressed: () async {
                                                playerr.seekToNext();
                                              },
                                              icon: const Icon(Ionicons
                                                  .play_skip_forward_outline),
                                              color: Colors.white,
                                              iconSize: 50,
                                            )
                                          ] else ...[
                                            const SizedBox(
                                              width: 66,
                                            )
                                          ],
                                        ]));
                              })
                        ]))));
  }

  getFiles() async {
    files = [];
    playlists = [];
    dir!.listSync(recursive: true).forEach((element) {
      if (p.extension(element.path) == '.mp3') {
        files.add(element);
      } else if (element is Directory) {
        playlists.add(element);
      }
    });
    Playlist = ConcatenatingAudioSource(children: []);
    for (var element in files) {
      Playlist!.add(AudioSource.uri(Uri.file(element.path),
          tag: MediaItem(
              id: element.path, title: element.path.split('/').last)));
    }
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
    final path = await DownloadsPath.downloadsDirectory();
    dir = Directory('${path!.path}/Tubify');
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => AlertDialog(
          actionsAlignment: MainAxisAlignment.spaceBetween,
          backgroundColor: const Color(0xff141414),
          title: const Text(
            "Allow \"Tubify\" to access your files while using the app",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          titleTextStyle: const TextStyle(fontFamily: 'Gotham', fontSize: 18),
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
                  _notify();
                  getFiles();
                  setState(() {});
                }),
          ],
        ),
      );
    } else {
      _notify();
      getFiles();
      setState(() {});
    }

    if ((await dir!.exists())) {
      return dir!.path;
    } else {
      dir!.create();
      return dir!.path;
    }
  }

  Future<bool> _notify() async {
    bool show = false;
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => AlertDialog(
          actionsAlignment: MainAxisAlignment.spaceBetween,
          backgroundColor: const Color(0xff141414),
          title: const Text(
            "Allow \"Tubify\" to send you Notifactions",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          titleTextStyle: const TextStyle(fontFamily: 'Gotham', fontSize: 18),
          content: const Text(
            "the app will access your notifications to be able to download audios.",
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
                  await Permission.notification.request();
                  show = true;
                  setState(() {});
                }),
          ],
        ),
      );
    } else {
      show = true;
    }
    return show;
  }
}

class DurationState {
  const DurationState(
      {required this.progress, required this.buffered, this.total});
  final Duration progress;
  final Duration buffered;
  final Duration? total;
}
