import 'dart:async';
import 'package:bitki_bilgi_sistemi/database/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart'; // CSV paketini import edin
import 'package:hexcolor/hexcolor.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


// Bitki Adı Ekle Dialogu Gösterme Fonksiyonu
void gosterInputDialog(BuildContext context, void Function(String) onConfirm) {
  final TextEditingController bitkiAdiKontrol = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Bitki Adı Ekle'),
        content: TextField(
          textCapitalization: TextCapitalization.words,
          keyboardType: TextInputType.text,
          controller: bitkiAdiKontrol,
          decoration: const InputDecoration(hintText: 'Bitki adı girin'),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('İptal'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Tamam'),
            onPressed: () {
              final girilenBitkiAdi = bitkiAdiKontrol.text;
              Navigator.of(context).pop();
              onConfirm(girilenBitkiAdi); // Kullanıcının girdiği bitki adını geri döndürür
            },
          ),
        ],
      );
    },
  );
}

// Su İpucu
void suMiktarIpucu(BuildContext context) {
  const snackBar = SnackBar(
    content: Text('Su miktarını mL cinsinden girin.'),
    duration: Duration(seconds: 2), // SnackBar'ın ne kadar süre görünür olacağını ayarlayın
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

// Bitki Adı Listesini Yükleyen Fonksiyon
Future<List<String>> bitkiAdiListesiniYukle() async {
  final rawData = await rootBundle.loadString('lib/assets/veriler/yaygin_bitkiler.csv');  // rootBundle dışarıdan dahil edilen dosyaların okunlamsını sağlar
  final List<List<dynamic>> satirlar = const CsvToListConverter().convert(rawData);
  final List<String> bitkiAdlari = satirlar.map((satir) => satir.isNotEmpty ? satir[0].toString() : '').toList();
  return bitkiAdlari;
}

// İngilizce Bitki Adı Listesini Yükleyen Fonksiyon
Future<List<String>> ingilizceBitkiAdiListesiniYukle() async {
  final rawData = await rootBundle.loadString('lib/assets/veriler/bitkiler_ingilizce.csv');
  final List<List<dynamic>> satirlar = const CsvToListConverter().convert(rawData);
  final List<String> bitkiAdlari = satirlar.map((satir) => satir.isNotEmpty ? satir[0].toString() : '').toList();
  return bitkiAdlari;
}

// Bitki Adını Kontrol Etme Fonksiyonu
Future<bool> bitkiAdiniKontrolEt(String bitkiAdi) async {
  final bitkiAdlari = await bitkiAdiListesiniYukle();
  return bitkiAdlari.contains(bitkiAdi);
}

// İngilizce Bitki Adını Kontrol Etme Fonksiyonu
Future<bool> ingilizceBitkiAdiniKontrolEt(String bitkiAdi) async {
  final bitkiAdlari = await ingilizceBitkiAdiListesiniYukle();
  return bitkiAdlari.contains(bitkiAdi);
}

// Bitki Adına Göre Su İhtiyacını Çeken Fonksiyon
Future<Map<String, double>> bitkiVerileriniYukle() async {
  // CSV dosyasını yükle
  final rawData = await rootBundle.loadString('lib/assets/veriler/sulama_2_deneme.csv');
  
  // CSV verilerini ayrıştır
  final List<List<dynamic>> satirlar = const CsvToListConverter(eol: '\n', fieldDelimiter: ';').convert(rawData);
  
  // Bitki verilerini saklayacağımız harita
  final Map<String, double> bitkiVerileri = {};
  
  // Her satırı işle
  for (var satir in satirlar) {
    if (satir.isNotEmpty && satir.length >= 2) {
      final bitkiAdi = satir[0].toString().trim(); // Bitki adını al
      final suIhtiyaciStr = satir[1].toString().trim(); // Su ihtiyacını al
      
      // Su ihtiyacını double türüne dönüştür
      final suIhtiyaci = double.tryParse(suIhtiyaciStr);
      
      // Eğer dönüştürme başarılıysa, bitki verilerine ekle
      if (suIhtiyaci != null) {
        bitkiVerileri[bitkiAdi] = suIhtiyaci;
      }
    }
  }
  
  return bitkiVerileri;
}

// Şehir Listesini Yükleyen Fonksiyon
Future<List<String>> sehirListesiniYukle() async {
  final rawData = await rootBundle.loadString('lib/assets/veriler/sehirler.csv');
  final List<List<dynamic>> satirlar = const CsvToListConverter().convert(rawData);
  final List<String> sehirler = satirlar.map((satir) => satir.isNotEmpty ? satir[0].toString() : '').toList();
  return sehirler;
}

// Bitki Bilgilerini Güncelleyen Fonksiyon
Future<void> bitkiGuncelleDialog(
  BuildContext context,
  int id,
  String bitkiAd,
  String sulamaMiktari,
  String sulamaTarihi,
  VoidCallback onUpdate,
) async {
  final TextEditingController bitkiAdController = TextEditingController(text: bitkiAd);
  final TextEditingController sulamaMiktariController = TextEditingController(text: sulamaMiktari);
  final TextEditingController sulamaTarihiController = TextEditingController(text: sulamaTarihi);

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return SingleChildScrollView(
        child: AlertDialog(
          title: const Text('Bitki Güncelle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bitkiAdController,
                decoration: const InputDecoration(labelText: 'Bitki Adı'),
              ),
              TextField(
                controller: sulamaMiktariController,
                decoration: const InputDecoration(labelText: 'Sulama Miktarı (mL)'),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
              TextField(
                controller: sulamaTarihiController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(labelText: 'Kaç Saat Önce Sulandı'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Güncelle'),
              onPressed: () async {
                final updatedBitkiAd = bitkiAdController.text.trim();
                final updatedSulamaMiktari = sulamaMiktariController.text.trim();
                final updatedSulamaTarihi = sulamaTarihiController.text.trim();

                // Alanların boş olup olmadığını kontrol et
                if (updatedBitkiAd.isEmpty || updatedSulamaMiktari.isEmpty || updatedSulamaTarihi.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen tüm alanları doldurunuz.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return; // Güncelleme işlemini iptal et
                }

                // Bitki adını kontrol et
                final bitkiMevcutMu = await bitkiAdiniKontrolEt(updatedBitkiAd);

                if (bitkiMevcutMu) {
                  try {
                    // Veritabanında güncelleme işlemi
                    await DatabaseService().bitkiGuncelle(
                      id,
                      updatedBitkiAd,
                      updatedSulamaMiktari,
                      updatedSulamaTarihi,
                    );

                    // Güncelleme başarılı olduğunda SnackBar'ı göster
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: HexColor("#00A300"),),
                            SizedBox(width: 8),
                            Text('Güncelleme başarılı!'),
                          ],
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );

                    // Güncelleme tamamlandıktan sonra callback'i çağır
                    Navigator.of(context).pop();
                    onUpdate(); // Ana sayfayı güncelle
                  } catch (e) {
                    // Hata durumunda AlertDialog'ı göster
                    Navigator.of(context).pop(); // Önce mevcut dialog'u kapat
                    showDialog<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Hata'),
                          content: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_rounded, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Güncelleme sırasında bir hata oluştu: $e'),
                              ),
                            ],
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Tamam'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }
                } else {
                  // Bitki adı sistemde mevcut değilse uyarı göster
                  Navigator.of(context).pop(); // Önce mevcut dialog'u kapat
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Girdiğiniz bitki adı mevcut değil.'),
                        ],
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      );
    },
  );
}


// Hava Durumu Bilgisi Çekme ve API Fonksiyonu
class WeatherService {
  final String apiKey = '72a31be699345b0d53815942b0cd579e';  // OpenWeatherMap API anahtarı

  Future<Map<String, dynamic>> fetchWeather(String city) async {
    final response = await http.get(
      Uri.parse('https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric')
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Hava durumu verileri alınamadı.');
    }
  }
}

// Sulama Zamanı Tahmin Fonksiyonu
Future<Duration?> tahminiSulamaZamaniHesapla(
  String bitkiAdi,
  int verilenSu,
  int gecenSaat,
  double sicaklik, // Sıcaklık çarpanı
) async {
  // Bitki verilerini ve su ihtiyaçlarını içeren CSV'den verileri yükler
  final bitkiVerileri = await bitkiVerileriniYukle();
  final suIhtiyaciMl = bitkiVerileri[bitkiAdi];
  
  if (suIhtiyaciMl == null) {
    // Bitki adı verilerde bulunamadı
    return null;
  }

  // Geçen sürede bitkiye verilen su miktarını hesaplayalım
  final verilenSuToplam = verilenSu * (gecenSaat / 24);

  // Su ihtiyacı ile verilen suyu karşılaştıralım
  final kalanSuIhtiyaci = suIhtiyaciMl - verilenSuToplam;

  // Eğer kalan su ihtiyacı 0 veya negatifse, bitki hemen sulanmalıdır
  if (kalanSuIhtiyaci <= 0) {
    return Duration.zero;
  }

  // Sıcaklık çarpanını kullanarak tahmini sulama zamanını hesaplayalım
  final sicaklikCarpani = _sicaklikCarpani(sicaklik);

  // Kalan su ihtiyacına göre tahmini sulama zamanını hesaplayalım
  final kalanSaat = kalanSuIhtiyaci / (verilenSuToplam * sicaklikCarpani);

  // Kalan saat değerini clample ederek doğru bir süre döndürme
  final kalanSaatClamped = kalanSaat.clamp(0, double.infinity);

  return Duration(hours: kalanSaatClamped.toInt());
}

// Sıcaklık çarpanını belirleyen fonksiyon
double _sicaklikCarpani(double sicaklik) {
  if (sicaklik <= 20) return 1.0;
  if (sicaklik <= 25) return 1.05;
  if (sicaklik <= 30) return 1.1;
  return 1.2;
}

