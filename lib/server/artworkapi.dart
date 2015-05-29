library simpleServer.server;

import 'dart:async';
import 'dart:convert';

import 'package:rpc/api.dart';
import 'package:mongo_dart/mongo_dart.dart';

import '../common/messages.dart';
import '../database/artist.dart';
import '../database/album.dart';
import '../provider/provider.dart';

@ApiClass(name: 'artwork', version: 'v1')
class ArtworkApi {
  final Db _db = new Db("mongodb://127.0.0.1/artwork");
  
  ArtworkApi() {
  }
  
  @ApiMethod(path: 'artist/{artist}')
  Future<ArtistResponse> getArtist(String artist) async {
    int start = new DateTime.now().millisecondsSinceEpoch; 
    print("Received request for artist: $artist");
    var artists = _db.collection("artists");
    
    return _db.open().then((_){
      return artists.findOne(where.eq('artist', artist)).then((row) {
        Map<String, String> response = row;
        _db.close();
        if (response == null || response == "null") {
          response = {};
        }
        response = stripPrivateFields(response);
        int now = new DateTime.now().millisecondsSinceEpoch;
        int elapsedMs = now - start;
        ArtistResponse artistResponse =  new ArtistResponse()
            ..artist = artist
            ..results = response
            ..timestamp = new DateTime.now().millisecondsSinceEpoch.toString();
        print ("Completed lookup for $artist in $elapsedMs ms");
        
        updateArtistProvidersIfNeeded(new Artist(artist), response);
        
        return artistResponse;
      });
    });
  }
  
  /**
   * Updates the provider information for the given artist if needed
   */
  updateArtistProvidersIfNeeded(Artist artist, Map<String, String> jsonMap) async {
    assert(artist != null);
    if (jsonMap.isEmpty) {
      updateAllProvidersForArtist(artist);
    } else {
      //todo
      updateAllProvidersForArtist(artist);
    }
    
  }
  
  void updateAllProvidersForArtist(Artist artist) {
    //TODO add other providers here
    updateLastFmProviderForArtist(artist);
  }
  
  updateLastFmProviderForArtist(Artist artist) {
    LastFmFetcher provider = new LastFmFetcher();
    provider.fetchAndUpdateArtist(artist);
  }
  
  /**
   * Updates the provider information for the given album if needed
   */
  updateAlbumProvidersIfNeeded(Artist artist, Album album, Map<String, String> jsonMap) {
    //TODO
  }
  
  /**
   * Strips any private fields from the json map.
   */
  Map<String, String> stripPrivateFields(Map<String, String> jsonMap) {
    jsonMap.remove(Artist.KEY_HITS);
    jsonMap.remove(Album.KEY_HITS);
    jsonMap.remove("_id");
    return jsonMap;
  }
  
  void scheduleArtistUpdate(Artist artist) {
    
  }
  
  @ApiMethod(path: 'artist/{artist}/album/{album}')
  Future<AlbumResponse> getAlbum(String artist, String album) async {
    int start = new DateTime.now().millisecondsSinceEpoch; 
        print("Received request for artist: $artist");
        var artists = _db.collection("artists");
        
        return _db.open().then((_){
          return artists.findOne(where.eq('artist', artist).eq('album', album)).then((row) {
            Map<String, String> response = row;
            _db.close();
            if (response == null || response == "null") {
              response = {};
            }
            int now = new DateTime.now().millisecondsSinceEpoch;
            int elapsedMs = now - start;
            AlbumResponse artistResponse =  new AlbumResponse()
                ..artist = artist
                ..album = album
                ..results = response
                ..timestamp = new DateTime.now().millisecondsSinceEpoch.toString();
            print ("Completed lookup for $artist in $elapsedMs ms");
            return artistResponse;
          });
        });
  }
}