import 'package:flutter/material.dart';
import 'package:tube_cast/constants.dart';
import 'package:youtube_api/youtube_api.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: Icon(Icons.menu),
          centerTitle: true,
          actions: [
            clicked
                ? IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 25,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        clicked = !clicked;
                      });
                    },
                  )
                : IconButton(
                    icon: Icon(
                      Icons.search,
                      size: 25,
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
                            });
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
                                    onPressed: () {
                                      setState(
                                        () {
                                          videoResult = [];
                                          controller.clear();
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.clear)),
                          ))),
                )
              : PreferredSize(
                  preferredSize: Size.fromHeight(0), // here the desired height
                  child: SizedBox.shrink())),
      body: Container(
          color: Colors.black,
          child: Center(
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.
            child: !_isLoading
                ? ListView(children: [
                    // Padding(
                    //     padding: EdgeInsets.fromLTRB(28, 10, 28, 0),
                    //     child: TextField(
                    //         style: TextStyle(color: Colors.white),
                    //         cursorColor: Colors.white,
                    //         onEditingComplete: () async {
                    //           String query = controller.text;
                    //           videoResult = await ytApi.search(query, type: 'video');
                    //           setState(() {});
                    //         },
                    //         onChanged: (value) {
                    //           setState(() {});
                    //         },
                    //         controller: controller,
                    //         decoration: InputDecoration(
                    //           fillColor: Color(0xff252525),
                    //           filled: true,
                    //           hintText: 'Search',
                    //           hintStyle: TextStyle(color: Colors.white),
                    //           constraints: BoxConstraints(maxHeight: 100),
                    //           border: const OutlineInputBorder(),
                    //           suffixIcon: controller.text.isEmpty
                    //               ? const Icon(
                    //                   Icons.search,
                    //                   color: Colors.white,
                    //                 )
                    //               : IconButton(
                    //                   color: Colors.white,
                    //                   onPressed: () {
                    //                     setState(
                    //                       () {
                    //                         videoResult = [];
                    //                         controller.clear();
                    //                       },
                    //                     );
                    //                   },
                    //                   icon: const Icon(Icons.clear)),
                    //         ))),

                    for (YouTubeVideo i in videoResult) ...[
                      Container(
                          height: 285,
                          padding: EdgeInsets.fromLTRB(28, 15, 28, 0),
                          child: Card(
                              elevation: 50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              color: Color(0xff252525),
                              child: Column(
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
                                            )),
                                        CircleAvatar(
                                          backgroundColor: Color(0xff1DB954),
                                          child: Icon(
                                            Icons.play_arrow,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                        ),
                                      ]),
                                  Transform.translate(
                                    offset: Offset(-6, -20),
                                    child: Container(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        i.duration.toString(),
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  Transform.translate(
                                      offset: Offset(0, -24),
                                      child: Divider(
                                        color: Color(0xff1DB954),
                                        thickness: 2.5,
                                      )),
                                  Transform.translate(
                                      offset: Offset(0, -16),
                                      child: Expanded(
                                          child: Padding(
                                              padding: EdgeInsets.fromLTRB(
                                                  20, 0, 20, 2),
                                              child: RichText(
                                                maxLines: 2,
                                                text: TextSpan(
                                                    locale: Locale('en'),
                                                    text:
                                                        removeUnicodeApostrophes(
                                                            i.title),
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        height: 1.5)),
                                              ))))
                                ],
                              )))
                    ]
                  ])
                : const CircularProgressIndicator(),
          )),
    );
  }

  String removeUnicodeApostrophes(String strInput) {
    // First remove the single slash.
    String strModified = strInput.replaceAll('&#39;', "\'");
    strModified = strModified.replaceAll('&quot;', "\"");

    // Now, we can replace the rest of the unicode with a proper apostrophe.
    return strModified;
  }
}
