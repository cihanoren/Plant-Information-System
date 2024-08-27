import 'package:bitki_bilgi_sistemi/database/database_service.dart';
import 'package:bitki_bilgi_sistemi/fonksiyonlar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexcolor/hexcolor.dart';

class KayitSayfa extends StatefulWidget {
  final String bitkiAdi;

  const KayitSayfa({super.key, required this.bitkiAdi});

  @override
  _KayitSayfaState createState() => _KayitSayfaState();
}

class _KayitSayfaState extends State<KayitSayfa> {
  late TextEditingController _bitkiAdiController;
  late TextEditingController _sulamaSaatiController;
  late TextEditingController _suMiktariController;

  @override
  void initState() {
    super.initState();
    _bitkiAdiController = TextEditingController(text: widget.bitkiAdi);
    _sulamaSaatiController = TextEditingController();
    _suMiktariController = TextEditingController();
  }

  @override
  void dispose() {
    _bitkiAdiController.dispose();
    _sulamaSaatiController.dispose();
    _suMiktariController.dispose();
    super.dispose();
  }

  // Veritabanına bitki ekleme fonksiyonu
  void _bitkiEkle() async {
    final bitkiAdi = _bitkiAdiController.text;
    final sulamaMiktari = _suMiktariController.text;
    final sulamaTarihi = _sulamaSaatiController.text;

    final dbService = DatabaseService();
    await dbService.bitkiEkle(bitkiAdi, sulamaMiktari, sulamaTarihi);

    // SnackBar ile bilgi verme
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Bitki Başarıyla Kaydedildi"),
            SizedBox(
              width: 8,
            ),
            Icon(
              Icons.check_circle,
              color: HexColor("#00A300"),
            ),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pushNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
              image: DecorationImage(
                  fit: BoxFit.fitHeight,
                  image: AssetImage("lib/assets/images/bitki_resim4.jpg"))),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: TextField(
                      keyboardType: TextInputType.text,
                      controller: _bitkiAdiController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Bitki Adı',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: TextField(
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      controller: _sulamaSaatiController,
                      decoration: const InputDecoration(
                        labelText: 'Kaç Saat Önce Sulandı ?',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: TextField(
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      controller: _suMiktariController,
                      onTap: () {
                        suMiktarIpucu(context);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Ne Kadar Su Verildi ?',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: () {
                      _bosAlanKontrol();
                      final bitkiAdi = _bitkiAdiController.text;
                      final sulamaSaati = _sulamaSaatiController.text;
                      final suMiktari = _suMiktariController.text;

                      if (_bosAlanKontrol()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                const Text('Lütfen tüm alanları doldurunuz!'),
                            duration: Duration(seconds: 2),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Kaydediliyor'),
                              content: Text(
                                'Bitki Adı: $bitkiAdi\n'
                                'Kaç Saat Önce Sulandı: $sulamaSaati\n'
                                'Ne Kadar Su Verildi: $suMiktari mL',
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Tamam'),
                                  onPressed: () {
                                    _bosAlanKontrol();
                                    _bitkiEkle(); // Bitki ekleme işlemini yap
                                    Navigator.of(context).popUntil((route) =>
                                        route
                                            .isFirst); // Ana sayfaya dönüş yapar
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    child: const Text(
                      'KAYDET',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _bosAlanKontrol() {
    String bitkiAdi = _bitkiAdiController.text.trim();
    String sulamaSaati = _sulamaSaatiController.text.trim();
    String suMiktari = _suMiktariController.text.trim();

    if (bitkiAdi.isEmpty || sulamaSaati.isEmpty || suMiktari.isEmpty) {
      // Eğer herhangi bir alan boşsa, true döndür
      return true;
    }

    // Tüm alanlar doluysa false döndür
    return false;
  }
}
