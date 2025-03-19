import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:scooter/models/promotionCodeModel.dart';
import 'package:scooter/provider/user_provider.dart';

class PromosionsPage extends StatefulWidget {
  const PromosionsPage({Key? key}) : super(key: key);

  @override
  _PromotionsPageState createState() => _PromotionsPageState();
}

class _PromotionsPageState extends State<PromosionsPage> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final userEmail = context.read<UserProvider>().userData!['email'];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: SafeArea(
          child: Column(
            children: [
              // Professional Header
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Title Section
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 12),
                          const Text(
                            'Promosyonlarım',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    // Divider
                    Container(
                      height: 1,
                      color: Colors.grey[100],
                    ),
                    // Promo Input Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
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
                                  Icons.local_offer,
                                  color: Color(0xFF416FDF),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Promosyon Kodu',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'İndirim kodunuzu girin',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _codeController,
                            decoration: InputDecoration(
                              hintText: 'Promosyon kodunu girin',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: _isLoading
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                                  : IconButton(
                                icon: const Icon(Icons.arrow_forward),
                                color: const Color(0xFF416FDF),
                                onPressed: () => _addPromotionCode(userEmail),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tab Bar
                    TabBar(
                      labelColor: const Color(0xFF416FDF),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: const Color(0xFF416FDF),
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: 'Aktif'),
                        Tab(text: 'Kullanılmış'),
                      ],
                    ),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: TabBarView(
                  children: [
                    _buildPromotionList(userEmail, false),
                    _buildPromotionList(userEmail, true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  Widget _buildPromotionList(String userEmail, bool isUsed) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('promotion_codes')
          .where('userEmail', isEqualTo: userEmail)
          .where('isUsed', isEqualTo: isUsed)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final promotions = snapshot.data!.docs
            .map((doc) => PromosionCode.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        }))
            .where((promo) => !isUsed ? promo.isValid() : true)
            .toList();

        if (promotions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isUsed
                      ? 'Kullanılmış promosyon kodunuz bulunmuyor'
                      : 'Aktif promosyon kodunuz bulunmuyor',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: promotions.length,
          itemBuilder: (context, index) {
            final promo = promotions[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isUsed
                                ? Colors.grey[200]
                                : Colors.yellow.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            promo.code,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isUsed ? Colors.grey : Colors.black,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${promo.discountAmount.toStringAsFixed(2)} TL',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isUsed ? Colors.grey : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      promo.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isUsed && promo.usedAt != null)
                      Text(
                        'Kullanım tarihi: ${_formatDate(promo.usedAt!)}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      )
                    else
                      Text(
                        'Son kullanım: ${_formatDate(promo.expiryDate)}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addPromotionCode(String userEmail) async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Kullanıcının bu kodu daha önce alıp almadığını kontrol et
      final existingUserPromos = await FirebaseFirestore.instance
          .collection('promotion_codes')
          .where('code', isEqualTo: code)
          .where('userEmail', isEqualTo: userEmail)
          .get();

      if (existingUserPromos.docs.isNotEmpty) {
        throw 'Bu promosyon kodunu zaten almışsınız';
      }

      // Geçerli promosyon kodunu bul
      final promoQuery = await FirebaseFirestore.instance
          .collection('promotion_codes')
          .where('code', isEqualTo: code)
          .where('userEmail', isNull: true) // Henüz kimseye atanmamış bir kopya bul
          .limit(1)
          .get();

      if (promoQuery.docs.isEmpty) {
        throw 'Geçersiz promosyon kodu veya tüm kodlar tükenmiş';
      }

      final promoDoc = promoQuery.docs.first;
      final promoData = promoDoc.data();

      final expiryDate = DateTime.parse(promoData['expiryDate']);
      if (DateTime.now().isAfter(expiryDate)) {
        throw 'Bu promosyon kodunun süresi dolmuş';
      }

      // Yeni bir kopya oluştur ve kullanıcıya ata
      await FirebaseFirestore.instance.collection('promotion_codes').add({
        'code': code,
        'discountAmount': promoData['discountAmount'],
        'expiryDate': promoData['expiryDate'],
        'description': promoData['description'],
        'isUsed': false,
        'userEmail': userEmail,
        'assignedAt': DateTime.now().toIso8601String(),
      });

      _codeController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${promoData['discountAmount']} TL değerinde promosyon kodu başarıyla eklendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}