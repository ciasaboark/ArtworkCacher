part of artworkCacher.provider;

class LastFmFetcher {
  static final String _queryServer = "http://ws.audioscrobbler.com/2.0/?method=artist.getInfo";
  
  Future fetchAndUpdateArtist(Artist artist) async {
    String jsonResponse = "";
    
    if (artist == null) {
      throw new NullArgumentException("artist can not be null");
    }
    
    String queryString = "${_queryServer}&format=json&api_key=${LAST_FM_API_KEY}&artist=${artist}";
    try {
      HttpClient client = new HttpClient();
      Uri queryUri = Uri.parse(queryString);
      print("GET: '${queryUri}'");
      client.getUrl(queryUri).then((HttpClientRequest request) {
        request.close().then((HttpClientResponse response) {
          //got the repsonse back from Last.FM
          response.transform(UTF8.decoder).listen((contents) {
            jsonResponse += contents.toString();
            print(jsonResponse);
          }, onDone: () {
            print(jsonResponse);
            List<Map<String, String>> imageSources = new List<Map<String, String>>();
            Map<String, dynamic> jsonMap = JSON.decode(jsonResponse);
            if (jsonMap.containsKey("artist")) {
              Map artist = jsonMap["artist"];
              if (artist.containsKey("image")) {
                //transform the lastfm image sizes to our own
                
                List<Map> images = artist["image"];
                for (Map imgSrc in images) {
                  print("Source, size: ${imgSrc['size']}, src: ${imgSrc['#text']}");
                  switch (imgSrc['size']) {
                    case "small":
                      imageSources.add({"small": imgSrc['#text']});
                      break;
                    case "medium":
                      imageSources.add({"medium": imgSrc['#text']});
                      break;
                    case "large":
                      imageSources.add({"large": imgSrc['#text']});
                      break;
                    case "extralarge":
                      imageSources.add({"xlarge": imgSrc['#text']});
                      break;
                    default:
                      //ignore other sizes
                  }
                }
                
              }
            }
            
            Provider lastfmProvider = new Provider("lastfm", 
                new DateTime.now().millisecondsSinceEpoch.toString(), imageSources);
            ProviderUpdater.updateProviderForArtist(artist, lastfmProvider);
          });
        }).catchError((err) {
          print("caught error loading artist information from: '${queryString}': ${e.toString()}");
        });
      });
    } catch (e) {
      //TODO
      print("caught error loading artist information from: '${queryString}': ${e.toString()}");
    }
  }
  
  Map<String, String> fetchAndUpdateAlbum(Artist artist, Album album) {
    //TODO
  }
}