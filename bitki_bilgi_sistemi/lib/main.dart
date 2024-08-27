import 'dart:async'; // Timer'ı kullanmak için
import 'package:bitki_bilgi_sistemi/kullanici_sil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart'; // CSV dosyalarını okuyabilmek için gerekli paketler
import 'package:bitki_bilgi_sistemi/database/database_service.dart';
import 'package:bitki_bilgi_sistemi/kayit_sayfa.dart'; // Kayıt sayfasını içeri aktarma
import 'package:bitki_bilgi_sistemi/fonksiyonlar.dart'; // Fonksiyonlar sayfasını içeri aktarma
import 'package:hexcolor/hexcolor.dart';
import 'package:bitki_bilgi_sistemi/login.dart';

Future<void> main() async {
  runApp(const MyApp()); // Uygulamanın çalışmasını sağlayan method
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: "/login",
      routes: {
        '/login': (context) => Login(),
        '/home': (context) => BitkiBilgi(),
      },
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      debugShowCheckedModeBanner: false, // Banner'ı Kaldırır
    );
  }
}

class BitkiBilgi extends StatefulWidget {
  const BitkiBilgi({super.key});

  @override
  State<BitkiBilgi> createState() => _BitkiBilgiState();
}

class BitkiSayac {
  Timer? timer;
  int kalanSure; // Kalan süreyi saniye olarak saklar

  BitkiSayac({this.kalanSure = 0});
}

class _BitkiBilgiState extends State<BitkiBilgi> {
  Future<List<Map<String, dynamic>>>? _bitkiler;
  List<String>? _sehirler;
  String? _seciliSehir;
  String? _havaDurumu;

  Map<int, BitkiSayac> _bitkiSayaclar =
      {}; // Her bitki için sayaçları ve süreleri tutacak

  @override
  void initState() {
    // initState Fonksiyonu uygulama başladığı anda çalışacak fonksiyonları içerir
    super.initState();
    _loadBitkiler(); // Uygulama başlatıldığında veritabanındaki verileri listeler
    _loadSehirler();
  }

  @override
  void dispose() {
    // Nesnelerin yaşam döngüsü sonlandığında temizlenmesini sağlar
    // Timer'ları Temizler
    _bitkiSayaclar.forEach((id, sayac) => sayac.timer?.cancel());
    super.dispose();
  }

  // Geri Sayım Fonksiyonu
  void _geriSayimBaslat(int bitkiId, Duration sure) {
    setState(() {
      // Eğer daha önce bir timer varsa iptal eder
      _bitkiSayaclar[bitkiId]?.timer?.cancel();

      // Yeni kalan süreyi başlat
      _bitkiSayaclar[bitkiId] = BitkiSayac()
        ..kalanSure = sure.inSeconds
        ..timer = Timer.periodic(Duration(seconds: 1), (timer) {
          setState(() {
            if (_bitkiSayaclar[bitkiId]!.kalanSure > 0) {
              _bitkiSayaclar[bitkiId]!.kalanSure--;
            } else {
              timer.cancel();
              // Geri sayım tamamlandığında UI'ı günceller (USER INTERFACE)
            }
          });
        });
    });
  }

  // Bitkileri yükleme fonksiyonu
  void _loadBitkiler() {
    setState(() {
      _bitkiler = DatabaseService()
          .bitkileriListele(); // Database'deki  bitkileri listeler
    });
  }

  // Şehirleri yükleme fonksiyonu
  Future<void> _loadSehirler() async {
    final rawData = await rootBundle.loadString(
        'lib/assets/veriler/sehirler.csv'); // CSV dosyasındaki şehirleri ayıklar
    final List<List<dynamic>> csvData =
        const CsvToListConverter().convert(rawData);
    final sehirler = csvData.map((row) => row[0].toString()).toList();

    final selectedCity = await DatabaseService()
        .getSelectedCity(); // Uygulama kapanmadan önce seçilmiş şehiri veritabanından getirir

    setState(() {
      _sehirler = sehirler;
      _seciliSehir = selectedCity;
    });
  }

