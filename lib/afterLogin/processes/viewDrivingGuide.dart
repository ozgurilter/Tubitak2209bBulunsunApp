import 'package:flutter/material.dart';

class ViewDrivingGuide extends StatelessWidget {
  const ViewDrivingGuide({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          backgroundColor: Colors.grey[100],
          body: SafeArea(
            child: ListView(
              children: [
                // Custom Header with Back Button
                Container(
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
                    children: [
                      // Title Bar with Back Button
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [

                            const Expanded(
                              child: Text(
                                'Kullanım Kılavuzu',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            // Simetri için boş container
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      // Guide Info Section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF416FDF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.electric_scooter,
                                color: Color(0xFF416FDF),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Scooter Rehberi',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Güvenli sürüş için talimatlar',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSection(
                              title: 'Sürüş Öncesi',
                              icon: Icons.checklist_rounded,
                              children: [
                                _buildGuideItem(
                                  icon: Icons.battery_charging_full,
                                  title: 'Batarya Kontrolü',
                                  description:
                                  'Scooter\'ın batarya seviyesinin yeterli olduğundan emin olun.',
                                ),
                                _buildGuideItem(
                                  icon: Icons.health_and_safety,
                                  title: 'Kask Kullanımı',
                                  description:
                                  'Güvenliğiniz için kask takmanız önerilir.',
                                ),
                                _buildGuideItem(
                                  icon: Icons.engineering,
                                  title: 'Mekanik Kontrol',
                                  description:
                                  'Frenler ve tekerleklerin durumunu kontrol edin.',
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildSection(
                              title: 'Sürüş Kuralları',
                              icon: Icons.rule_rounded,
                              children: [
                                _buildGuideItem(
                                  icon: Icons.speed,
                                  title: 'Hız Limiti',
                                  description:
                                  'Şehir içinde maksimum 25 km/s hızla sürün.',
                                ),
                                _buildGuideItem(
                                  icon: Icons.directions_walk,
                                  title: 'Yaya Önceliği',
                                  description:
                                  'Yaya yollarında yayalara öncelik verin.',
                                ),
                                _buildGuideItem(
                                  icon: Icons.traffic,
                                  title: 'Trafik Kuralları',
                                  description:
                                  'Tüm trafik işaret ve kurallarına uyun.',
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildSection(
                              title: 'Güvenlik İpuçları',
                              icon: Icons.security_rounded,
                              children: [
                                _buildGuideItem(
                                  icon: Icons.signal_cellular_alt,
                                  title: 'Tecrübe Kazanın',
                                  description:
                                  'İlk sürüşlerinizi tenha alanlarda yapın.',
                                ),
                                _buildGuideItem(
                                  icon: Icons.visibility,
                                  title: 'Görünür Olun',
                                  description:
                                  'Gece sürüşlerinde reflektif kıyafetler giyin.',
                                ),
                                _buildGuideItem(
                                  icon: Icons.phone_iphone,
                                  title: 'Dikkat Dağıtmayın',
                                  description:
                                  'Sürüş sırasında telefon kullanmayın.',
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildSection(
                              title: 'Park Etme',
                              icon: Icons.local_parking_rounded,
                              children: [
                                _buildGuideItem(
                                  icon: Icons.location_on,
                                  title: 'Uygun Yer',
                                  description:
                                  'Scooter\'ı yaya trafiğini engellemeyecek şekilde park edin.',
                                ),
                                _buildGuideItem(
                                  icon: Icons.lock,
                                  title: 'Kilitleme',
                                  description:
                                  'Sürüşü sonlandırmadan önce scooter\'ın kilitlendiğinden emin olun.',
                                ),
                                _buildGuideItem(
                                  icon: Icons.photo_camera,
                                  title: 'Fotoğraf Çekin',
                                  description:
                                  'Park sonrası scooter\'ın fotoğrafını çekin.',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF416FDF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF416FDF)),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildGuideItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF416FDF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF416FDF), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
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
      ),
    );
  }
}
