// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_static/shelf_static.dart';

import '../asset/cache.dart';
import '../asset/file_based.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../package_graph/package_graph.dart';
import 'directory_watcher_factory.dart';

/// Manages setting up consistent defaults for all options and build modes.
class BuildOptions {
  /// Build mode options.
  StreamSubscription logListener;
  PackageGraph packageGraph;
  AssetReader reader;
  AssetWriter writer;

  /// Watch mode options.
  Duration debounceDelay;
  DirectoryWatcherFactory directoryWatcherFactory;

  /// Server options.
  int port;
  String address;
  String directory;
  Handler requestHandler;

  BuildOptions(
      {this.debounceDelay,
      this.directoryWatcherFactory,
      Level logLevel,
      onLog(LogRecord),
      this.packageGraph,
      this.reader,
      this.writer,
      this.directory,
      this.address,
      this.port,
      this.requestHandler}) {
    /// Set up logging
    logLevel ??= Level.INFO;
    Logger.root.level = logLevel;
    onLog ??= (LogRecord record) {
      var color;
      if (record.level < Level.WARNING) {
        color = _cyan;
      } else if (record.level < Level.SEVERE) {
        color = _yellow;
      } else {
        color = _red;
      }
      var message = '$color[${record.level}]$_endColor ${record.loggerName}: '
          '${record.message}\n';
      if (record.level >= Level.SEVERE) {
        stderr.write(message);
      } else {
        stdout.write(message);
      }
    };
    logListener = Logger.root.onRecord.listen(onLog);

    /// Set up other defaults.
    address ??= 'localhost';
    directory ??= '.';
    port ??= 8000;
    requestHandler ??= createStaticHandler(directory,
        defaultDocument: 'index.html', listDirectories: true);
    debounceDelay ??= const Duration(milliseconds: 250);
    packageGraph ??= new PackageGraph.forThisPackage();
    var cache = new AssetCache();
    reader ??=
        new CachedAssetReader(cache, new FileBasedAssetReader(packageGraph));
    writer ??=
        new CachedAssetWriter(cache, new FileBasedAssetWriter(packageGraph));
    directoryWatcherFactory ??= defaultDirectoryWatcherFactory;
  }
}

final _cyan = Platform.isWindows ? '' : '\u001b[36m';
final _yellow = Platform.isWindows ? '' : '\u001b[33m';
final _red = Platform.isWindows ? '' : '\u001b[31m';
final _endColor = Platform.isWindows ? '' : '\u001b[0m';
