library salix.server;

import 'dart:async';
import 'dart:convert';

import 'package:rpc/rpc.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logging/logging.dart';

import '../common/messages.dart';
import '../database/artist.dart';
import '../database/album.dart';
import '../provider/provider.dart';

@ApiClass(name: 'artwork', version: 'v1')
class ArtworkApi {
  final Db _db = new Db("mongodb://127.0.0.1/salix");
  final Logger log = new Logger("ArtworkApi");
  
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
            ..timestamp = new DateTime.now().toString();
        log.info("Completed lookup for $artist in $elapsedMs ms");
        
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
      updateLastFmProviderForArtistIfNeeded(artist, jsonMap);
    } 
  }
       
  void updateLastFmProviderForArtistIfNeeded(Artist artist, Map jsonMap) {
    LastFmProvider provider = new LastFmProvider();
    provider.updateLastFMProviderForArtistIfNeeded(artist, jsonMap);
  }
  
  void updateAllProvidersForArtist(Artist artist) {
    //TODO add other providers here
    updateLastFmProviderForArtist(artist);
  }
  
  updateLastFmProviderForArtist(Artist artist) {
    LastFmProvider provider = new LastFmProvider();
    provider.fetchAndUpdateArtist(artist);
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
        log.info("Received request for artist: '$artist', album: '$album'");
        DbCollection albums = _db.collection("album");
        
        return _db.open().then((_){
          return albums.findOne(where.eq('artist', artist).eq('album', album)).then((row) {
            Map<String, String> response = row;
            _db.close();
            if (response == null || response == "null") {
              response = {};
            }
            int now = new DateTime.now().millisecondsSinceEpoch;
            int elapsedMs = now - start;
            AlbumResponse albumResponse =  new AlbumResponse()
                ..artist = artist
                ..album = album
                ..results = response
                ..timestamp = new DateTime.now().toString();
            log.info("Completed lookup for $artist in $elapsedMs ms");
            
            Artist tmpArtist = new Artist(artist);
            Album tmpAlbum = new Album(tmpArtist, album);
            updateAlbumProvidersIfNeeded(tmpArtist, tmpAlbum, response);
            
            return albumResponse;
          });
        });
  }
  
  /**
   * Updates the provider information for the given artist if needed
   */
  updateAlbumProvidersIfNeeded(Artist artist, Album album, Map<String, String> jsonMap) async {
    assert(artist != null);
    if (jsonMap.isEmpty) {
      updateAllProvidersForAlbum(artist, album);
    } else {
      updateLastFmProviderForAlbumIfNeeded(artist, album, jsonMap);
    } 
  }
  
  void updateLastFmProviderForAlbumIfNeeded(Artist artist, Album album, Map jsonMap) {
    LastFmProvider provider = new LastFmProvider();
    provider.updateLastFMProviderForAlbumIfNeeded(artist, album, jsonMap);
  }
 
  void updateAllProvidersForAlbum(Artist artist, Album album) {
    //TODO add other providers here
    updateLastFmProviderForAlbum(artist, album);
  }
 
  
  
  updateLastFmProviderForAlbum(Artist artist, Album album) {
    LastFmProvider provider = new LastFmProvider();
    provider.fetchAndUpdateAlbum(artist, album);
  }
}