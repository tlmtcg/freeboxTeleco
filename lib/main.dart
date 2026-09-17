import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:media_kit/media_kit.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app/app.dart';
import 'podcast/api/podcast_api.dart';
import 'podcast/database/podcast_database.dart';
import 'podcast/repository/podcast_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ===========================================================================
  // MEDIA KIT
  // ===========================================================================

  MediaKit.ensureInitialized();

  // ===========================================================================
  // SQLITE
  // ===========================================================================

  if (Platform.isWindows ||
      Platform.isLinux ||
      Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // ===========================================================================
  // ENVIRONNEMENT
  // ===========================================================================

  await dotenv.load(fileName: '.env');

  final apiKey = dotenv.env['PODCAST_INDEX_API_KEY'];
  final apiSecret = dotenv.env['PODCAST_INDEX_API_SECRET'];

  if (apiKey == null || apiKey.isEmpty) {
    debugPrint(
      'ERREUR : PODCAST_INDEX_API_KEY absente',
    );
    return;
  }

  if (apiSecret == null || apiSecret.isEmpty) {
    debugPrint(
      'ERREUR : PODCAST_INDEX_API_SECRET absente',
    );
    return;
  }

  // ===========================================================================
  // SERVICES PODCAST
  // ===========================================================================

  final podcastApi = PodcastApi(
    apiKey: apiKey,
    apiSecret: apiSecret,
  );

  final podcastDatabase = PodcastDatabase.instance;

  final repository = PodcastRepository(
    api: podcastApi,
    database: podcastDatabase,
  );

  // ===========================================================================
  // APPLICATION
  // ===========================================================================

  runApp(
    FreeboxRemoteApp(
      repository: repository,
      podcastApi: podcastApi,
    ),
  );
}
