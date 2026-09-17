import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get podcastIndexApiKey =>
      dotenv.env['PODCAST_INDEX_API_KEY'] ?? '';

  static String get podcastIndexApiSecret =>
      dotenv.env['PODCAST_INDEX_API_SECRET'] ?? '';

  String remoteType = 'pop';

}

final appConfig = AppConfig();
