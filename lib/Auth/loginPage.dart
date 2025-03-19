
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scooter/Auth/registerPage.dart';
import 'package:scooter/afterLogin/mainScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  final FirebaseFirestore? firestore;
  LoginPage({Key? key, this.title , this.firestore}) : super(key: key);
  final String? title;

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formSignInKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool rememberPassword = false;
  String? emailReset;
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    _loadUserEmailPassword();
  }

  void _loadUserEmailPassword() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var email = prefs.getString("email") ?? "";
      var password = prefs.getString("password") ?? "";
      var rememberMe = prefs.getBool("remember_me") ?? false;

      if (rememberMe) {
        setState(() {
          _emailController.text = email;
          _passwordController.text = password;
          rememberPassword = rememberMe;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<bool> passwordResetWithMail({required String mail}) async {
    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: mail)
          .get();

      if (userQuery.docs.isNotEmpty) {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: mail);
        return true;
      }
      return false;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  void _login() async {
    if (_formSignInKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // E-posta doğrulama kontrolü
        if (!userCredential.user!.emailVerified) {
          setState(() {
            _isLoading = false;
          });

          AwesomeDialog(
            context: context,
            dialogType: DialogType.warning,
            dismissOnTouchOutside: false,
            animType: AnimType.scale,
            title: 'E-posta Doğrulanmadı',
            desc: 'Hesabınızı kullanabilmek için lütfen e-posta adresinizi doğrulayın.',
            btnOkText: 'Yeni Doğrulama E-postası Gönder',
            btnCancelText: 'Tamam',
            btnOkOnPress: () async {
              try {
                await userCredential.user!.sendEmailVerification();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Yeni doğrulama e-postası gönderildi.'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Doğrulama e-postası gönderilemedi. Lütfen daha sonra tekrar deneyin.'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            btnCancelOnPress: () {},
          ).show();
          return;
        }

        // E-posta doğrulanmışsa giriş yap
        if (rememberPassword) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('email', _emailController.text);
          await prefs.setString('password', _passwordController.text);
          await prefs.setBool('remember_me', rememberPassword);
        }

        // Firestore'dan kullanıcı bilgilerini al
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_emailController.text)
            .get();

        String nameSurname = userDoc['nameSurname'];
        String email = userDoc['email'];

        setState(() {
          _isLoading = false;
        });

        AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          dismissOnTouchOutside: false,
          animType: AnimType.bottomSlide,
          title: 'Giriş Başarılı',
          desc: 'Hoş geldiniz!',
          btnOkOnPress: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainScreen(
                  nameSurname: nameSurname,
                  email: email,
                ),
              ),
            );
          },
          btnOkText: 'Devam Et',
        ).show();

      } on FirebaseAuthException catch (e) {
        setState(() {
          _isLoading = false;
        });

        String errorMessage = 'Giriş yapılamadı';
        if (e.code == 'user-not-found') {
          errorMessage = 'Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Hatalı şifre girdiniz.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Geçersiz e-posta adresi.';
        }

        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.bottomSlide,
          title: 'Giriş Başarısız',
          desc: errorMessage,
          btnOkOnPress: () {},
          btnOkText: 'Tamam',
          btnOkColor: Colors.red,
        ).show();
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
                    // Logo veya İkon
                    Container(
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
                    ),
                    SizedBox(height: 30),
                    // Karşılama Metni
                    Text(
                      'Tekrar Hoşgeldiniz!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Devam etmek için giriş yapın',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 40),
                    // Giriş Formu
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
                        key: _formSignInKey,
                        child: Column(
                          children: [
                            // E-posta Alanı
                            TextFormField(
                              controller: _emailController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Lütfen e-posta adresinizi girin.";
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
                              obscureText: !_isPasswordVisible,
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
                                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                    color: Color(0xFF416FDF),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
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
                            // Beni Hatırla & Şifremi Unuttum
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: rememberPassword,
                                        onChanged: (value) {
                                          setState(() {
                                            rememberPassword = value!;
                                          });
                                        },
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        activeColor: Color(0xFF416FDF),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Beni hatırla',
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => Padding(
                                        padding: EdgeInsets.only(
                                          bottom: MediaQuery.of(context).viewInsets.bottom,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(24),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              topRight: Radius.circular(20),
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text(
                                                    'Şifre Sıfırlama',
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF416FDF),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    icon: const Icon(Icons.close),
                                                    color: Colors.grey,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              const Text(
                                                'Şifre sıfırlama bağlantısı almak için e-posta adresinizi girin',
                                                style: TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              TextField(
                                                decoration: InputDecoration(
                                                  filled: true,
                                                  fillColor: Colors.grey[100],
                                                  prefixIcon: const Icon(Icons.email, color: Color(0xFF416FDF)),
                                                  hintText: 'E-posta adresinizi girin',
                                                  hintStyle: const TextStyle(color: Colors.black45),
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
                                                    borderSide: const BorderSide(color: Color(0xFF416FDF)),
                                                  ),
                                                ),
                                                onChanged: (mail) {
                                                  emailReset = mail;
                                                },
                                              ),
                                              const SizedBox(height: 24),
                                              SizedBox(
                                                width: double.infinity,
                                                height: 55,
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF416FDF),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(15),
                                                    ),
                                                  ),
                                                  onPressed: () async {
                                                    if (emailReset != null && emailReset!.isNotEmpty) {
                                                      bool success = await passwordResetWithMail(mail: emailReset!);
                                                      Navigator.pop(context); // Close modal first

                                                      if (success) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(
                                                            content: Text('Şifre sıfırlama bağlantısı e-posta adresinize gönderildi'),
                                                            backgroundColor: Color(0xFF416FDF),
                                                            behavior: SnackBarBehavior.floating,
                                                            duration: Duration(seconds: 3),
                                                          ),
                                                        );
                                                      } else {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(
                                                            content: Text('Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı. Lütfen önce kayıt olun.'),
                                                            backgroundColor: Colors.red,
                                                            behavior: SnackBarBehavior.floating,
                                                            duration: Duration(seconds: 3),
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  },
                                                  child: const Text(
                                                    'Şifreyi Sıfırla',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Şifremi Unuttum',
                                    style: TextStyle(
                                      color: Color(0xFF416FDF),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 30),
                            // Giriş Butonu
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF416FDF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : Text(
                                  'Giriş Yap',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    // Kayıt Ol Linki
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Hesabınız yok mu? ',
                          style: TextStyle(color: Colors.white70),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SignUpPage()),
                            );
                          },
                          child: Text(
                            'Kayıt Ol',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
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
