
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scooter/Auth/loginPage.dart';

class SignUpPage extends StatefulWidget {
  SignUpPage({Key ?key, this.title}) : super(key: key);

  final String? title;

  @override
  _SignUpPageState createState() => _SignUpPageState();
}


class _SignUpPageState extends State<SignUpPage> {

  final _formSingUpKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameSurnameController = TextEditingController();
  final TextEditingController _truePassController = TextEditingController();
  bool _isPasswordVisible1 = false;
  bool _isPasswordVisible2 = false;
  bool confirmation = false;
  String? _errorMessage;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> _checkIfUserExists(String email) async {
    final QuerySnapshot emailSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    return emailSnapshot.docs.isNotEmpty;
  }

  void _register() async {
    setState(() {
      if (!confirmation) {
        _errorMessage = "Lütfen kayıt olmak için kişisel verilerin işlenmesini onaylayın.";
      } else {
        _errorMessage = null;
      }
    });

    if (_formSingUpKey.currentState!.validate() && confirmation) {
      String nameSurname = _nameSurnameController.text;
      String email = _emailController.text;
      String password = _passwordController.text;
      String password2 = _truePassController.text;

      bool userExists = await _checkIfUserExists(email);

      if (userExists) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.warning,
          animType: AnimType.scale,
          title: 'Hata',
          desc: 'Bu e-posta adresi zaten kullanılıyor.',
          btnOkOnPress: () {
            _emailController.clear();
            _nameSurnameController.clear();
            _passwordController.clear();
            _truePassController.clear();
          },
          btnOkColor: Colors.red,
          btnOkText: 'Tamam',
        ).show();
      } else {
        if (password != password2) {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.warning,
            animType: AnimType.scale,
            title: 'Hata',
            desc: 'Girdiğiniz şifreler eşleşmiyor. Lütfen kontrol edin.',
            btnOkOnPress: () {
              _passwordController.clear();
              _truePassController.clear();
            },
            btnOkColor: Colors.red,
            btnOkText: 'Tamam',
          ).show();
        } else {
          try {
            // Kullanıcı oluştur
            UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );

            // E-posta doğrulama linki gönder
            await userCredential.user!.sendEmailVerification();

            // Firestore'a kullanıcı bilgilerini kaydet
            await FirebaseFirestore.instance.collection('users').doc(email).set({
              'nameSurname': nameSurname,
              'email': email,
              'createdAt': FieldValue.serverTimestamp(),
            });

            AwesomeDialog(
              context: context,
              dialogType: DialogType.success,
              animType: AnimType.bottomSlide,
              dismissOnTouchOutside: false,
              title: 'Kayıt Başarılı',
              desc: 'E-posta adresinize doğrulama bağlantısı gönderdik. Lütfen e-postanızı kontrol edin ve hesabınızı doğrulayın.',
              btnOkText: 'Giriş Sayfasına Git',
              btnOkOnPress: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                      (route) => false,
                );
              },
            ).show();
          } on FirebaseAuthException catch (e) {
            String errorMessage = 'Bir hata oluştu';
            if (e.code == 'weak-password') {
              errorMessage = 'Şifre çok zayıf. Lütfen daha güçlü bir şifre belirleyin.';
            } else if (e.code == 'invalid-email') {
              errorMessage = 'Geçersiz e-posta adresi.';
            }

            AwesomeDialog(
              context: context,
              dialogType: DialogType.error,
              animType: AnimType.scale,
              title: 'Hata',
              desc: errorMessage,
              btnOkOnPress: () {},
              btnOkColor: Colors.red,
              btnOkText: 'Tamam',
            ).show();
          }
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF416FDF),
                Color(0xFF5B86E5),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    SizedBox(height: 50),
                    // Logo Container
                    /*Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.electric_scooter,
                        size: 72,
                        color: Colors.white,
                      ),
                    ),*/

                    SizedBox(height: 30),
                    // Karşılama Metni
                    Text(
                      'Hoş Geldiniz!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Hesap oluşturmak için bilgilerinizi girin',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 40),
                    // Kayıt Formu
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formSingUpKey,
                        child: Column(
                          children: [
                            // Ad Soyad Alanı
                            TextFormField(
                              controller: _nameSurnameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Lütfen ad ve soyadınızı girin.";
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[100],
                                prefixIcon: Icon(Icons.person, color: Color(0xFF416FDF)),
                                hintText: 'Ad Soyad',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(color: Color(0xFF416FDF)),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            // Email Alanı
                            TextFormField(
                              controller: _emailController,
                              validator: (value) {
                                if (value != null && value.isNotEmpty && !value.contains('@')) {
                                  return "Geçerli bir e-posta adresi girin.";
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[100],
                                prefixIcon: Icon(Icons.email, color: Color(0xFF416FDF)),
                                hintText: 'E-posta',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(color: Color(0xFF416FDF)),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            // Şifre Alanı
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible1,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Lütfen şifrenizi girin';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[100],
                                prefixIcon: Icon(Icons.lock, color: Color(0xFF416FDF)),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible1 ? Icons.visibility : Icons.visibility_off,
                                    color: Color(0xFF416FDF),
                                  ),
                                  onPressed: () => setState(() => _isPasswordVisible1 = !_isPasswordVisible1),
                                ),
                                hintText: 'Şifre',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(color: Color(0xFF416FDF)),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            // Şifre Tekrar Alanı
                            TextFormField(
                              controller: _truePassController,
                              obscureText: !_isPasswordVisible2,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Lütfen şifrenizi tekrar girin';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[100],
                                prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF416FDF)),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible2 ? Icons.visibility : Icons.visibility_off,
                                    color: Color(0xFF416FDF),
                                  ),
                                  onPressed: () => setState(() => _isPasswordVisible2 = !_isPasswordVisible2),
                                ),
                                hintText: 'Şifre Tekrar',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(color: Color(0xFF416FDF)),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            // Onay Kutusu
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: confirmation,
                                      onChanged: (value) {
                                        setState(() {
                                          confirmation = value!;
                                          if (confirmation) _errorMessage = null;
                                        });
                                      },
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      activeColor: Color(0xFF416FDF),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Kişisel verilerin işlenmesini onaylıyorum",
                                      style: TextStyle(
                                        color: _errorMessage != null ? Colors.red : Colors.grey[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red, fontSize: 12),
                                ),
                              ),
                            SizedBox(height: 30),
                            // Kayıt Ol Butonu
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF416FDF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 2,
                                ),
                                child: Text(
                                  'Kayıt Ol',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    // Giriş Yap Linki
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Zaten hesabınız var mı? ',
                          style: TextStyle(color: Colors.white70),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LoginPage()),
                            );
                          },
                          child: Text(
                            'Giriş Yap',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
