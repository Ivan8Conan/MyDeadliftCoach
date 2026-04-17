import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SQLiteHelper {
  static final SQLiteHelper _instance = SQLiteHelper._internal();
  static SQLiteHelper get instance => _instance;
  SQLiteHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'mydeadliftcoach.db');
    
    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabel users
    await db.execute('''
      CREATE TABLE users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        tinggi_badan INTEGER,
        berat_badan INTEGER,
        level TEXT DEFAULT 'Pemula',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabel training_sessions
    await db.execute('''
      CREATE TABLE training_sessions (
        session_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        tanggal DATE NOT NULL,
        waktu_mulai TIMESTAMP NOT NULL,
        waktu_selesai TIMESTAMP,
        jumlah_repetisi INTEGER DEFAULT 0,
        rating_efektivitas REAL,
        FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
      )
    ''');

    // Tabel session_details
    await db.execute('''
      CREATE TABLE session_details (
        detail_id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER,
        timestamp INTEGER NOT NULL,
        sudut_punggung REAL,
        sudut_pinggul REAL,
        sudut_lutut REAL,
        frame_path TEXT,
        FOREIGN KEY (session_id) REFERENCES training_sessions (session_id) ON DELETE CASCADE
      )
    ''');

    // Tabel error_types
    await db.execute('''
      CREATE TABLE error_types (
        error_id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER,
        kode_error TEXT NOT NULL,
        nama_error TEXT NOT NULL,
        time_error TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        risiko TEXT,
        threshold_min REAL,
        threshold_max REAL,
        waktu_feedback TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        pesan_teks TEXT NOT NULL,
        is_played INTEGER DEFAULT 0,
        FOREIGN KEY (session_id) REFERENCES training_sessions (session_id) ON DELETE CASCADE
      )
    ''');
  }


  // Mendaftarkan Pengguna Baru
  Future<int> insertUser(Map<String, dynamic> user) async {
    Database db = await instance.database;
    return await db.insert('users', user);
  }

  // Membuat Sesi Latihan Baru
  Future<int> insertSession(Map<String, dynamic> session) async {
    Database db = await instance.database;
    return await db.insert('training_sessions', session);
  }

  // Mengakhiri Sesi Latihan
  Future<int> updateSession(int sessionId, Map<String, dynamic> session) async {
    Database db = await instance.database;
    return await db.update(
      'training_sessions', 
      session, 
      where: 'session_id = ?', 
      whereArgs: [sessionId]
    );
  }

  // Menyimpan Log Kesalahan / Feedback dari ML
  Future<int> insertErrorLog(Map<String, dynamic> errorLog) async {
    Database db = await instance.database;
    return await db.insert('error_types', errorLog);
  }

  // Mengambil Semua Sesi untuk ditampilkan di HistoryPage
  Future<List<Map<String, dynamic>>> getAllSessions() async {
    Database db = await instance.database;
    return await db.query('training_sessions', orderBy: 'session_id DESC');
  }

  Future<List<Map<String, dynamic>>> getSessionErrors(int sessionId) async {
    Database db = await instance.database;
    return await db.query(
      'error_types',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'time_error ASC',
    );
  }

  // Hapus Sesi Latihan beserta semua log error-nya
  Future<int> deleteSession(int sessionId) async {
    Database db = await instance.database;
    return await db.delete(
      'training_sessions',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }
}