library salix.messages;

import 'package:rpc/rpc.dart';

class Response {
  
}

class ArtistResponse {
  @ApiProperty(required: true)
  Map<String, String> results;
  
  @ApiProperty(required: true)
  String artist;
  
  @ApiProperty(required: true)
  String timestamp;
}

class AlbumResponse {
  @ApiProperty(required: true)
  Map<String, String> results;
  
  @ApiProperty(required: true)
  String artist;
  
  @ApiProperty(required: true)
  String album;
  
  @ApiProperty(required: true)
  String timestamp;
}