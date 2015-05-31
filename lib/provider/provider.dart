library salix.provider;

import '../private/keyset.dart';
import '../database/artist.dart';
import '../database/album.dart';
import '../exception/exceptions.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:mongo_dart/mongo_dart.dart';


part 'lastfm_provider.dart';
part 'provider_updater.dart';

class Provider {
  String source;
  String last_updated;
  String expires;
  String info;
  List<Map<String, String>> img_resources;
  
  Provider(String this.source, String this.last_updated,{String expires, String info, List<Map<String, String>> img_resources}) {
    this.expires = expires;
    this.info = info;
    this.img_resources = img_resources;
  }
  
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = new Map<String, dynamic>();
    map["source"] = source;
    map["last_updated"] = last_updated;
    
    //optional members may be null.  Instead of inserting "null" into the
    //map we just omit these fields
    if (expires != null) map["expires"] = expires;
    if (info != null) map["info"] = info;
    if (img_resources != null) map["img_resources"] = img_resources;
    
    return map;
  }
}