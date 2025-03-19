
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scooter/Auth/loginPage.dart';
import 'package:scooter/provider/user_provider.dart';

class UserSettings extends StatefulWidget {
  @override
  State<UserSettings> createState() => _UserSettingsState();
}

class _UserSettingsState extends State<UserSettings> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isEditingName = false;
  bool _isEditingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final email = context.read<UserProvider>().userData?['email'];
    if (email != null) {
      await context.read<UserProvider>().fetchUserData(email);
      if (mounted) {
        setState(() {
          _nameController.text = context.read<UserProvider>().userData?['nameSurname'] ?? '';
        });
      }
    }
  }

  Future<void> _updateUserInfo() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final email = context.read<UserProvider>().userData?['email'];
      if (email == null) throw Exception('Kullanıcı email bilgisi bulunamadı');

      if (_isEditingPassword && _currentPasswordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Şifre değişikliği için mevcut şifre gereklidir.')),
        );
        return;
      }

      await context.read<UserProvider>().updateUserInfo(
        nameSurname: _isEditingName ? _nameController.text : null,
        password: _isEditingPassword ? _passwordController.text : null,
        currentEmail: email,
        currentPassword:
        _isEditingPassword ? _currentPasswordController.text : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil başarıyla güncellendi')),
        );
      }

      setState(() {
        _isEditingName = false;
        _isEditingPassword = false;
        _currentPasswordController.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
              Text('Profil güncellenirken hata oluştu: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modern Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.delete_forever,
                        color: Colors.red[700], size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Hesabı Sil',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red[50]!, Colors.red[100]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red[100]!.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: Colors.red[700], size: 28),
                                const SizedBox(width: 12),
                                Text(
                                  'ÖNEMLİ UYARI',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Hesabınızı silmek geri alınamaz bir işlemdir. Tüm verileriniz kalıcı olarak silinecektir:',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildWarningItem('Profil bilgileriniz'),
                            _buildWarningItem('Ödeme yöntemleriniz'),
                            _buildWarningItem('Geçmiş sürüşleriniz'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Hesap Doğrulama',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Devam etmek için hesap bilgilerinizi girin',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildDeleteTextField(
                        controller: emailController,
                        label: 'E-posta Adresi',
                        icon: Icons.email_outlined,
                        validator: (value) {
                          final currentEmail =
                          context.read<UserProvider>().userData?['email'];
                          if (value != currentEmail) {
                            return 'Lütfen e-posta adresinizi doğru girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDeleteTextField(
                        controller: passwordController,
                        label: 'Şifre',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Şifre gereklidir';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      minimumSize: const Size(double.infinity, 56),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            // Kullanıcıyı yeniden doğrula
                            final credential = EmailAuthProvider.credential(
                              email: emailController.text,
                              password: passwordController.text,
                            );

                            await user.reauthenticateWithCredential(credential);

                            // Batch işlemi başlat
                            final batch = FirebaseFirestore.instance.batch();

                            // Kartları ve işlemleri sil
                            final cardsSnapshot = await FirebaseFirestore
                                .instance
                                .collection('users')
                                .doc(emailController.text)
                                .collection('cards')
                                .get();

                            for (var cardDoc in cardsSnapshot.docs) {
                              // Kartın transaction'larını sil
                              final transactionsSnapshot =
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(emailController.text)
                                  .collection('cards')
                                  .doc(cardDoc.id)
                                  .collection('transactions')
                                  .get();

                              for (var transactionDoc
                              in transactionsSnapshot.docs) {
                                batch.delete(transactionDoc.reference);
                              }

                              // Kartı sil
                              batch.delete(cardDoc.reference);
                            }

                            // Kullanıcı dokümanını sil
                            batch.delete(FirebaseFirestore.instance
                                .collection('users')
                                .doc(emailController.text));

                            // Batch işlemini uygula
                            await batch.commit();

                            // Auth hesabını sil
                            await user.delete();

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Hesabınız başarıyla silindi.'),
                                  backgroundColor: Colors.red,
                                ),
                              );

                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LoginPage()),
                                    (route) => false,
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Hata: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_forever, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'HESABI SİL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text(
                      'Vazgeç',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF416FDF),
              ),
            ),
          );
        }

        if (userProvider.userData == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Kullanıcı bulunamadı',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        _nameController.text = userProvider.userData!['nameSurname'] ?? '';

        return SafeArea(
          child: Scaffold(
            backgroundColor: Colors.grey[50],
            body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF416FDF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.settings,
                                  color: Color(0xFF416FDF),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Hesap Ayarları',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Profil bilgilerinizi yönetin',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Section
                          _buildSectionHeader(
                            'Profil Bilgileri',
                            Icons.person,
                            const Color(0xFF416FDF),
                          ),
                          const SizedBox(height: 16),
                          _buildSettingsCard(
                            child: Column(
                              children: [
                                _buildSettingsField(
                                  label: 'Ad Soyad',
                                  value: userProvider.userData!['nameSurname'] ?? '',
                                  icon: Icons.person_outline,
                                  onEdit: () {
                                    setState(() => _isEditingName = !_isEditingName);
                                  },
                                  isEditing: _isEditingName,
                                  controller: _nameController,
                                ),
                                const Divider(height: 1),
                                _buildSettingsField(
                                  label: 'E-posta',
                                  value: userProvider.userData!['email'] ?? '',
                                  icon: Icons.email_outlined,
                                  isEditable: false,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Security Section
                          _buildSectionHeader(
                            'Güvenlik',
                            Icons.shield_outlined,
                            const Color(0xFF416FDF),
                          ),
                          const SizedBox(height: 16),
                          _buildSettingsCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_isEditingPassword) ...[
                                  _buildPasswordField(
                                    label: 'Yeni Şifre',
                                    controller: _passwordController,
                                    validator: (value) {
                                      if (value != null && value.isNotEmpty && value.length < 6) {
                                        return 'Şifre en az 6 karakter olmalıdır';
                                      }
                                      return null;
                                    },
                                  ),
                                  const Divider(height: 1),
                                  _buildPasswordField(
                                    label: 'Mevcut Şifre',
                                    controller: _currentPasswordController,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Mevcut şifre gereklidir';
                                      }
                                      return null;
                                    },
                                  ),
                                ] else
                                  _buildSettingsField(
                                    label: 'Şifre',
                                    value: '••••••••',
                                    icon: Icons.lock_outline,
                                    onEdit: () {
                                      setState(() => _isEditingPassword = !_isEditingPassword);
                                    },
                                    isEditing: _isEditingPassword,
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Danger Zone
                          _buildSectionHeader(
                            'Tehlikeli Bölge',
                            Icons.warning_amber_rounded,
                            Colors.red,
                          ),
                          const SizedBox(height: 16),
                          _buildDangerButton('Hesabı Sil', onPressed: _deleteAccount),

                          // Save Changes Button
                          if (_isEditingName || _isEditingPassword) ...[
                            const SizedBox(height: 32),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF416FDF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                minimumSize: const Size(double.infinity, 56),
                                elevation: 0,
                              ),
                              onPressed: _updateUserInfo,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save_outlined),
                                  SizedBox(width: 8),
                                  Text(
                                    'DEĞİŞİKLİKLERİ KAYDET',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.remove_circle_outline, size: 20, color: Colors.red[700]),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.red[700],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?)? validator,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSettingsField({
    required String label,
    required String value,
    required IconData icon,
    bool isEditable = true,
    bool isEditing = false,
    VoidCallback? onEdit,
    TextEditingController? controller,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF416FDF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF416FDF), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: isEditing
                ? TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 16,
              ),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isEditable)
            IconButton(
              icon: Icon(
                isEditing ? Icons.check : Icons.edit_outlined,
                size: 20,
              ),
              color: isEditing ? const Color(0xFF416FDF) : Colors.grey[600],
              onPressed: onEdit,
              style: IconButton.styleFrom(
                backgroundColor: isEditing
                    ? const Color(0xFF416FDF).withOpacity(0.1)
                    : Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextFormField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF416FDF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_outline,
                color: Color(0xFF416FDF), size: 20),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDangerButton(String label, {required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.delete_forever,
                      color: Colors.red[700], size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bu işlem geri alınamaz',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[300],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.red[700]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }
}

