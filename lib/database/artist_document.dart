import 'dart:convert';

class ArtistDocument {
  String _id;
  String artist;
  List<Source> sources;
  
  static String _artist_key = "artist";
  static String _id_key = "_id";
  static String _sources_key = "_sources";
  
  ArtistDocument(String this._id, String this.artist, List<Source>this.sources);
  
  static ArtistDocument fromString(String jsonString) {
    Map<String, String> jsonMap = JSON.decode(jsonString);
    return new ArtistDocument.fromMap(jsonMap);
  }
  
  static ArtistDocument fromMap(Map<String, String> jsonMap) {
    String id = jsonMap.get(_id_key);
    String artist = jsonMap.get(_artist_key);
    //todo
    return null;
  }
  
  
}

class Source {
  Provider source;
  String last_updated;
  List<ImageSource> image_sources;
  
  Source(Provider this.source, String this.last_updated, List<ImageSource> this.image_sources);
  
  factory Source.fromString(String jsonString) {
    
  }
}

class Provider {
  
}

class ImageSource {
  String size;
  Uri uri;
}