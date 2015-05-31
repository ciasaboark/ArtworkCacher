// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:rpc/rpc.dart';

import '../lib/common/messages.dart';
import '../lib/server/artworkapi.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_rpc/shelf_rpc.dart' as shelf_rpc;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart' as shelf_static;
import 'package:path/path.dart' show join, dirname;

final ApiServer _apiServer = new ApiServer(prettyPrint: true);

main() async {
  Logger.root
      ..level = Level.ALL
      ..onRecord.listen((LogRecord rec) {
        print('${rec.level.name}: ${rec.time}: ${rec.loggerName}: ${rec.message}');
      });
  Logger log = new Logger("Salix");
  log.info("Starting...");
  _apiServer.addApi(new ArtworkApi());
  
  var apiHandler = shelf_rpc.createRpcHandler(_apiServer);
  var pathToBuild = join(dirname(Platform.script.toFilePath()),
        '..', 'admin');
  var staticHandler = shelf_static.createStaticHandler(pathToBuild, defaultDocument:'index.html', serveFilesOutsidePath: true);
  var loggingStaticHandler = const shelf.Pipeline().addMiddleware(shelf.logRequests()).addHandler(staticHandler);
  
  var handler = new shelf.Cascade()
    .add(loggingStaticHandler)  
    .add(apiHandler)
    .handler;

  HttpServer server = (await io.serve(handler, 'localhost', 8080));
  
  log.info('Server listening on http://${server.address.host}:${server.port}');
}
