import 'package:flutter/material.dart';
import 'package:tube_cast/screens/search.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  await FlutterDownloader.initialize(
      debug:
          true, // optional: set to false to disable printing logs to console (default: true)
      ignoreSsl:
          true // option: set to false to disable working with http links (default: false)
      );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tubify',
      theme: ThemeData(
        fontFamily: 'Gotham',
        unselectedWidgetColor: Colors.white,
        colorScheme:
            ThemeData().colorScheme.copyWith(primary: const Color(0xff3e4da0)),
      ),
      home: const MyHomePage(),
    );
  }
}
