library artworkCacher.artist;

class Artist {
  static final String KEY_HITS = "hits";
  String name = "";

  Artist(String this.name);
  
  @override String toString() => this.name;
}