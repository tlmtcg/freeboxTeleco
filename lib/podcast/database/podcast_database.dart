
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class PodcastDatabase {
  static const String _databaseName = 'podcasts.db';
  static const int _databaseVersion = 3;

  static PodcastDatabase? _instance;
  static Database? _database;

  PodcastDatabase._();

  static PodcastDatabase get instance {
    _instance ??= PodcastDatabase._();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE radios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        search_term TEXT NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE podcasts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        podcast_index_id INTEGER UNIQUE,
        radio_id INTEGER,
        title TEXT NOT NULL,
        description TEXT,
        image_url TEXT,
        feed_url TEXT,
        website_url TEXT,
        categories TEXT,
        last_updated INTEGER,

        FOREIGN KEY (radio_id)
          REFERENCES radios(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE episodes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        podcast_id INTEGER NOT NULL,
        guid TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        audio_url TEXT NOT NULL,
        image_url TEXT,
        published_at INTEGER,
        duration_seconds INTEGER,
        listened INTEGER NOT NULL DEFAULT 0,
        position_seconds INTEGER NOT NULL DEFAULT 0,
        last_played_at INTEGER,

        UNIQUE (podcast_id, guid),

        FOREIGN KEY (podcast_id)
          REFERENCES podcasts(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_podcasts_radio
      ON podcasts(radio_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_episodes_podcast
      ON episodes(podcast_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_episodes_published
      ON episodes(published_at)
    ''');

    await db.execute('''
      CREATE INDEX idx_episodes_last_played
      ON episodes(last_played_at)
    ''');
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE podcasts ADD COLUMN categories TEXT',
      );
    }

    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE episodes ADD COLUMN last_played_at INTEGER',
      );

      await db.execute('''
        CREATE INDEX idx_episodes_last_played
        ON episodes(last_played_at)
      ''');
    }
  }

  Future<void> close() async {
    final db = _database;

    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    await databaseFactory.deleteDatabase(path);

    _database = null;
  }
}
