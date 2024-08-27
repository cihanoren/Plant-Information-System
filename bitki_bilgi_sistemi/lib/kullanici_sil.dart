import 'package:flutter/material.dart';
import 'package:bitki_bilgi_sistemi/database/database_service.dart';

class KullaniciSil extends StatefulWidget {
  @override
  _KullaniciSilState createState() => _KullaniciSilState();
}

class _KullaniciSilState extends State<KullaniciSil> {
  List<Map<String, dynamic>> _kullanicilar = [];
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _kullanicilariYukle();
  }

  void _kullanicilariYukle() async {
    final kullanicilar = await _dbService.tumKullanicilariGetir();
    setState(() {
      _kullanicilar = kullanicilar;
    });
  }

  Future<void> _kullaniciSil(int id) async {
    await _dbService.kullaniciSil(id);
    _kullanicilariYukle();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Kullanıcıları Sil'),
        ),
        body: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _kullanicilar.length,
                  itemBuilder: (context, index) {
                    final kullanici = _kullanicilar[index];
                    return Card(
                      child: ListTile(
                        title: Text(kullanici['email'] ?? 'Email yok'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          color: Colors.red,
                          onPressed: () {
                            _kullaniciSil(kullanici['id']);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