  // Bitki silme fonksiyonu
  Future<void> _bitkiSil(int id) async {
    await DatabaseService().bitkiSil(
        id); // Veritabanındaki bitkileri silmeyi sağlayan fonksiyonun çağırır
    // Sayacı iptal et
    _bitkiSayaclar[id]
        ?.timer
        ?.cancel(); // Kayıtlı bitki silinirse sayaç hata oluşturmasın diye sayacı da kaldırır
    _bitkiSayaclar.remove(id);
    _loadBitkiler();
  }

  // Bitki ekleme ve düzenleme için dialog gösterme
  void _showDialog() {
    gosterInputDialog(context, (bitkiAdi) async {
      final bitkiMevcutMu = await bitkiAdiniKontrolEt(
          bitkiAdi); // Gerekli fonksiyon çağrılarak CSV dosyasından kontrol yapar
      if (bitkiMevcutMu) {
        Navigator.of(context)
            .push(
          // True değer dönerse kullanıcıyı verilen sayfaya yönlendirir
          MaterialPageRoute(
            builder: (context) => KayitSayfa(bitkiAdi: bitkiAdi),
          ),
        )
            .then((_) {
          _loadBitkiler(); // Bitki kaydetme işlemi yapıldıktan sonra anasayfayı günceller
        });
      } else {
        showDialog(
          context:
              context, // Widget'lerin kendisine ve üstündeki widget'lere erişmesini sağlar
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Uyarı'),
              content:
                  const Text('Girdiğiniz bitki ismi sistemde kayıtlı değil.'),
              actions: <Widget>[
                // Dialog penceresi açıldığında gerçekleşecek olayları yönetir
                TextButton(
                  child: const Text('Tamam'),
                  onPressed: () {
                    // Butona basıldığında çalışacak işlemleri içeren fonksiyondur
                    Navigator.of(context)
                        .pop(); // Navigator bulunduğu konuma nereden geldiğini hafızada tutar ve pop ile hafızadaki konuma geri dönmeyi sağlar
                  },
                ),
              ],
            );
          },
        );
      }
    });
  }

  // Kullanıcılar Listesi Getirme
  void _showKullaniciListesi() async {
    final dbService = DatabaseService(); // Veri tabanı bağlantısını sağlar
    final kullanicilar = await dbService
        .tumKullanicilariGetir(); // Veri tabanındaki kullanıcıları getirme fonksiyonu çağırılarak veriler değişkene atanıyor
    // Kullanıcı listesini bir dialogda gösteriyor.
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Kullanıcı Listesi'),
          content: SingleChildScrollView(
            // Bottom overflow hatası yaşanmaması için kaydırılabilir yapı sağlıyor
            child: ListBody(
              children: kullanicilar.map((kullanici) {
                return Text('Email: ${kullanici['email']}');
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(); //Butona basıldığında bir önceki sayfaya dönmeyi sağlıyor
              },
              child: Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  // Hava durumu bilgilerini al
  Future<void> _getHavaDurumu(String sehir) async {
    try {
      final weatherData = await WeatherService().fetchWeather(
          sehir); // Hava durumu fonksiyonu ile seçilen şehirin hava durumunu getirir
      setState(() {
        // SetState dinamik bir kontrol sağlıyor gerekli yerleri güncelliyor
        _havaDurumu =
            '${weatherData['main']['temp']} °C'; // Hava durumunun görünümünü formatlar
      });
    } catch (e) {
      setState(() {
        _havaDurumu = 'Hava durumu bilgisi alınamadı.';
      });
    }
  }

  @override // Altında yazılan methodların yukarıdaki üst sınıflarda tanımlanan methodları değiştirmesine olanak tanır
  Widget build(BuildContext context) {
    return Scaffold(
      // Uygulamaya arkaplan katmanı ekler ve bir katman üzerinde çalışmasını sağlar
      appBar: AppBar(
        // Sayfanın en üstündeki alandır
        title: const Text(
          "Bitki Bilgi Sistemi",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'kullanicilari_goster') {
              _showKullaniciListesi();
            } else if (value == 'kullanicilari_sil') {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          KullaniciSil())); // Silme olayının yeni bir sayfada yapılmasını sağlıyor
            } else if (value == 'cikis_yap') {
              Navigator.pushAndRemoveUntil(
                // Gelinen sayfaya geri dönmeyi engelleyecek şekilde gitmeyi sağlıyor
                context, // Yani çıkış yapıldıktan sonra ana sayfaya erişmeyi engelliyor
                MaterialPageRoute(
                    builder: (context) =>
                        Login()), // Çıkış işlemi tamamlandıktan sonra Giriş sayfasına yönlendiriyor
                (route) =>
                    false, // Önceki sayfaların yığından(stack) kaldırılmasını sağlar ve doğrudan verilen sayfayya gitmesini sağlar
              ); // Tüm önceki
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem<String>(
                value: 'kullanicilari_goster',
                child: Text('Kullanıcıları Göster'),
              ),
              PopupMenuItem<String>(
                value: 'kullanicilari_sil',
                child: Text('Kullanıcıları Sil'),
              ),
              PopupMenuItem(
                value: 'cikis_yap',
                child: Text("Çıkış Yap"),
              )
            ];
          },
        ),
        centerTitle: true,
        backgroundColor: HexColor(
            "#00A300"), // HexColor paketi kullanarak Geniş Renk Paletleri kullanılabilir
      ),
      body: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                // Container'e resim eklemek için gerekli widgetler ve özellikler
                fit: BoxFit
                    .fitHeight, // Resime Container'in kapsadığı yükseklik kadar boyut veriyor
                image: AssetImage("lib/assets/images/bitki_resim2.jpg"))),
        child: Column(
          children: [
            Container(
              width: MediaQuery.of(
                      context) // Genişlik olarak cihazın mevcut genişliğini alır
                  .size
                  .width, // Container yapısının cihazın mevcut ölçülerini kullanmasını sağlar
              color: HexColor("#00A300"),
              child: Row(
                mainAxisAlignment: MainAxisAlignment
                    .spaceBetween, // Row widget'inin elemanları arasındaki boşlukları ayarlar
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Text(
                      "Hoşgeldiniz",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  if (_sehirler != null)
                    Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: DropdownButton<String>(
                          // ComboBox benzeri bir yapıdır tıklandığında şehirleri içeren bir liste açar
                          hint: const Text('Şehir Seçin',
                              style: TextStyle(color: Colors.white)),
                          value: _seciliSehir,
                          onChanged: (String? newValue) {
                            // Eğer bir değişim olursa çalışacak hazır fonksiyon
                            setState(() {
                              _seciliSehir = newValue;
                              if (newValue != null) {
                                _getHavaDurumu(newValue);
                                DatabaseService().setSelectedCity(
                                    newValue); // Seçilen şehri veritabanına kaydet
                              }
                            });
                          },
                          items: _sehirler!
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Row(
                                children: [
                                  Text(value,
                                      style:
                                          const TextStyle(color: Colors.black)),
                                  if (_seciliSehir == value &&
                                      _havaDurumu != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text(_havaDurumu!,
                                          style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        )),
                ],
              ),
            ),
            Expanded(
              // Altında kullanılan widget'lerin sınırsız alan kaplamasını engeller
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _bitkiler,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    // Uygulama başlatıldığında yada bütün bitkiler silindiğinde sayfa boşsa yazılacak metin için sayfa analizi yapar
                    return Center(child: Text('Hata: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text(
                      "Kayıtlı bir bitki bulunmuyor",
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ));
                  } else {
                    final bitkiler = snapshot.data!;
                    return ListView.builder(
                      itemCount: bitkiler.length,
                      itemBuilder: (context, index) {
                        final bitki = bitkiler[index];
                        final bitkiId = bitki['id']
                            as int; // bitkiler tablosundan verileri çekip değişkenlere atıyor
                        final bitkiAd = bitki['bitki_adi'] as String;
                        final sulamaMiktari = bitki['sulama_miktari'] as String;
                        final sulamaTarihi = bitki['sulama_tarihi'] as String;

                        // Tahmini sulama zamanı hesapla ve sayacı başlatır
                        final suZamani = tahminiSulamaZamaniHesapla(
                            bitkiAd,
                            int.parse(sulamaMiktari),
                            int.parse(sulamaTarihi),
                            _sicaklikCarpani(1.1));

                        // Geri sayımı başlat, yalnızca ilk oluşturma sırasında yapılır
                        if (!_bitkiSayaclar.containsKey(bitkiId)) {
                          suZamani.then((sure) {
                            if (sure != null) {
                              _geriSayimBaslat(bitkiId, sure);
                            }
                          });
                        }

                        return Dismissible(
                          // Kaydırarak işlem yapmayı sağlar örneğin silme ekleme arşivleme vb.
                          key: Key(bitkiId.toString()),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            final confirmation = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Silme Onayı'),
                                  content: const Text(
                                      'Bu bitkiyi silmek istediğinizden emin misiniz?'),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('Hayır'),
                                      onPressed: () {
                                        Navigator.of(context).pop(false);
                                      },
                                    ),
                                    TextButton(
                                      child: const Text('Evet'),
                                      onPressed: () {
                                        Navigator.of(context).pop(true);
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                            return confirmation ??
                                false; // iki soru işareti varsayınlar değer tanımlamaya yarıyor
                          },
                          onDismissed: (direction) {
                            if (direction == DismissDirection.endToStart) {
                              _bitkiSil(bitkiId);
                            }
                          },
                          background: Container(
                            color: Colors.red,
                            child: const Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: EdgeInsets.only(right: 20),
                                child: Icon(Icons.delete, color: Colors.white),
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                            child: Card(
                              // Eklenen bitkilerin kart şeklinde gözükmesini sağlar
                              child: ListTile(
                                title: Text(
                                  bitkiAd,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kaç Saat Önce Sulandı: $sulamaTarihi\n'
                                      'Sulama Miktarı: $sulamaMiktari mL\n',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 0),
                                    const Text(
                                      'Tahmini Sulama Zamanı: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _bitkiSayaclar.containsKey(bitkiId)
                                          ? '${(_bitkiSayaclar[bitkiId]!.kalanSure / 60).floor()} dakika ${_bitkiSayaclar[bitkiId]!.kalanSure % 60} saniye'
                                          : 'Yükleniyor...',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (String value) {
                                    if (value == 'Düzenle') {
                                      bitkiGuncelleDialog(
                                        context,
                                        bitkiId,
                                        bitkiAd,
                                        sulamaMiktari.toString(),
                                        sulamaTarihi.toString(),
                                        () {
                                          // Ana sayfayı güncelle
                                          _loadBitkiler();
                                        },
                                      );
                                    } else if (value == 'Sil') {
                                      _bitkiSil(bitkiId);
                                    }
                                  },
                                  itemBuilder: (BuildContext context) {
                                    return [
                                      const PopupMenuItem<String>(
                                        value: 'Düzenle',
                                        child: Text('Güncelle'),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'Sil',
                                        child: Text('Sil'),
                                      ),
                                    ];
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                onPressed: _showDialog,
                child: const Text(
                  "EKLE",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Sıcaklık çarpanını belirleyen fonksiyon
  double _sicaklikCarpani(double sicaklik) {
    if (sicaklik <= 20) return 1.0;
    if (sicaklik <= 25) return 1.05;
    if (sicaklik <= 30) return 1.1;
    return 1.2;
  }
}
