part of salix.provider;

class LastFmProvider {
  static final String _queryServer = "http://ws.audioscrobbler.com/2.0/";
  static final String _queryMethodArtist = "?method=artist.getInfo";
  static final String _queryMethodAlbum = "?method=album.getInfo";
  static final Logger log = new Logger('LastFmProvider');
  static final int _expireDays = 7;
  
  
  void updateLastFMProviderForAlbumIfNeeded(Artist artist, Album album, Map jsonMap) {
    assert(artist != null);
    assert(album != null);
    if (_shouldProviderBeUpdated(jsonMap)) {
      log.fine("provider for artist: ${artist.name}, album: ${album.name} should be updated");
      fetchAndUpdateAlbum(artist, album);
    } else {
      log.fine("provider for artist: ${artist.name}, album: ${album.name} does not need to be updated");
    }
  }
  
  void updateLastFMProviderForArtistIfNeeded(Artist artist, Map jsonMap) {
    assert(artist != null);
    if (_shouldProviderBeUpdated(jsonMap)) {
      log.fine("provider for artist: $artist should be updated");
      fetchAndUpdateArtist(artist);
    } else {
      log.fine("provider for artist: $artist does not need to be updated");
    }
  }
  
  bool _shouldProviderBeUpdated(Map jsonMap) {
    bool updateProvider = false;
    
    //pull out the lastfm inner map
    try {
      List sources = jsonMap['sources'];
      for (Map source in sources) {
        if (source['source'] == "lastfm") {
          String expires = source['expires'];
          if (expires == null) {
            updateProvider = true;
          } else {
            DateTime now = new DateTime.now();
            DateTime expireDate = DateTime.parse(expires);
            if (expireDate.millisecondsSinceEpoch <= now.millisecondsSinceEpoch) {
              updateProvider;
            }
          }
        }
      }
    } catch (err) {
      log.warning("caught error parsing json map: ${err.toString()}");
      updateProvider = true;
    }
    
    return updateProvider;
  }
  
  
  Future fetchAndUpdateArtist(Artist artist) async {
    if (artist == null) {
      throw new NullArgumentException("artist can not be null");
    }
   
    String queryString = "${_queryServer}${_queryMethodArtist}&format=json&api_key=${LAST_FM_API_KEY}&artist=${artist}";
    Uri queryUri = Uri.parse(queryString);
    _queryForResponse(queryUri).then((String jsonResponse) {
      if (jsonResponse != null) {
        _processArtistResponse(artist, jsonResponse);
      }
    });
  }
  
  Future<String> _queryForResponse(Uri queryUri) {
    Completer completer = new Completer();
    try {
      HttpClient client = new HttpClient();
      
      log.fine("GET: '${queryUri}'");
      client.getUrl(queryUri).then((HttpClientRequest request) {
        log.finer("connection established");
        request.close().then((HttpClientResponse response) {
          log.finer("got the repsonse back from Last.FM");
          String responseString = "";
          
          response.transform(UTF8.decoder).listen((contents) {
            //listen will be called repeatedly as chunks arrive 
            log.finest("received chunk: ${contents.toString().length} characters");
            responseString += contents.toString();
          }, onDone: () {
            log.fine("received complete response: $response");
            completer.complete(responseString);
          }).onError((err) {
            log.warning("caught error transforming body response bytes to UTF8 string");
            completer.complete(null);
          });
        }).catchError((err) {
          log.warning("caught error loading artist information from: '${queryUri.toString()}': ${err.toString()}");
          completer.complete(null);
        });
      }).catchError((err) {
        log.warning("caught error while connecting to url: ${queryUri.toString()}");
        completer.complete(null);
      });
    } catch (e) {
      //TODO
      log.warning("caught error loading artist information from: '${queryUri.toString()}': ${e.toString()}");
      completer.complete(null);
    }

    return completer.future;
  }
  
