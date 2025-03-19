
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;

  void setUserData(Map<String, dynamic> data) {
    _userData = data;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> fetchUserData(String email) async {
    setLoading(true);
    try {
      final QuerySnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userDoc.docs.isNotEmpty) {
        setUserData(userDoc.docs.first.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error fetching user data: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> reauthenticateUser(String currentEmail, String currentPassword) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User is not signed in.");

      final credential = EmailAuthProvider.credential(email: currentEmail, password: currentPassword);
      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      print("Re-authentication failed: $e");
      throw Exception("Re-authentication failed: $e");
    }
  }
  Future<void> updateUserInfo({
    String? nameSurname,
    String? password,
    required String currentEmail,
    String? currentPassword,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("No user logged in.");
    }

    try {
      // Sadece şifre değişikliği varsa reauthentication yap
      if (password != null && password.isNotEmpty) {
        if (currentPassword == null || currentPassword.isEmpty) {
          throw Exception("Current password is required for password change.");
        }
        await reauthenticateUser(currentEmail, currentPassword);
        await user.updatePassword(password);
      }

      // Firestore'da ad soyad güncelleme
      if (nameSurname != null && nameSurname.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentEmail)
            .update({'nameSurname': nameSurname});
      }

      // Kullanıcı bilgilerini güncelledikten sonra tekrar çek
      await fetchUserData(currentEmail);
    } catch (e) {
      print('Failed to update user info: $e');
      throw Exception('Failed to update user info: $e');
    }
  }
}

