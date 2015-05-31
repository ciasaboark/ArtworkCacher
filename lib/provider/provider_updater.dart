part of salix.provider;

class ProviderUpdater {
  static Logger log = new Logger("ProviderUpdater");
  /**
   * Inserts or updates the 'sources' section of the artist document for the given provider.  
   */
  static updateProviderForArtist(Artist artist, Provider provider) async {
    log.fine("Updating provider: '${provider.source}' for artist: '$artist'");
    //TODO update all the providers for the artist
    Db db = new Db("mongodb://127.0.0.1/salix");
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
        log.warning("Unable to query for artist: '${artist.toString()}', err: '${err.toString()}'");
        db.close();
      });
    }).catchError((err) {
      log.warning("Unable to open database connection: Err: '${err.toString()}'");
    });
  }
  
  static insertDocumentToArtistsCollection(Artist artist, Map document) {
    ("Inserting new document for artist: '$artist'");
    Db db = new Db("mongodb://127.0.0.1/salix");
    DbCollection artists;
    db.open().then((_) {
      artists = db.collection("artists");
      artists.update(where.eq('artist', artist.name), document,
          upsert: true, writeConcern: WriteConcern.ACKNOWLEDGED).then((value) {
        log.fine("Inserted document for artist: '$artist'");
      }).catchError((err) {
        log.warning("Error updating document for artist: '$artist', err: '${err.toString()}");
      });
      db.close();
    }).catchError((err) {
      log.warning("Error opening database for insert operation.  Err: '${err.toString()}'");
      throw(new MongoDartError("Error opening database for insert operation.  Err: '${err.toString()}'"));
    });
  }
  
  static insertDocumentToAlbumCollection(Artist artist, Album album, Map document) {
      ("Inserting new document for artist: '$artist'");
      Db db = new Db("mongodb://127.0.0.1/salix");
      DbCollection artists;
      db.open().then((_) {
        artists = db.collection("album");
        artists.update(where.eq('artist', artist.name).eq("album", album.name), document,
            upsert: true, writeConcern: WriteConcern.ACKNOWLEDGED).then((value) {
          log.fine("Inserted document for artist: '${artist.name}', album: '{album.name}'");
        }).catchError((err) {
          log.warning("Error updating document for artist: '${artist.name}', album: '{album.name}', err: '${err.toString()}");
        });
        db.close();
      }).catchError((err) {
        log.warning("Error opening database for insert operation.  Err: '${err.toString()}'");
        throw(new MongoDartError("Error opening database for insert operation.  Err: '${err.toString()}'"));
      });
    }
  
  static updateProviderForAlbum(Artist artist, Album album, Provider provider) async {
    log.fine("Updating provider: '${provider.source}' for artist: '${artist.name}', album: '{album.name}'");
    //TODO update all the providers for the artist
    Db db = new Db("mongodb://127.0.0.1/salix");
    var collection = db.collection("album");
    db.open().then((_) {
      collection.findOne(where.eq('artist', "${artist.name}").eq('album', "${album.name}")).then((row) {
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
        DateTime now = new DateTime.now();
        DateTime expires = now.add(new Duration(days: 7));
        row["artist"] = artist.name;
        row["album"] = album.name;
        row["createdAt"] = now.toString();
        row["expires"] = expires.toString();
        row["sources"] = sources;
        
        insertDocumentToAlbumCollection(artist, album, row);
        db.close();
      }).catchError((err) {
        log.warning("Unable to query for artist: '${artist.toString()}', err: '${err.toString()}'");
        db.close();
      });
    }).catchError((err) {
      log.warning("Unable to open database connection: Err: '${err.toString()}'");
    });
  }
  
}
