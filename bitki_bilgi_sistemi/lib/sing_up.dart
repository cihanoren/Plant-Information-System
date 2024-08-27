import 'package:flutter/material.dart';
import 'package:bitki_bilgi_sistemi/database/database_service.dart';
import 'package:hexcolor/hexcolor.dart';

class SingUp extends StatefulWidget {
  SingUp({super.key});

  @override
  State<SingUp> createState() => _SingUpState();
}

class _SingUpState extends State<SingUp> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.fitHeight,
                  image: AssetImage("lib/assets/images/bitki_resim.jpg"))),
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [                
                SizedBox(height: 15),
                Padding(
                  padding: EdgeInsets.only(left: 30, right: 30),
                  child: Card.filled(
                    child: Padding(
                      padding: EdgeInsets.only(left: 15),
                      child: TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                            labelText: "E-Posta", border: InputBorder.none),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 30, right: 30),
                  child: Card.filled(
                    child: Padding(
                      padding: EdgeInsets.only(left: 15),
                      child: TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                            labelText: "Şifre", border: InputBorder.none),
                        obscureText: true,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () async {
                    await _kullaniciEkle(context);
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: Text(
                    "Kayıt Ol",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _kullaniciEkle(BuildContext context) async {
  final email = _emailController.text;
  final sifre = _passwordController.text;

  // E-posta ve şifre alanlarının boş olup olmadığını kontrol et
  if (email.isEmpty || sifre.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("E-posta ve şifre alanları boş bırakılamaz."),
        backgroundColor: Colors.red,
      ),
    );
    return; // Fonksiyonun geri kalanını çalıştırma
  }

  final dbService = DatabaseService();

  bool isRegistered = await dbService.emailKayitliMi(email);

  if (isRegistered) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Bu e-posta adresi zaten kayıtlı."),
        backgroundColor: Colors.red,
      ),
    );
  } else {
    await dbService.kullaniciEkle(email, sifre);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Kayıt Başarılı"),
            SizedBox(width: 8),
            Icon(
              Icons.check_circle,
              color: HexColor("#00A300"),
            ),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    _emailController.clear();
    _passwordController.clear();
  }
}

}
