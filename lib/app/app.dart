import 'package:flutter/material.dart';

import '../podcast/api/podcast_api.dart';
import '../podcast/repository/podcast_repository.dart';
import '../home/remote_home_page.dart';

class FreeboxRemoteApp extends StatelessWidget {
  final PodcastRepository repository;
  final PodcastApi podcastApi;

  const FreeboxRemoteApp({
    super.key,
    required this.repository,
    required this.podcastApi,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Télécommande Freebox',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        brightness: Brightness.dark,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B8CFF),
          brightness: Brightness.dark,
        ),

        scaffoldBackgroundColor:
            const Color(0xFF080B12),

        fontFamily: 'sans',

        useMaterial3: true,
      ),

      home: RemoteHomePage(
        repository: repository,
        podcastApi: podcastApi,
      ),
    );
  }
}
