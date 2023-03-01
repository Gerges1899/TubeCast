import 'dart:convert';

List<Video> videoFromJson(String str) =>
    List<Video>.from(json.decode(str).map((x) => Video.fromJson(x)));

String videoToJson(List<Video> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Video {
  String kind;
  String id;
  String channelTitle;
  String title;
  String description;
  DateTime publishedAt;
  String channelId;
  Thumbnails thumbnails;
  String channelurl;
  String url;
  Video({
    required this.kind,
    required this.id,
    required this.channelTitle,
    required this.title,
    required this.description,
    required this.publishedAt,
    required this.channelId,
    required this.thumbnails,
    required this.channelurl,
    required this.url,
  });

  factory Video.fromJson(Map<String, dynamic> json) => Video(
        kind: json["kind"],
        id: json["id"],
        channelTitle: json["channelTitle"],
        title: json["title"],
        description: json["description"],
        publishedAt: DateTime.parse(json["publishedAt"]),
        channelId: json["channelId"],
        thumbnails: Thumbnails.fromJson(json["thumbnails"]),
        channelurl: json["channelurl"],
        url: json["url"],
      );

  Map<String, dynamic> toJson() => {
        "kind": kind,
        "id": id,
        "channelTitle": channelTitle,
        "title": title,
        "description": description,
        "publishedAt": publishedAt.toIso8601String(),
        "channelId": channelId,
        "thumbnails": thumbnails.toJson(),
        "channelurl": channelurl,
        "url": url,
      };
}

class Thumbnails {
  Thumbnails({
    required this.thumbnailsDefault,
    required this.medium,
    required this.high,
  });

  Default thumbnailsDefault;
  Default medium;
  Default high;

  factory Thumbnails.fromJson(Map<String, dynamic> json) => Thumbnails(
        thumbnailsDefault: Default.fromJson(json["default"]),
        medium: Default.fromJson(json["medium"]),
        high: Default.fromJson(json["high"]),
      );

  Map<String, dynamic> toJson() => {
        "default": thumbnailsDefault.toJson(),
        "medium": medium.toJson(),
        "high": high.toJson(),
      };
}

class Default {
  Default({
    required this.url,
    required this.width,
    required this.height,
  });

  String url;
  int width;
  int height;

  factory Default.fromJson(Map<String, dynamic> json) => Default(
        url: json["url"],
        width: json["width"],
        height: json["height"],
      );

  Map<String, dynamic> toJson() => {
        "url": url,
        "width": width,
        "height": height,
      };
}
