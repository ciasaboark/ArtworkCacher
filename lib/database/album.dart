library artworkCacher.album;

import 'artist.dart';

class Album {
  static final String KEY_HITS = "hits";
  Artist artist;
  String album;
  
  Album(Artist this.artist, String this.album);
  
  Album.fromArtistName(String artist, String albumName) {
    this.artist = new Artist(artist);
    this.album = albumName;
  }
  
}