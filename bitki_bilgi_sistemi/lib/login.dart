import 'package:bitki_bilgi_sistemi/database/database_service.dart';
import 'package:bitki_bilgi_sistemi/main.dart';
import 'package:flutter/material.dart';
import 'package:bitki_bilgi_sistemi/sing_up.dart';

class Login extends StatelessWidget {
  Login({super.key});

  final _emailController =
      TextEditingController(); // Girilen verileri kontrol edebilmek için Controller ataması yapılıyor
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      /* Uygulamanın dış çerçevesini kısıtlar yani bildirim paneli ile
         uygulama ekranının üst üste binmesini engeller*/
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
              image: DecorationImage(
                  fit: BoxFit.fitHeight,
                  image: AssetImage("lib/assets/images/bitki_resim.jpg"))),
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,  // Column'un içerdiği widgetleri sayfanın sanunda hızalar
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 30, right: 30),
                  child: Card.filled(  // Card görünümünü soluklaştırır
                    child: Padding(
                      padding: EdgeInsets.only(left: 15),
                      child: TextFormField(
                        controller: _emailController,   // controller ile email text alanına girilen bilgilere 
                        decoration: InputDecoration(    // erişmemize olanak sağlar böylece veriyi inceleyebilir parçalayabilir ve değiştirebiliriz
                            labelText: "  E-Posta",
                            border: InputBorder
                                .none), // Border none kullanarak metin alanındaki alt çizgiyi kaldırılır
                        keyboardType: TextInputType.emailAddress,  // klavyeyi email girebilecek şekilde ayarlar
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 30, right: 30),
                  child: Card.filled(  // filled kullanarak card görünümünü soluklaştırılır
                    child: Padding(
                      padding: EdgeInsets.only(left: 15),
                      child: TextFormField(
                        controller: _passwordController,  // şifre bilgisine erişimi sağlar
                        decoration: InputDecoration(
                            labelText: "  Şifre", border: InputBorder.none),
                        obscureText: true,  // metin karakterlerini şifre şeklinde gizleyerek girmeyi sağlar
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                ElevatedButton(
                    onPressed: () {
                      _logIn(context);
                    },
                    child: Text(
                      "Giriş Yap",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(    // buton görünümünü özelleştirmemizi sağlar
                      backgroundColor: Colors.blue,
                    )),
                SizedBox(height: 20),
                Text(
                  "Hesabınız Yok Mu?",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(     // push metodu ile kullanıcıyı istenilen sayfaya yönlendirmeyi sağlar
                      context,
                      MaterialPageRoute(builder: (context) => SingUp()),  // yönlendirilecek sayfa girilir
                    );
                  },
                  child: Text("Kayıt Ol"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

 // async komutu fonksiyonun cevap döndürmesini beklemeden diğer fonksiyonları çalışabilir hale getirir
 // sonuç döndürmesi uzun süren fonksiyonlarda kullanılır.
  void _logIn(BuildContext context) async { 
    String email = _emailController.text;     
    String password = _passwordController.text;

    final dbService = DatabaseService();  // Veri tabanına erişim sağlıyor

    // E-posta ve şifrenin veritabanında olup olmadığını kontrol et
    bool isValid = await dbService.girisYap(email, password);  /* Veri tabanındaki kullanicilar tablosuna 
    erişerek girilen email ve şifre duğru mu karşılaştırması yapıyor ve bool yanıt döndürüyor
    await komutu bu sorgu tamamlanmadan if sorgusuna geçmemesini sağlıyor */

    if (isValid) {  // dönen değer true ise
      // Giriş başarılıysa ana sayfaya yönlendirir
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => BitkiBilgi()));
      _emailController.clear();
      _passwordController.clear();
    } else {
      // Hata mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(   //kullanıcı bilgilerinin eşleşmemesi durumunda bir bildirim göstermeyi sağlıyor
        SnackBar(
          content: Row(children: [
            Text(
              'E-posta veya şifre hatalı',
            ),
            SizedBox(width: 8),
            Icon(                             // işlem sonucu ile ilgili bir icon gösteriyor
              Icons.error_outline_outlined,
              color: Colors.red,
            )
          ]),
        ),
      );
    }
  }
}
