library salix.album;

import 'artist.dart';

class Album {
  static final String KEY_HITS = "hits";
  Artist artist;
  String name;
  
  Album(Artist this.artist, String this.name);
  
  Album.fromArtistName(String artist, String albumName) {
    this.artist = new Artist(artist);
    this.name = albumName;
  }
  
}