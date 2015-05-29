part of artworkCacher.provider;

class ProviderUpdater {
  /**
   * Inserts or updates the 'sources' section of the artist document for the given provider.  
   */
  static updateProviderForArtist(Artist artist, Provider provider) async {
    //TODO update all the providers for the artist
    Db db = new Db("mongodb://127.0.0.1/artwork");
    var collection = db.collection("artists");
    db.open().then((_) {
      collection.findOne(where.eq('artist', "${artist.name}")).then((row) {
        List<Map<String, dynamic>> sources = new List<Map<String, dynamic>>();
        if (row == null || row.isEmpty) {
          row = {};
        } else if (row.containsKey("sources")) {
          /// document has at least one source already.  If it contains this provider
          /// then remove it and insert the new version.  To avoid a concurrent modification
          /// error we have to do this as a mark and sweep
          sources = row['sources'];
          List<Map> toRemove = new List<Map>();
          for (Map<String, dynamic> source in sources) {
            if (source['source'] == provider.source) {
              toRemove.add(source);
            }
          }
          for (Map map in toRemove) {
            sources.remove(map);
          }
          toRemove = null;
        }
        
        sources.add(provider.toMap());
        DateTime timestamp = new DateTime.now();
        int now = timestamp.millisecondsSinceEpoch;
        DateTime expires = timestamp.add(new Duration(days: 7));
        row["artist"] = artist.name;
        row["createdAt"] = timestamp.toString();
        row["expires"] = expires.toString();
        row["sources"] = sources;
        
        insertDocumentToArtistsCollection(artist, row);
        db.close();
      }).catchError((err) {
        print("Unable to query for artist: '${artist.toString()}', err: '${err.toString()}'");
        db.close();
      });
    }).catchError((err) {
      print("Unable to open database connection: Err: '${err.toString()}'");
    });
  }
  
  static insertDocumentToArtistsCollection(Artist artist, Map document) {
    Db db = new Db("mongodb://127.0.0.1/artwork");
    DbCollection artists;
    db.open().then((_) {
      artists = db.collection("artists");
      artists.update(where.eq('artist', artist.name), document,
          upsert: true, writeConcern: WriteConcern.ACKNOWLEDGED).then((value) {
        print(value);
      }).catchError((err) {
        print("Error updating document for artist: '$artist', err: '${err.toString()}");
      });
      db.close();
    }).catchError((err) {
      print("Error opening database for insert operation.  Err: '${err.toString()}'");
      throw(new MongoDartError("Error opening database for insert operation.  Err: '${err.toString()}'"));
    });
  }
  
  static updateProviderForAlbum(Artist artist, Album album, Provider provider) async {
    //TODO update all the providers for the album
  }
  
}
