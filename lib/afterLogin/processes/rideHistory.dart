
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../provider/user_provider.dart';

class RideHistoryPage extends StatefulWidget {
  const RideHistoryPage({Key? key}) : super(key: key);

  @override
  State<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String _selectedFilter = 'all'; // all, week, month, custom

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  Stream<QuerySnapshot> _getFilteredStream(String email) {
    var collection = FirebaseFirestore.instance
        .collection('users')
        .doc(email)
        .collection('rides');

    switch (_selectedFilter) {
      case 'week':
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        return collection
            .where('startTime',
            isGreaterThanOrEqualTo: weekAgo.toIso8601String())
            .orderBy('startTime', descending: true)
            .snapshots();
      case 'month':
        final monthAgo = DateTime.now().subtract(const Duration(days: 30));
        return collection
            .where('startTime',
            isGreaterThanOrEqualTo: monthAgo.toIso8601String())
            .orderBy('startTime', descending: true)
            .snapshots();
      case 'custom':
        if (_selectedStartDate != null && _selectedEndDate != null) {
          return collection
              .orderBy('startTime', descending: true)
              .where('startTime',
              isGreaterThanOrEqualTo: _selectedStartDate!.toIso8601String(),
              isLessThanOrEqualTo: _selectedEndDate!
                  .add(const Duration(days: 1))
                  .toIso8601String())
              .snapshots();
        }
        return collection.orderBy('startTime', descending: true).snapshots();
      default:
        return collection.orderBy('startTime', descending: true).snapshots();
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF416FDF),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
        _selectedFilter = 'custom';
      });
    }
  }

  Widget _buildStatisticsCard(List<QueryDocumentSnapshot> rides) {
    double totalCost = 0;
    int totalDuration = 0;

    for (var ride in rides) {
      final data = ride.data() as Map<String, dynamic>;
      totalCost += (data['cost'] as num).toDouble();
      totalDuration += data['duration'] as int;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF416FDF), Color(0xFF4B7BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF416FDF).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sürüş İstatistikleri',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.electric_scooter,
                  title: 'Toplam Sürüş',
                  value: rides.length.toString(),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.timer,
                  title: 'Toplam Süre',
                  value: _formatDuration(totalDuration),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.payment,
                  title: 'Toplam Tutar',
                  value: '${totalCost.toStringAsFixed(2)} TL',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = context.read<UserProvider>().userData?['email'];

    return Scaffold(
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
                          'Sürüş Geçmişi',
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
                  // Filter Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(
                                label: 'Tümü',
                                isSelected: _selectedFilter == 'all',
                                onSelected: (selected) {
                                  setState(() => _selectedFilter = 'all');
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: 'Son 7 Gün',
                                isSelected: _selectedFilter == 'week',
                                onSelected: (selected) {
                                  setState(() => _selectedFilter = 'week');
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: 'Son 30 Gün',
                                isSelected: _selectedFilter == 'month',
                                onSelected: (selected) {
                                  setState(() => _selectedFilter = 'month');
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: _selectedFilter == 'custom' &&
                                    _selectedStartDate != null
                                    ? '${DateFormat('dd/MM').format(_selectedStartDate!)} - ${DateFormat('dd/MM').format(_selectedEndDate!)}'
                                    : 'Tarih Seç',
                                isSelected: _selectedFilter == 'custom',
                                onSelected: (selected) => _selectDateRange(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              // Content Area
              child: StreamBuilder<QuerySnapshot>(
                stream: _getFilteredStream(email!),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Bir hata oluştu: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Bu tarih aralığında sürüş bulunamadı',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildStatisticsCard(snapshot.data!.docs),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (context, index) {
                            final data = snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                            return _buildRideCard(data);
                          },
                          childCount: snapshot.data!.docs.length,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride) {
    // Promosyon kodu bilgisini kontrol et
    final String promoInfo = ride['promotionCode'] != null
        ? '\nPromosyon: ${ride['promotionCode']}'
        : '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF416FDF).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.electric_scooter,
                  color: Color(0xFF416FDF),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ride['scooterBrand'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF416FDF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.calendar_today,
                        title: 'Tarih',
                        value: _formatDate(ride['startTime']),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.timer,
                        title: 'Süre',
                        value: _formatDuration(ride['duration'] ?? 0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.payment, color: Colors.green),
                          const SizedBox(width: 12),
                          const Text(
                            'Toplam Ücret',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(ride['cost'] ?? 0.0).toStringAsFixed(2)} TL',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      if (ride['promotionCode'] != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.local_offer, color: Colors.orange),
                            const SizedBox(width: 12),
                            Text(
                              'Promosyon: ${ride['promotionCode']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.black54),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildFilterChip({
  required String label,
  required bool isSelected,
  required Function(bool) onSelected,
}) {
  return FilterChip(
    label: Text(
      label,
      style: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[800],
        fontSize: 13,
      ),
    ),
    selected: isSelected,
    onSelected: onSelected,
    selectedColor: const Color(0xFF416FDF),
    backgroundColor: Colors.grey[100],
    checkmarkColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: isSelected ? const Color(0xFF416FDF) : Colors.transparent,
      ),
    ),
  );
}
