import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:randonnee/screens/map.dart';
import 'dart:math' show log, pi, pow, tan, cos;

class DatabaseService {
  static const _version = 9;
  static const _dbName = 'HikeApp.db';
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, _dbName);

    print('📁 Chemin de la base : $path');

    return await openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createAllTables(db);
    print('✅ Toutes les tables créées avec succès');
    await insertTestData(db);
    print('✅ Données de test insérées');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Upgrading database from $oldVersion to $newVersion');

    if (oldVersion < 2) await _migrateV1ToV2(db);
    if (oldVersion < 3) await _migrateV2ToV3(db);
    if (oldVersion < 4) await _migrateV3ToV4(db);
    if (oldVersion < 5) await _migrateV4ToV5(db);
    if (oldVersion < 6) await _migrateV5ToV6(db);
    if (oldVersion < 7) await _migrateV6ToV7(db);
    if (oldVersion < 8) await _migrateV7ToV8(db);
    if (oldVersion < 9) await _migrateV8ToV9(db);
  }

  Future<void> _migrateV1ToV2(Database db) async {
    try {
      print('✅ Migrated to V2 successfully');
    } catch (e) {
      print('❌ V2 migration error: $e');
      rethrow;
    }
  }

  Future<void> _migrateV2ToV3(Database db) async {
    try {
      await db.execute('DROP TABLE IF EXISTS messages');
      await db.execute('DROP TABLE IF EXISTS conversations');

      await db.execute('''
        CREATE TABLE conversations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user1_id INTEGER NOT NULL,
          user2_id INTEGER NOT NULL,
          last_message_at TEXT,
          FOREIGN KEY (user1_id) REFERENCES users(id) ON DELETE CASCADE,
          FOREIGN KEY (user2_id) REFERENCES users(id) ON DELETE CASCADE,
          UNIQUE (user1_id, user2_id)
        )
      ''');

      await db.execute('''
        CREATE TABLE messages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          conversation_id INTEGER NOT NULL,
          sender_id INTEGER NOT NULL,
          content TEXT NOT NULL,
          sent_at TEXT DEFAULT (datetime('now','localtime')),
          is_read INTEGER DEFAULT 0,
          FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
          FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE)
      ''');

      print('✅ Migrated to V3 successfully (messaging system)');
    } catch (e) {
      print('❌ V3 migration error: $e');
      rethrow;
    }
  }

  Future<void> _migrateV3ToV4(Database db) async {
    try {
      print('✅ Migrated to V4 successfully');
    } catch (e) {
      print('❌ V4 migration error: $e');
      rethrow;
    }
  }

  Future<void> _migrateV4ToV5(Database db) async {
    try {
      print('✅ Migrated to V5 successfully');
    } catch (e) {
      print('❌ V5 migration error: $e');
      rethrow;
    }
  }

  Future<void> _migrateV5ToV6(Database db) async {
    try {
      print('🔄 Début migration V5 vers V6');

      await db.execute('''
      CREATE TABLE IF NOT EXISTS hike_reviews_temp (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hike_id TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        rating INTEGER NOT NULL CHECK(rating >= 1 AND rating <= 5),
        comment TEXT,
        created_at TEXT
      )
    ''');

      await db.execute('''
      INSERT INTO hike_reviews_temp 
      SELECT * FROM hike_reviews
    ''');

      await db.execute('DROP TABLE IF EXISTS hike_reviews');

      await db.execute('''
      CREATE TABLE hike_reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hike_id TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        rating INTEGER NOT NULL CHECK(rating >= 1 AND rating <= 5),
        comment TEXT,
        created_at TEXT DEFAULT (datetime('now','localtime')),
        FOREIGN KEY (hike_id) REFERENCES hikes(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

      await db.execute('''
      INSERT INTO hike_reviews 
      SELECT * FROM hike_reviews_temp
    ''');

      await db.execute('DROP TABLE IF EXISTS hike_reviews_temp');

      print('✅ Migration V5 vers V6 terminée avec succès');
    } catch (e) {
      print('❌ Erreur migration V5 vers V6: $e');
      rethrow;
    }
  }

  Future<void> _migrateV6ToV7(Database db) async {
    try {
      // Vérifie d'abord si la colonne existe déjà
      final columns = await db.rawQuery("PRAGMA table_info(users)");
      final roleColumnExists = columns.any((col) => col['name'] == 'role');

      if (!roleColumnExists) {
        await db.execute(
          'ALTER TABLE users ADD COLUMN role TEXT DEFAULT "user"',
        );
        print('✅ Colonne role ajoutée à la table users');
      } else {
        print('ℹ️ La colonne role existe déjà');
      }
    } catch (e) {
      print('❌ V7 migration error: $e');
      rethrow;
    }
  }

  Future<void> _migrateV7ToV8(Database db) async {
    try {
      print('🔄 Début migration V7 vers V8 (tables pour GPS hors ligne)');

      // Création de la table pour les parcours enregistrés
      await db.execute('''
      CREATE TABLE IF NOT EXISTS hike_paths (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hike_id TEXT NOT NULL,
        path_data TEXT NOT NULL,
        saved_at TEXT NOT NULL,
        FOREIGN KEY (hike_id) REFERENCES hikes(id) ON DELETE CASCADE
      )
    ''');

      // Création de la table pour les itinéraires enregistrés
      await db.execute('''
      CREATE TABLE IF NOT EXISTS saved_routes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hike_id TEXT NOT NULL,
        route_data TEXT NOT NULL,
        saved_at TEXT NOT NULL,
        FOREIGN KEY (hike_id) REFERENCES hikes(id) ON DELETE CASCADE
      )
    ''');

      // Création de la table pour le cache des tuiles (si elle n'existe pas déjà)
      await db.execute('''
      CREATE TABLE IF NOT EXISTS map_tiles (
        x INTEGER NOT NULL,
        y INTEGER NOT NULL,
        z INTEGER NOT NULL,
        tile_data BLOB NOT NULL,
        last_accessed INTEGER NOT NULL,
        PRIMARY KEY (x, y, z)
      )
    ''');

      print('✅ Migration V7 vers V8 terminée avec succès');
    } catch (e) {
      print('❌ Erreur migration V7 vers V8: $e');
      rethrow;
    }
  }

  Future<void> _migrateV8ToV9(Database db) async {
    try {
      // Vérifie si les colonnes existent déjà
      final columns = await db.rawQuery("PRAGMA table_info(hikes)");
      final needsMigration =
          !columns.any((col) => col['name'] == 'average_rating');

      if (needsMigration) {
        await db.execute('''
        CREATE TABLE hikes_new (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          location TEXT NOT NULL,
          wilaya TEXT NOT NULL,
          latitude REAL,
          longitude REAL,
          description TEXT NOT NULL,
          distance REAL NOT NULL,
          duration REAL NOT NULL,
          difficulty TEXT NOT NULL,
          imageUrl TEXT,
          creator_id INTEGER,
          average_rating REAL DEFAULT 0,
          created_at TEXT DEFAULT (datetime('now','localtime')),
          review_count INTEGER DEFAULT 0,
          FOREIGN KEY (creator_id) REFERENCES users(id)
        )
      ''');

        // Copie les anciennes données
        await db.execute('''
        INSERT INTO hikes_new (
          id, title, location, wilaya, latitude, longitude, 
          description, distance, duration, difficulty, imageUrl, creator_id
        )
        SELECT 
          id, title, location, wilaya, latitude, longitude, 
          description, distance, duration, difficulty, imageUrl, creator_id
        FROM hikes
      ''');

        // Remplace l'ancienne table
        await db.execute('DROP TABLE hikes');
        await db.execute('ALTER TABLE hikes_new RENAME TO hikes');

        print('✅ Migration V8 vers V9 terminée (colonnes stats ajoutées)');
      }
    } catch (e) {
      print('❌ Erreur migration V8 vers V9: $e');
      rethrow;
    }
  }

  Future<void> _createAllTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT DEFAULT 'user', 
        created_at TEXT DEFAULT (datetime('now','localtime'))
        )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS hikes (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      location TEXT NOT NULL,
      wilaya TEXT NOT NULL,
      latitude REAL,
      longitude REAL,
      description TEXT NOT NULL,
      distance REAL NOT NULL,
      duration REAL NOT NULL,
      difficulty TEXT NOT NULL,
      imageUrl TEXT,
      creator_id INTEGER,
      average_rating REAL DEFAULT 0,          
      created_at TEXT DEFAULT (datetime('now','localtime')),  
      review_count INTEGER DEFAULT 0,         
      FOREIGN KEY (creator_id) REFERENCES users(id)
    )
  ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS saved_hikes (
        user_id INTEGER NOT NULL,
        hike_id TEXT NOT NULL,
        saved_at TEXT DEFAULT (datetime('now','localtime')),
        PRIMARY KEY (user_id, hike_id),
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (hike_id) REFERENCES hikes(id))
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS conversations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user1_id INTEGER NOT NULL,
        user2_id INTEGER NOT NULL,
        last_message_at TEXT,
        FOREIGN KEY (user1_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (user2_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE (user1_id, user2_id))
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        conversation_id INTEGER NOT NULL,
        sender_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        sent_at TEXT DEFAULT (datetime('now','localtime')),
        is_read INTEGER DEFAULT 0,
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
        FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE)
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS hike_reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hike_id TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        rating INTEGER NOT NULL CHECK(rating >= 1 AND rating <= 5),
        comment TEXT,
        created_at TEXT DEFAULT (datetime('now','localtime')),
        FOREIGN KEY (hike_id) REFERENCES hikes(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE)
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS hike_paths (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hike_id TEXT NOT NULL,
        path_data TEXT NOT NULL,
        saved_at TEXT NOT NULL,
        FOREIGN KEY (hike_id) REFERENCES hikes(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS saved_routes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hike_id TEXT NOT NULL,
        route_data TEXT NOT NULL,
        saved_at TEXT NOT NULL,
        FOREIGN KEY (hike_id) REFERENCES hikes(id) ON DELETE CASCADE
      )
    ''');

    await _insertDefaultHikes(db);
  }

  Future<void> _insertDefaultHikes(Database db) async {
    final defaultHikes = [
      {
        'id': '1',
        'title': 'Tassili N\'Ajjer',
        'location': 'Djanet, Algérie',
        'wilaya': 'Djanet',
        'latitude': 24.8333,
        'longitude': 9.5000,
        'description': 'Randonnée dans le désert',
        'distance': 25.0,
        'duration': 8.0,
        'difficulty': 'Difficile',
        'imageUrl': 'assets/images/tassili.jpg',
        'creator_id': null,
      },
      {
        'id': '2',
        'title': 'Chréa',
        'location': 'Blida, Algérie',
        'wilaya': 'Blida',
        'latitude': 36.4167,
        'longitude': 2.8833,
        'description': 'Randonnée en montagne dans le parc national de Chréa',
        'distance': 12.0,
        'duration': 4.0,
        'difficulty': 'Moyen',
        'imageUrl': 'assets/images/chrea.jpg',
        'creator_id': null,
      },
      {
        'id': '3',
        'title': 'Djurdjura',
        'location': 'Tizi Ouzou, Algérie',
        'wilaya': 'Tizi Ouzou',
        'latitude': 36.4667,
        'longitude': 4.0667,
        'description': 'Randonnée dans le massif du Djurdjura',
        'distance': 15.0,
        'duration': 6.0,
        'difficulty': 'Difficile',
        'imageUrl': 'assets/images/djurdjura.jpg',
        'creator_id': null,
      },
      {
        'id': '4',
        'title': 'Ghoufi',
        'location': 'Batna, Algérie',
        'wilaya': 'Batna',
        'latitude': 35.5833,
        'longitude': 6.1833,
        'description': 'Randonnée dans les gorges de Ghoufi',
        'distance': 10.0,
        'duration': 5.0,
        'difficulty': 'Moyen',
        'imageUrl': 'assets/images/ghoufi.jpg',
        'creator_id': null,
      },
    ];

    for (final hike in defaultHikes) {
      await db.insert(
        'hikes',
        hike,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> verifyTables() async {
    final db = await this.db;
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      print('✅ Tables existantes: ${tables.map((t) => t['name']).toList()}');

      final requiredTables = ['users', 'hikes', 'hike_reviews'];
      final missingTables =
          requiredTables
              .where((t) => !tables.any((table) => table['name'] == t))
              .toList();

      if (missingTables.isNotEmpty) {
        throw Exception('Tables manquantes: $missingTables');
      }
    } catch (e) {
      print('❌ Erreur vérification tables: $e');
      rethrow;
    }
  }

  static String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // test de donnéee
  Future<void> insertTestData(Database db) async {
    // 1. Insère un user admin
    await db.insert('users', {
      'name': 'celia',
      'email': 'hammoum@gmail.com',
      'password': _hashPassword('celia123'),
      'role': 'admin',
    });

    // 2. Insère un second admin
    await db.insert('users', {
      'name': 'imine',
      'email': 'imine@gmail.com',
      'password': _hashPassword('imine456'),
      'role': 'admin',
    });

    // 3. Insère un user normal
    await db.insert('users', {
      'name': 'Test User',
      'email': 'test@example.com',
      'password': _hashPassword('user123'),
      'role': 'user',
    });
  }

  // =============== Méthodes Reviews ===============
  Future<int> addHikeReview(Map<String, dynamic> review) async {
    final db = await this.db;
    // 1. On récupère l'ID de la randonnée concernée
    final hikeId = review['hike_id'] as String;

    // 2. On insère l'avis dans la table hike_reviews
    final reviewId = await db.insert('hike_reviews', review);

    // 3. ON AJOUTE CETTE LIGNE CRUCIALE
    await _updateHikeRating(
      hikeId,
    ); // Met à jour la note moyenne de la randonnée

    return reviewId;
  }

  Future<List<Map<String, dynamic>>> getHikeReviews(String hikeId) async {
    final db = await this.db;
    return await db.rawQuery(
      '''
    SELECT r.*, u.name as user_name 
    FROM hike_reviews r
    JOIN users u ON r.user_id = u.id
    WHERE r.hike_id = ?
    ORDER BY r.created_at DESC
  ''',
      [hikeId],
    );
  }

  Future<double> getAverageRating(String hikeId) async {
    final db = await this.db;
    final result = await db.rawQuery(
      '''
    SELECT AVG(rating) as average 
    FROM hike_reviews 
    WHERE hike_id = ?
  ''',
      [hikeId],
    );
    return (result.first['average'] as num?)?.toDouble() ?? 0.0;
  }

  // =============== Méthodes Users ===============
  Future<int> createUser(Map<String, dynamic> user) async {
    final db = await this.db;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await this.db;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await this.db;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllUsersExcept(
    int excludedUserId,
  ) async {
    try {
      final db = await this.db;
      return await db.query(
        'users',
        where: 'id != ?',
        whereArgs: [excludedUserId],
        orderBy: 'name ASC', // Tri alphabétique
      );
    } catch (e) {
      print('❌ Erreur getAllUsersExcept: $e');
      rethrow;
    }
  }

  // =============== Méthodes Hikes ===============
  Future<int> createHike(Map<String, dynamic> hike) async {
    final db = await this.db;
    return await db.insert('hikes', hike);
  }

  Future<Map<String, dynamic>?> getHikeById(String id) async {
    final db = await this.db;
    final result = await db.query('hikes', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllHikes() async {
    final db = await this.db;
    return await db.query('hikes');
  }

  Future<List<Map<String, dynamic>>> getUserHikes(int userId) async {
    final db = await this.db;
    return await db.query(
      'hikes',
      where: 'creator_id = ?',
      whereArgs: [userId],
    );
  }

  // =============== Méthodes Saved Hikes ===============
  Future<int> saveHikeForUser(int userId, String hikeId) async {
    final db = await this.db;
    return await db.insert('saved_hikes', {
      'user_id': userId,
      'hike_id': hikeId,
    });
  }

  Future<List<Map<String, dynamic>>> getSavedHikes(int userId) async {
    final db = await this.db;
    return await db.rawQuery(
      '''
      SELECT hikes.* FROM hikes
      INNER JOIN saved_hikes ON hikes.id = saved_hikes.hike_id
      WHERE saved_hikes.user_id = ?
      ''',
      [userId],
    );
  }

  // =============== Méthodes Conversations ===============
  Future<int> getOrCreateConversation(int user1Id, int user2Id) async {
    final db = await this.db;

    // Vérifie si la conversation existe déjà
    final existing = await db.query(
      'conversations',
      where:
          '(user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?)',
      whereArgs: [user1Id, user2Id, user2Id, user1Id],
    );

    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    // Crée une nouvelle conversation
    return await db.insert('conversations', {
      'user1_id': user1Id < user2Id ? user1Id : user2Id,
      'user2_id': user1Id < user2Id ? user2Id : user1Id,
      'last_message_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> deleteConversation(int conversationId) async {
    final db = await this.db;
    return await db.delete(
      'conversations',
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  Future<List<Map<String, dynamic>>> getUserConversations(int userId) async {
    final db = await this.db;

    return await db.rawQuery(
      '''
      SELECT 
        c.id,
        u.id as other_user_id,
        u.name as other_user_name,
        m.content as last_message,
        m.sent_at as last_message_time
      FROM conversations c
      JOIN users u ON (u.id = CASE 
        WHEN c.user1_id = ? THEN c.user2_id 
        ELSE c.user1_id 
      END)
      LEFT JOIN messages m ON m.id = (
        SELECT id FROM messages 
        WHERE conversation_id = c.id
        ORDER BY sent_at DESC 
        LIMIT 1
      )
      WHERE c.user1_id = ? OR c.user2_id = ?
      ORDER BY m.sent_at DESC
    ''',
      [userId, userId, userId],
    );
  }

  // =============== Méthodes Messages ===============
  Future<int> sendMessage(Map<String, dynamic> message) async {
    final db = await this.db;
    final messageId = await db.insert('messages', message);

    // Met à jour le timestamp de la dernière conversation
    await db.update(
      'conversations',
      {'last_message_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [message['conversation_id']],
    );

    return messageId;
  }

  Future<int> markMessagesAsRead(int conversationId, int userId) async {
    final db = await this.db;
    return await db.update(
      'messages',
      {'is_read': 1},
      where: 'conversation_id = ? AND sender_id != ?',
      whereArgs: [conversationId, userId],
    );
  }

  Future<List<Map<String, dynamic>>> getMessagesForConversation(
    int conversationId,
  ) async {
    final db = await this.db;
    return await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'sent_at ASC',
    );
  }

  // ========= Suppression Base de donnée =======

  Future<void> deleteDatabase() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, _dbName);
    await File(path).delete();
    print('🗑️ Base de données supprimée');
  }
  // clé étrangére

  Future<void> verifyForeignKeys() async {
    final db = await this.db;
    try {
      // Utilisez query au lieu de rawQuery
      final result = await db.query(
        'sqlite_master',
        where: 'type = ? AND sql LIKE ?',
        whereArgs: ['table', '%FOREIGN KEY%'],
      );
      print('✅ Tables avec clés étrangères: ${result.length}');
    } catch (e) {
      print('❌ Erreur vérification clés étrangères: $e');
    }
  }

  // test clé étrangére
  Future<void> testForeignKeys() async {
    final db = await this.db;

    // 1. Vérifie les données existantes
    final users = await db.query('users', limit: 1);
    final hikes = await db.query('hikes', limit: 1);

    if (users.isEmpty || hikes.isEmpty) {
      print('⚠️ Base vide - exécutez _insertTestData() d\'abord');
      return;
    }
  }

  // =============== Méthode d'exportation ===============
  Future<String> exportDatabase() async {
    try {
      // Chemin actuel de la base
      Directory appDir = await getApplicationDocumentsDirectory();
      String dbPath = '${appDir.path}/$_dbName';

      // Dossier de téléchargements (accessible)
      Directory? downloadsDir = await getDownloadsDirectory();
      String exportPath = '${downloadsDir?.path}/HikeApp_export.db';

      // Copie le fichier
      await File(dbPath).copy(exportPath);

      print('✅ Base exportée vers : $exportPath');
      return exportPath;
    } catch (e) {
      print('❌ Erreur d\'export : $e');
      throw Exception('Échec de l\'export : $e');
    }
  }

  // =============== Méthode de DEBUG ===============
  Future<void> debugPrintTableStructure() async {
    final db = await this.db;
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'",
    );

    for (final table in tables) {
      final tableName = table['name'];
      print('\nTable $tableName:');
      final cols = await db.rawQuery('PRAGMA table_info($tableName)');
      for (final col in cols) {
        print(
          '${col['name']} (${col['type']}) ${col['notnull'] == 1 ? 'NOT NULL' : ''}',
        );
      }

      final fks = await db.rawQuery('PRAGMA foreign_key_list($tableName)');
      if (fks.isNotEmpty) {
        print('Clés étrangères:');
        for (final fk in fks) {
          print(
            '- ${fk['from']} → ${fk['table']}.${fk['to']} (ON DELETE: ${fk['on_delete']})',
          );
        }
      }
    }
  }

  // pour hors ligne
  Future<void> saveHikePath(String hikeId, List<Position3D> path) async {
    final db = await this.db;
    await db.insert('hike_paths', {
      'hike_id': hikeId,
      'path_data': jsonEncode(
        path.map((p) => [p.latitude, p.longitude, p.altitude]).toList(),
      ),
      'saved_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Position3D>?> getHikePath(String hikeId) async {
    final db = await this.db;
    final result = await db.query(
      'hike_paths',
      where: 'hike_id = ?',
      whereArgs: [hikeId],
      orderBy: 'saved_at DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      final data = jsonDecode(result.first['path_data'] as String) as List;
      return data.map((e) => Position3D(e[0], e[1], e[2])).toList();
    }
    return null;
  }

  // Dans DatabaseService :
  Future<void> saveRoute(String hikeId, List<LatLng> route) async {
    final db = await this.db;
    await db.insert('saved_routes', {
      'hike_id': hikeId,
      'route_data': jsonEncode(
        route.map((p) => [p.latitude, p.longitude]).toList(),
      ),
      'saved_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<LatLng>?> getRoute(String hikeId) async {
    final db = await this.db;
    final result = await db.query(
      'saved_routes',
      where: 'hike_id = ?',
      whereArgs: [hikeId],
      orderBy: 'saved_at DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      final data = jsonDecode(result.first['route_data'] as String) as List;
      return data.map((e) => LatLng(e[0], e[1])).toList();
    }
    return null;
  }

  Future<void> initMapCache() async {
    final db = await this.db;
    try {
      // Vérifie d'abord si la table existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='map_tiles'",
      );

      if (tables.isEmpty) {
        // Crée la table si elle n'existe pas
        await db.execute('''
        CREATE TABLE map_tiles (
          x INTEGER NOT NULL,
          y INTEGER NOT NULL,
          z INTEGER NOT NULL,
          tile_data BLOB NOT NULL,
          last_updated INTEGER NOT NULL,
          PRIMARY KEY (x, y, z)
        )
      ''');
      } else {
        // Vérifie si la colonne last_updated existe
        final columns = await db.rawQuery("PRAGMA table_info(map_tiles)");
        final hasLastUpdated = columns.any(
          (col) => col['name'] == 'last_updated',
        );

        if (!hasLastUpdated) {
          await db.execute(
            'ALTER TABLE map_tiles ADD COLUMN last_updated INTEGER NOT NULL DEFAULT 0',
          );
        }
      }
      print('✅ Map tile cache initialized/verified');
    } catch (e) {
      print('❌ Error initializing map cache: $e');
      rethrow;
    }
  }

  Future<Uint8List?> getMapTile(int x, int y, int z) async {
    final db = await this.db;
    try {
      final result = await db.query(
        'map_tiles',
        where: 'x = ? AND y = ? AND z = ?',
        whereArgs: [x, y, z],
      );

      if (result.isNotEmpty) {
        print('✅ Tile $z/$x/$y found in cache');
        return result.first['tile_data'] as Uint8List;
      } else {
        print('ℹ️ Tile $z/$x/$y not in cache');
        return null;
      }
    } catch (e) {
      print('❌ Error getting tile $z/$x/$y: $e');
      return null;
    }
  }

  Future<void> saveMapTile(int x, int y, int z, Uint8List tileData) async {
    final db = await this.db;
    try {
      await db.insert('map_tiles', {
        'x': x,
        'y': y,
        'z': z,
        'tile_data': tileData,
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print('❌ Error saving tile: $e');
      rethrow;
    }
  }

  Future<void> downloadMapArea(LatLng center, int zoom, int radius) async {
    int successCount = 0;
    int failCount = 0;

    for (int x = -radius; x <= radius; x++) {
      for (int y = -radius; y <= radius; y++) {
        try {
          final tileX =
              ((center.longitude + 180) / 360 * pow(2, zoom)).floor() + x;
          final tileY =
              ((1 -
                          log(
                                tan(center.latitude * pi / 180) +
                                    1 / cos(center.latitude * pi / 180),
                              ) /
                              pi) /
                      2 *
                      pow(2, zoom))
                  .floor() +
              y;

          final url = 'https://tile.openstreetmap.org/$zoom/$tileX/$tileY.png';
          final response = await http.get(Uri.parse(url));

          if (response.statusCode == 200) {
            await saveMapTile(tileX, tileY, zoom, response.bodyBytes);
            successCount++;
          } else {
            failCount++;
            print(
              '⚠️ Failed to download tile $zoom/$tileX/$tileY - Status: ${response.statusCode}',
            );
          }

          await Future.delayed(Duration(milliseconds: 50));
        } catch (e) {
          failCount++;
          print('❌ Error downloading tile: $e');
        }
      }
    }

    print('✅ Download completed: $successCount tiles saved, $failCount failed');
  }

  Future<void> cacheMapTile(int x, int y, int z, String url) async {
    try {
      final existing = await getMapTile(x, y, z);
      if (existing != null) return;

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await saveMapTile(x, y, z, response.bodyBytes);
      }
    } catch (e) {
      print('Erreur cache tuile: $e');
    }
  }

  Future<void> preloadTiles(LatLng center, int zoom, int radius) async {
    try {
      for (int x = -radius; x <= radius; x++) {
        for (int y = -radius; y <= radius; y++) {
          final tileX = _longitudeToTileX(center.longitude, zoom) + x;
          final tileY = _latitudeToTileY(center.latitude, zoom) + y;

          final url = 'https://tile.openstreetmap.org/$zoom/$tileX/$tileY.png';
          final response = await http.get(Uri.parse(url));

          if (response.statusCode == 200) {
            await saveMapTile(tileX, tileY, zoom, response.bodyBytes);
            print('Tuile $zoom/$tileX/$tileY préchargée');
          }
        }
      }
    } catch (e) {
      print('Erreur lors du préchargement: $e');
    }
  }

  int _longitudeToTileX(double lon, int zoom) {
    return ((lon + 180) / 360 * pow(2, zoom)).floor();
  }

  int _latitudeToTileY(double lat, int zoom) {
    return ((1 - log(tan(lat * pi / 180) + 1 / cos(lat * pi / 180)) / pi) /
            2 *
            pow(2, zoom))
        .floor();
  }

  // statistiques

  Future<Map<String, dynamic>> getStatsSummary() async {
    final db = await this.db;

    final userCount =
        (await db.rawQuery(
              'SELECT COUNT(*) as count FROM users',
            )).first['count']
            as int;

    final hikeCount =
        (await db.rawQuery(
              'SELECT COUNT(*) as count FROM hikes',
            )).first['count']
            as int;

    final avgRating =
        (await db.rawQuery('''
      SELECT AVG(hike_reviews.rating) as avg 
      FROM hike_reviews 
      WHERE rating > 0
    ''')).first['avg']
            as double?;

    return {
      'userCount': userCount,
      'hikeCount': hikeCount,
      'avgRating': avgRating ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getRecentHikes({int limit = 5}) async {
    final db = await this.db;
    return db.query('hikes', orderBy: 'created_at DESC', limit: limit);
  }

  Future<List<Map<String, dynamic>>> getTopRatedHikes({int limit = 5}) async {
    final db = await this.db;
    return db.query(
      'hikes',
      where: 'average_rating > 0',
      orderBy: 'average_rating DESC',
      limit: limit,
    );
  }

  Future<void> _updateHikeRating(String hikeId) async {
    final db = await this.db;

    // 1. Calcule la nouvelle moyenne
    final avgResult = await db.rawQuery(
      '''
    SELECT AVG(rating) as avg, COUNT(id) as count 
    FROM hike_reviews 
    WHERE hike_id = ?
  ''',
      [hikeId],
    );

    final avgRating = avgResult.first['avg'] as double?;
    final reviewCount = avgResult.first['count'] as int;

    // 2. Met à jour la randonnée
    await db.update(
      'hikes',
      {'average_rating': avgRating ?? 0, 'review_count': reviewCount},
      where: 'id = ?',
      whereArgs: [hikeId],
    );
  }
}
