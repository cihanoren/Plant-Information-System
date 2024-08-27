import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _veritabani;

  // Veritabanı bağlantısını almak için 
  Future<Database> get veritabani async {
    if (_veritabani != null) return _veritabani!;
    _veritabani = await _veritabaniBaslat();
    return _veritabani!;
  }

  // Veritabanını başlatma ve oluşturma fonksiyonu
  Future<Database> _veritabaniBaslat() async {
    // Veritabanı dosyasının yolunu oluştur
    String yol = join(await getDatabasesPath(), 'Bitki_Bilgi_Sistemi.db');
    // Veritabanını oluştur ve döndür
    return await openDatabase(
      yol,
      version: 2, // Veritabanı sürümünü artırdık
      onCreate: _veritabaniOlustur,
      onUpgrade:
          _veritabaniGuncelle, // Veritabanı güncelleme fonksiyonunu ekleyin
    );
  }

  // Veritabanı ilk oluşturulduğunda çağrılan fonksiyon
  Future<void> _veritabaniOlustur(Database db, int versiyon) async {  // veri tabanı oluşturulduktan sonra tabloları oluşturuyor
    await db.execute('''
      CREATE TABLE bitkiler_(
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        bitki_adi TEXT NOT NULL, 
        sulama_miktari TEXT,
        sulama_tarihi TEXT 
      )
    ''');

    await db.execute('''
      CREATE TABLE sehirler(
        key TEXT PRIMARY KEY, 
        value TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE kullanicilar(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT NOT NULL,
      sifre TEXT NOT NULL
      )
    ''');
  }

  // Veritabanı güncelleme fonksiyonu
  Future<void> _veritabaniGuncelle(
      Database db, int eskiVersiyon, int yeniVersiyon) async {
    if (eskiVersiyon < 2) {
      await db.execute('''
        CREATE TABLE sehirler(
          key TEXT PRIMARY KEY, 
          value TEXT
        )
      ''');
    }
  }

  // Kullanıcı ekleme fonksiyonu
  Future<void> kullaniciEkle(String email, String sifre) async {
    final db = await veritabani;
    Map<String, dynamic> yeniKullanici = {
      'email': email,
      'sifre': sifre,
    };

    await db.insert('kullanicilar', yeniKullanici,
        conflictAlgorithm: ConflictAlgorithm.ignore); 
        /* ekleme algoritması kullanıyorum ve ignore yöntemi ile kaydedilmek istenen veri
         daha öncesinde veri tabanında bulunuyorsa eski veriyi değiştirmesini engelliyor */  
  }

  // DatabaseService içinde
  Future<bool> emailKayitliMi(String email) async {
    final db = await veritabani;
    final List<Map<String, dynamic>> maps = await db.query(
      'kullanicilar',
      where: 'email = ?',
      whereArgs: [email],
    );
    return maps.isNotEmpty;
  }

  // Kullanıcıları Çeken Fonksiyon
  Future<List<Map<String, dynamic>>> tumKullanicilariGetir() async {
    final db = await veritabani; // Veritabanı bağlantısını alın
    return await db.query('kullanicilar'); // Tüm kullanıcıları getir
  }

  // Kullanıcı silme fonksiyonu
  Future<void> kullaniciSil(int id) async {
    final db = await veritabani;
    await db.delete(
      'kullanicilar',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Giriş Kontrol Fonksiyonu
  Future<bool> girisYap(String email, String password) async {
    final db = await veritabani;
    final List<Map<String, dynamic>> maps = await db.query(
      'kullanicilar',
      where: 'email = ? AND sifre = ?',
      whereArgs: [email, password],
    );
    return maps.isNotEmpty;
  }

  // Yeni bitki ekleme fonksiyonu
  Future<void> bitkiEkle(
      String bitkiAd, String sulamaMiktari, String sulamaTarihi) async {
    final db = await veritabani;
    Map<String, dynamic> yeniBitki = {
      'bitki_adi': bitkiAd, // Bitki adı
      'sulama_miktari': sulamaMiktari, // Sulama miktarı
      'sulama_tarihi': sulamaTarihi, // Sulama tarihi
    };

    // Yeni bitki verilerini veritabanına ekle
    await db.insert('bitkiler_', yeniBitki,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Veritabanındaki bitkileri listeleme fonksiyonu
  Future<List<Map<String, dynamic>>> bitkileriListele() async {
    final db = await veritabani; // Veritabanı bağlantısını al
    final List<Map<String, dynamic>> maps = await db.query('bitkiler_');
    return maps;
  }

  // Bitki silme fonksiyonu
  Future<void> bitkiSil(int id) async {
    final db = await veritabani;
    await db.delete(
      'bitkiler_',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Bitki güncelleme fonksiyonu
  Future<void> bitkiGuncelle(int id, String bitkiAdi, String sulamaMiktari,
      String sulamaTarihi) async {
    final db = await veritabani;
    await db.update(
      'bitkiler_',
      {
        'bitki_adi': bitkiAdi,
        'sulama_miktari': sulamaMiktari,
        'sulama_tarihi': sulamaTarihi
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Seçilen şehri veritabanına kaydetme fonksiyonu
  Future<void> setSelectedCity(String city) async {
    final db = await veritabani;
    await db.insert(
      'sehirler',
      {'key': 'city', 'value': city},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Veritabanından seçilen şehri alma fonksiyonu
  Future<String?> getSelectedCity() async {
    final db = await veritabani;
    final List<Map<String, dynamic>> maps = await db.query(
      'sehirler',
      where: 'key = ?',
      whereArgs: ['city'],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }
}
