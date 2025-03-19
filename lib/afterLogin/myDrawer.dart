
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scooter/Auth/loginPage.dart';
import 'package:scooter/afterLogin/processes/paymentMethods.dart';
import 'package:scooter/afterLogin/processes/promotionView.dart';
import 'package:scooter/afterLogin/processes/rideHistory.dart';
import 'package:scooter/afterLogin/processes/userSettings.dart';
import 'package:scooter/afterLogin/processes/viewDrivingGuide.dart';
import 'package:scooter/afterLogin/scooterMap.dart';
import 'package:scooter/provider/user_provider.dart';

class MyDrawer extends StatelessWidget {
  final Function(Widget) onPageChange;
  final Widget currentPage;  // Şu an gösterilen sayfayı takip etmek için

  const MyDrawer({
    Key? key,
    required this.onPageChange,
    required this.currentPage,
  }) : super(key: key);

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required Widget page,
  }) {
    final bool isCurrentPage = currentPage.runtimeType == page.runtimeType;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCurrentPage
                ? const Color(0xFF416FDF)
                : const Color(0xFF416FDF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
              isCurrentPage ? Icons.map : icon,
              color: isCurrentPage ? Colors.white : const Color(0xFF416FDF)
          ),
        ),
        title: Text(
          isCurrentPage ? 'Haritayı Görüntüle' : title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isCurrentPage ? const Color(0xFF416FDF) : Colors.black,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: () {
          if (isCurrentPage) {
            onPageChange( ScooterMap());
          } else {
            onPageChange(page);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return Drawer(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Profil Bölümü (aynı)
                  Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 20,
                      bottom: 20,
                      left: 20,
                      right: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF416FDF),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 35,
                            backgroundColor: const Color(0xFF416FDF).withOpacity(0.2),
                            child: Text(
                              (userProvider.userData!['nameSurname'] ?? '')[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF416FDF),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          userProvider.userData!['nameSurname'] ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userProvider.userData!['email'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menu Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      children: [
                        _buildDrawerItem(
                          icon: Icons.payment_rounded,
                          title: 'Ödeme Yöntemleri',
                          page: const PaymentMethodsPage(),
                        ),
                        _buildDrawerItem(
                          icon: Icons.history_rounded,
                          title: 'Sürüş Geçmişi',
                          page: const RideHistoryPage(),
                        ),
                        _buildDrawerItem(
                          icon: Icons.card_giftcard_rounded,
                          title: 'Promosyon Kodları',
                          page: const PromosionsPage(),
                        ),
                        _buildDrawerItem(
                          icon: Icons.settings_rounded,
                          title: 'Ayarlar',
                          page: UserSettings(),
                        ),
                        _buildDrawerItem(
                          icon: Icons.help_outline_rounded,
                          title: 'Sürüş Kılavuzu',
                          page: const ViewDrivingGuide(),
                        ),
                      ],
                    ),
                  ),

                  // Çıkış Butonu (aynı)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Çıkış Yap'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        foregroundColor: Colors.red,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}