  _processArtistResponse(Artist artist, String response) {
    List<Map<String, String>> imageSources = new List<Map<String, String>>();
    Map<String, dynamic> jsonMap = JSON.decode(response);
    try {
      log.finest("searching for root level artist key");
      Map artistMap = jsonMap["artist"];
      log.finest("searcing for image sources");
      List<Map> images = artistMap["image"];
      imageSources = _getImageSourcesFromMap(images);
      log.fine("inserting new last.fm provider info for artist: '$artist'");
      DateTime expireDate = new DateTime.now().add(new Duration(days: _expireDays));
      Provider lastfmProvider = new Provider("lastfm", 
                      new DateTime.now().toString(),
                      expireDate.toString(),
                      imageSources);
      ProviderUpdater.updateProviderForArtist(artist, lastfmProvider);
    } catch (err) {
      log.warning("did not receive correct response from last.fm artist query, will not update" +
        " this provider for artist: '${artist.name}', err: '${err.toString()}'");
    }
  }
  
  
  _processAlbumResponse(Artist artist, Album album, String response) {
    List<Map<String, String>> imageSources = new List<Map<String, String>>();
    Map<String, dynamic> jsonMap = JSON.decode(response);
    log.finest("searching for root level album key");
    try {
      Map albumMap = jsonMap["album"]; 
      List<Map> images = albumMap["image"];
      imageSources = _getImageSourcesFromMap(images);
      log.fine("inserting new last.fm provider info for artist: '$artist'");
      DateTime expireDate = new DateTime.now().add(new Duration(days: _expireDays));
      Provider lastfmProvider = new Provider("lastfm", 
                      new DateTime.now().toString(),
                      expireDate.toString(),
                      imageSources);
        ProviderUpdater.updateProviderForAlbum(artist, album, lastfmProvider);
      
    } catch (err) {
      log.warning("did not receive correct response from last.fm artist query, will not update" +
          " this provider for artist: '${artist.name}', album: '${album.name}', err: '${err.toString()}'");
    }
  }
  
  List<Map<String, String>> _getImageSourcesFromMap(List<Map> images) {
    List<Map<String, String>> imageSources = new List<Map<String, String>>();
    for (Map imgSrc in images) {
      log.finest("Source, size: ${imgSrc['size']}, src: ${imgSrc['#text']}");
      Map imgMap = {};
      switch (imgSrc['size']) {
        case "small":
          imgMap = {"small": imgSrc['#text']};
          imageSources.add(imgMap);
          log.fine("adding image source: ${imgMap.toString()}'");
          break;
        case "medium":
          imgMap = {"medium": imgSrc['#text']};
          imageSources.add(imgMap);
          log.fine("adding image source: ${imgMap.toString()}'");
          break;
        case "large":
          imgMap = {"large": imgSrc['#text']};
          imageSources.add(imgMap);
          log.fine("adding image source: ${imgMap.toString()}'");
          break;
        case "extralarge":
          imgMap = {"xlarge": imgSrc['#text']};
          imageSources.add(imgMap);
          log.fine("adding image source: ${imgMap.toString()}'");
          break;
        default:
          //ignore other sizes
      }
    }
    return imageSources;
  }
  
  Map<String, String> fetchAndUpdateAlbum(Artist artist, Album album) {
    if (artist == null) {
      throw new NullArgumentException("artist can not be null");
    }
    
    if (album == null) {
      throw new NullArgumentException("album can not be null");
    }
   
    String queryString = "${_queryServer}${_queryMethodAlbum}&format=json&api_key=${LAST_FM_API_KEY}&artist=${artist.name}&album=${album.name}";
    log.fine("fetching album information from: '$queryString'");
    Uri queryUri = Uri.parse(queryString);
    _queryForResponse(queryUri).then((String jsonResponse) {
      if (jsonResponse != null) {
        _processAlbumResponse(artist, album, jsonResponse);
      }
    });
  }
}