Architecture complète
lib/
│
├── main.dart
│
├── core/
│   ├── ...
│
├── discovery/
│   ├── ...
│
├── network/
│   ├── ...
│
├── rudp/
│   ├── ...
│
├── hid/
│   ├── ...
│
├── remote/
│   ├── ...
│
└── podcast/
    │
    ├── models/
    │   ├── podcast.dart
    │   └── podcast_episode.dart
    │
    ├── api/
    │   └── podcast_api.dart
    │
    ├── database/
    │   └── podcast_database.dart
    │
    ├── repository/
    │   └── podcast_repository.dart
    │
    ├── player/
    │   └── podcast_player.dart
    │
    └── podcast_page.dart

Mais derrière ces fichiers, je propose cette responsabilité précise.

1. models/podcast.dart

Représente un podcast / une émission.

Podcast
│
├── id
├── podcastIndexId
├── radioId
├── title
├── description
├── imageUrl
├── feedUrl
├── websiteUrl
└── lastUpdated

Il ne contient pas les épisodes.

2. models/podcast_episode.dart

Représente un épisode.

PodcastEpisode
│
├── id
├── podcastId
├── guid
├── title
├── description
├── audioUrl
├── imageUrl
├── publishedAt
├── duration
├── listened
└── position

position permettra de reprendre la lecture.

Exemple :

Épisode
    durée       52:18
    position    17:42
    listened    false
3. api/podcast_api.dart

C'est uniquement le client Podcast Index.

Il ne connaît pas SQLite.

Il pourra fournir des méthodes du genre :

searchPodcasts(...)
getPodcast(...)
getEpisodes(...)
getTrending(...)
getRecentEpisodes(...)

Flux :

PodcastRepository
        │
        ▼
PodcastApi
        │
        ▼
Podcast Index

L'API ne doit jamais décider quoi conserver en base.

4. database/podcast_database.dart

C'est notre couche SQLite.

Elle ne connaît pas Podcast Index.

Elle connaît uniquement :

radios
podcasts
episodes
Table radios
radios
────────────────────────
id
name
image_url

Exemple :

1 | France Inter
2 | France Culture
3 | RTL
Table podcasts
podcasts
────────────────────────
id
podcast_index_id
radio_id
title
description
image_url
feed_url
website_url
last_updated

Relation :

radio
  │
  ├── podcast
  ├── podcast
  └── podcast
Table episodes
episodes
────────────────────────
id
podcast_id
guid
title
description
audio_url
image_url
published_at
duration
position
listened

Relation :

Podcast
   │
   ├── Episode
   ├── Episode
   ├── Episode
   └── Episode

Et :

UNIQUE(podcast_id, guid)

pour empêcher les doublons.

5. repository/podcast_repository.dart

C'est le cerveau de la partie podcast.

C'est la seule classe que podcast_page.dart devrait utiliser pour les données.

Elle fait le lien :

             Podcast Index
                   ▲
                   │
             PodcastApi
                   ▲
                   │
              Repository
                   │
                   ▼
             SQLite Database

Exemples :

Future<List<Podcast>> getPodcasts({
  int? radioId,
});
Future<List<PodcastEpisode>> getEpisodes({
  int? podcastId,
});
Future<List<PodcastEpisode>> searchEpisodes(
  String text,
);
Future<void> syncPodcast(
  Podcast podcast,
);
Future<void> syncRadio(
  int radioId,
);
6. Synchronisation

Le repository sera responsable de la synchronisation.

Par exemple :

syncRadio(France Inter)
        │
        ▼
Podcast Index
        │
        ▼
liste podcasts
        │
        ▼
SQLite
        │
        ├── nouveau podcast → INSERT
        │
        └── podcast existant → UPDATE

Puis pour les épisodes :

Podcast
   │
   ▼
Podcast Index
   │
   ▼
Episodes
   │
   ├── nouveau → INSERT
   │
   └── existant → UPDATE

Et surtout :

listened
position

ne doivent jamais être écrasés par une synchronisation.

7. player/podcast_player.dart

Cette classe ne fait aucun accès à Podcast Index.

Elle s'occupe uniquement de la lecture.

Je partirais sur just_audio.

Responsabilités :

PodcastPlayer
│
├── play()
├── pause()
├── stop()
├── seek()
├── forward()
├── rewind()
├── position
├── duration
└── state

Par exemple :

Future<void> playEpisode(
  PodcastEpisode episode,
)

Le lecteur reçoit donc directement :

audioUrl

et lit le flux.

8. Sauvegarde de la position

Il y aura une liaison entre :

PodcastPlayer
       │
       ▼
PodcastRepository
       │
       ▼
PodcastDatabase

Pendant la lecture :

17:41
17:42
17:43
...

on sauvegarde périodiquement la position.

Par exemple toutes les 5 secondes ou 10 secondes.

Mais pas à chaque milliseconde.

9. podcast_page.dart

La page ne doit pas connaître :

HTTP
Podcast Index
SQLite
SQL
parsing JSON
parsing RSS
fonctionnement de just_audio

Elle utilise simplement :

PodcastRepository
PodcastPlayer

Architecture :

                 PodcastPage
                     │
          ┌──────────┴──────────┐
          ▼                     ▼
 PodcastRepository       PodcastPlayer
          │                     │
     ┌────┴────┐                │
     ▼         ▼                ▼
 SQLite    Podcast Index       Audio
10. Plus tard : widgets de la page

Quand on construira réellement l'interface, je te conseille de ne pas mettre tout dans podcast_page.dart.

On pourra ajouter :

podcast/
│
├── widgets/
│   ├── podcast_card.dart
│   ├── episode_card.dart
│   ├── podcast_filter.dart
│   ├── podcast_search.dart
│   ├── podcast_player_bar.dart
│   └── podcast_episode_detail.dart

Donc à terme :

podcast/
├── models/
├── api/
├── database/
├── repository/
├── player/
├── widgets/
└── podcast_page.dart
11. Vue d'ensemble finale
                         ┌─────────────────┐
                         │  Podcast Index  │
                         └────────┬────────┘
                                  │
                              HTTP/API
                                  │
                                  ▼
                         ┌─────────────────┐
                         │  podcast_api    │
                         └────────┬────────┘
                                  │
                                  ▼
                       ┌─────────────────────┐
                       │ podcast_repository  │
                       └───────┬───────┬─────┘
                               │       │
                         lecture       │ synchro
                               │       │
                               ▼       ▼
                    ┌──────────────┐ ┌─────────────┐
                    │podcast_player│ │   SQLite    │
                    └──────┬───────┘ └──────┬──────┘
                           │                │
                           ▼                ▼
                         AUDIO       radios/podcasts/
                                    episodes
                                             │
                                             ▼
                                     ┌──────────────┐
                                     │ PodcastPage  │
                                     └──────────────┘
Et je garderais une règle importante

API ≠ base ≠ repository ≠ interface ≠ lecteur.

Cela nous évitera de finir avec un gros podcast_page.dart qui fait simultanément du HTTP, du SQL, du parsing et de la lecture audio.

Ordre de développement

Je te propose de procéder exactement dans cet ordre :

1. podcast.dart
2. podcast_episode.dart
3. podcast_api.dart
4. podcast_database.dart
5. podcast_repository.dart
6. podcast_player.dart
7. tests API
8. tests SQLite
9. synchronisation
10. podcast_page.dart

Et avant d'écrire podcast_api.dart, il faut vérifier la version actuelle de l'API Podcast Index et ses endpoints/authentification, car ce sont des informations qui peuvent évoluer.
