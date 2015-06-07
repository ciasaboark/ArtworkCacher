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
  final Db _db = new Db("mongodb://phobotic.io:27017/salix");
  final Logger log = new Logger("ArtworkApi");
  
  /**
   * Replace all instances of '%20' in string with ' '.  Converts to lowercase.
   */
  String normalizeString(String string) {
    String decodeString = Uri.decodeFull(string).toLowerCase();
    return decodeString;
  }
  
  @ApiMethod(path: 'artist/{artist}')
  Future<ArtistResponse> getArtist(String artist) async {
    artist = normalizeString(artist);
    int start = new DateTime.now().millisecondsSinceEpoch; 
    log.info("Received request for artist: $artist");
    var artists = _db.collection("artists");
    
    return _db.open().then((_){
      return artists.findOne(where.eq('artist', artist)).then((row) {
        Map<String, String> response = row;
        _db.close();
        int now = new DateTime.now().millisecondsSinceEpoch;
        if (response == null || response == "null") {
          log.info("No cached document for artist: '${artist}'");
          response = {};
        } else {
          //if the response has expired then just blank it out.  The document will be removed
          //later in processing
          try {
            int expiresMs = DateTime.parse(response['expires']).millisecondsSinceEpoch;
            if (expiresMs < now) {
              response = {};
              log.info("Cached document for artist: '$artist' has expired");
            } else {
              log.info("Cached document for artist: '$artist' is still good");
            }
          } catch (err) {
            response = {};
            log.info("Error reading cached document for artist: '$artist'");
          }
        }
        response = stripPrivateFields(response);
        
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
  Map<String, String> stripPrivateFields(Map<String, dynamic> jsonMap) {
    try {
      jsonMap.remove(Artist.KEY_HITS);
      jsonMap.remove(Album.KEY_HITS);
      jsonMap.remove("_id");
    } catch (err) {
      //errors are fine here, the keys might not exist
    }
    return jsonMap;
  }
  
  void scheduleArtistUpdate(Artist artist) {
    
  }
  
  @ApiMethod(path: 'artist/{artist}/album/{album}')
  Future<AlbumResponse> getAlbum(String artist, String album) async {
    artist = normalizeString(artist);
    album = normalizeString(album);
    int start = new DateTime.now().millisecondsSinceEpoch; 
        log.info("Received request for artist: '$artist', album: '$album'");
        DbCollection albums = _db.collection("album");
        
        return _db.open().then((_){
          return albums.findOne(where.eq('artist', artist).eq('album', album)).then((row) {
            Map<String, String> response = row;
            _db.close();
            int now = new DateTime.now().millisecondsSinceEpoch;
            if (response == null || response == "null") {
              log.info("No cached document for artist: '${artist}', album: $album");
              response = {};
            } else {
              //if the response has expired then just blank it out.  The document will be removed
              //later in processing
              try {
                int expiresMs = DateTime.parse(response['expires']).millisecondsSinceEpoch;
                if (expiresMs < now) {
                  response = {};
                  log.info("Cached document for artist: '$artist', album: $album has expired");
                } else {
                  log.info("Cached document for artist: '$artist', album: $album is still good");
                }
              } catch (err) {
                response = {};
                log.info("Error reading cached document for artist: '$artist', album: $album");
              }
              
            }
            response = stripPrivateFields(response);
            
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
      log.info("updating all providers for artist: ${artist.name}, album: ${album.name}");
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