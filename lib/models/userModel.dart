import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scooter/Auth/loginPage.dart';
class User {
  final String userName;
  final String userEmail;

  User({required this.userName, required this.userEmail});

  factory User.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return User(userName: data['userName'], userEmail: data['userEmail']);
  }

  Map<String, dynamic> toMap() {
    return {'userEmail': userEmail, 'userName': userName};
  }

  Future<void> deleteAccount(BuildContext context, String email, String password) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Kullanıcıyı yeniden kimlik doğrulama
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );

        await user.reauthenticateWithCredential(credential);

        // Önce kartları çek
        final cardsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(email)
            .collection('cards')
            .get();

        // Batch işlemi başlat
        final batch = FirebaseFirestore.instance.batch();

        // Her kart için işlemler
        for (var cardDoc in cardsSnapshot.docs) {
          // Kartın transaction'larını çek
          final transactionsSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(email)
              .collection('cards')
              .doc(cardDoc.id)
              .collection('transactions')
              .get();

          // Her transaction'ı sil
          for (var transactionDoc in transactionsSnapshot.docs) {
            batch.delete(transactionDoc.reference);
          }

          // Kartı sil
          batch.delete(cardDoc.reference);
        }

        // Kullanıcı dokümanını sil
        batch.delete(FirebaseFirestore.instance.collection('users').doc(email));

        // Batch işlemini uygula
        await batch.commit();

        // Kullanıcı hesabını sil
        await user.delete();

        // Başarı mesajı gösterme
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hesap başarıyla silindi.')),
        );

        // Login sayfasına yönlendirme
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
              (route) => false,
        );
      }
    } catch (e) {
      // Hata mesajı gösterme
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hesap silinirken hata oluştu: $e')),
      );
    }
  }
}
