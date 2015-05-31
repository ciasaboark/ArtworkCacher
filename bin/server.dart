// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:rpc/rpc.dart';

import '../lib/common/messages.dart';
import '../lib/server/artworkapi.dart';


final ApiServer _apiServer = new ApiServer(prettyPrint: true);

main() async {
  Logger.root
      ..level = Level.ALL
      ..onRecord.listen((LogRecord rec) {
        print('${rec.level.name}: ${rec.time}: ${rec.loggerName}: ${rec.message}');
      });
  
  _apiServer.addApi(new ArtworkApi());
  HttpServer server = await HttpServer.bind(InternetAddress.ANY_IP_V4,8089);
  server.listen(_apiServer.httpRequestHandler);
  print('Server listening on http://${server.address.host}:${server.port}');
}
