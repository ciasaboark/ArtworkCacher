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
  List<Map<String, String>> img_resources;
  
  Provider(String this.source, String this.last_updated, String this.expires, List<Map<String, String>> this.img_resources);
  
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = new Map<String, dynamic>();
    map["source"] = source;
    map["last_updated"] = last_updated;
    map["img_resources"] = img_resources;
    map["expires"] = expires;
    return map;
  }
}