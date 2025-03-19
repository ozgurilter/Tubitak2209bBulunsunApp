import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:scooter/afterLogin/processes/paymentMethods.dart';
import 'package:scooter/afterLogin/processes/promotionView.dart';
import 'package:scooter/models/cardModel.dart';
import 'package:scooter/models/promotionCodeModel.dart';
import 'package:scooter/provider/user_provider.dart';

class PaymentSelectionDialog extends StatefulWidget {
  final List<CardModel> cards;
  final Function(CardModel, PromosionCode?) onCardSelected;

  const PaymentSelectionDialog({
    Key? key,
    required this.cards,
    required this.onCardSelected,
  }) : super(key: key);

  @override
  _PaymentSelectionDialogState createState() => _PaymentSelectionDialogState();
}

class _PaymentSelectionDialogState extends State<PaymentSelectionDialog> {
  PromosionCode? selectedPromotion;

  @override
  Widget build(BuildContext context) {
    final userEmail = context.read<UserProvider>().userData!['email'];

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ödeme Yöntemi',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Kullanmak istediğiniz kartı seçin',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Cards List
              if (widget.cards.isEmpty)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.credit_card_off_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Kayıtlı kart bulunamadı',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...widget.cards.map((card) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => widget.onCardSelected(card, selectedPromotion),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF416FDF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.credit_card,
                              color: Color(0xFF416FDF),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '****${card.cardNumber.substring(card.cardNumber.length - 4)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${card.balance.toStringAsFixed(2)} TL',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                )),

              // Promotion Code Section
              const SizedBox(height: 24),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('promotion_codes')  // promotion_codes koleksiyonunu kullan
                    .where('userEmail', isEqualTo: userEmail)  // Kullanıcıya atanmış kodları getir
                    .where('isUsed', isEqualTo: false)  // Kullanılmamış kodları getir
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final promotions = snapshot.data!.docs
                      .map((doc) => PromosionCode.fromJson({
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                  }))
                      .where((promo) => promo.isValid())
                      .toList();

                  if (promotions.isEmpty) {
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_offer_outlined,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Aktif promosyon kodunuz bulunmuyor',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PromosionsPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Promosyon Kodu Ekle'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF416FDF),
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      ...promotions.map((promo) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selectedPromotion?.id == promo.id
                                ? Colors.yellow
                                : Colors.grey[200]!,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              selectedPromotion =
                              selectedPromotion?.id == promo.id ? null : promo;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.local_offer,
                                  color: selectedPromotion?.id == promo.id
                                      ? Colors.yellow
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        promo.code,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        promo.description,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${promo.discountAmount.toStringAsFixed(2)} TL',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PromosionsPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Başka Kod Ekle'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF416FDF),
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Add New Card Button
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Close dialog first
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentMethodsPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Yeni Kart Ekle'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF416FDF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}