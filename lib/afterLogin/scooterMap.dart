import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:scooter/afterLogin/processes/paymentMethods.dart';
import 'package:scooter/afterLogin/processes/subPages/paymentSelectionDialog.dart';
import 'package:scooter/afterLogin/processes/subPages/readQR.dart';
import 'package:scooter/models/cardModel.dart';
import 'package:scooter/models/promotionCodeModel.dart';
import 'package:scooter/models/scooterModel.dart';
import 'package:scooter/provider/user_provider.dart';
import 'package:scooter/widget/secretKeys.dart';

class ScooterMap extends StatefulWidget {
  const ScooterMap({Key? key}) : super(key: key);
  @override
  _ScooterMapState createState() => _ScooterMapState();
}

class _ScooterMapState extends State<ScooterMap> {
  GoogleMapController? mapController;
  Location location = Location();
  LatLng? currentLocation;
  Set<Marker> markers = {};
  Set<Polyline> _polylines = {};
  List<Scooter> scooters = [];
  Timer? _rentalTimer;
  int _elapsedSeconds = 0;
  Scooter? _rentedScooter;
  double _totalCost = 0.0;
  Scooter? _selectedScooter;
  int _rentDuration = 0;
  CardModel? _selectedCard;
  PromosionCode? selectedPromosion;
  Map<String, List<Scooter>> _clusters = {};

  double _normalMarkerSize = 120;
  double _selectedMarkerSize = 120;
  double _selectedAnimationScale = 1.3;
  static const double CLUSTER_DISTANCE = 30.0;

  // scooter dinleme yapma
  late StreamController<List<Scooter>> _scooterStreamController;
  Timer? _scooterUpdateTimer;
  Timer? _debounceTimer;


  @override
  void initState() {
    super.initState();
    _initializeScooterStream();
    _initializeMap();
  }

  void _initializeScooterStream() {
    _scooterStreamController = StreamController<List<Scooter>>();
    _scooterStreamController.stream.listen((updatedScooters) {
      if (mounted) {
        setState(() {
          scooters = updatedScooters;
          _createClusters();
        });
      }
    });
  }

  void _startScooterUpdates() {
    // İlk yükleme
    _fetchAndUpdateScooters();

    // Periyodik kontrol (30 saniyede bir)
    _scooterUpdateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchAndUpdateScooters();
    });
  }

  Future<void> _fetchAndUpdateScooters() async {
    try {
      final response = await http.get(
        Uri.parse(Secrets.baseUrl),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final scooterData = json.decode(response.body);
        final updatedScooters = scooterData
            .map<Scooter>((data) => Scooter.fromJson(data))
            .toList();

        _scooterStreamController.add(updatedScooters);
      }
    } catch (e) {
      print('Scooter güncelleme hatası: $e');
    }
  }


  @override
  void didUpdateWidget(ScooterMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh markers when widget is updated
    if (mounted) {
      _updateScooterMarkers();
      _createClusters();
    }
  }

  @override
  void dispose() {
    _scooterUpdateTimer?.cancel();
    _scooterStreamController.close();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      await _getCurrentLocation();
      //await _loadScooters();
      _setupLocationListener();
      _startScooterUpdates();
    } catch (e) {
      print('Initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Harita yüklenirken bir hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rentScooter(Scooter scooter) async {
    // Zaten kiralanan bir scooter varsa engelle
    if (_rentedScooter != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zaten kiralanmış bir scooter\'ınız var.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!scooter.isEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu scooter şu anda kullanımda.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Kullanıcının kartlarını al
      final userEmail = context.read<UserProvider>().userData!['email'];
      final cardsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .collection('cards')
          .get();

      final cards = cardsSnapshot.docs
          .map((doc) => CardModel.fromJson(doc.data()))
          .toList();

      if (cards.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Kayıtlı ödeme yöntemi bulunamadı.'),
            action: SnackBarAction(
              label: 'Kart Ekle',
              onPressed: () => showPaymentMethodsPage(context),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Ödeme seçme dialogunu göster
      if (!mounted) return;

      CardModel? selectedCard;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return PaymentSelectionDialog(
            cards: cards,
            onCardSelected: (card, promosion) {
              selectedCard = card;
              selectedPromosion = promosion; // Seçilen promosyonu kaydet
              Navigator.pop(context);
            },
          );
        },
      );

      if (selectedCard == null) return; // Kullanıcı seçim yapmadan çıktı

      // QR Tarama sayfasını aç
      if (!mounted) return;

      bool qrVerified = false;
      String? qrCode;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QRScannerPage(
            scooter: scooter,
            onQRMatch: (String code) {
              qrVerified = true;
              qrCode = code;
              Navigator.pop(context);
            },
          ),
        ),
      );

      if (!qrVerified || qrCode == null) return; // QR tarama başarısız veya iptal edildi

      // Kiralama işlemini başlat

      await _processRental(scooter, selectedCard!);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bir hata oluştu: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void showPaymentMethodsPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WillPopScope(
          onWillPop: () async {
            Navigator.of(context).pop();
            return false;
          },
          child: Scaffold(
            body: Stack(
              children: [
                const PaymentMethodsPage(),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _processRental(Scooter scooter, CardModel selectedCard) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // Scooter durumunu güncelle
      final response = await http.put(
        Uri.parse('${Secrets.baseUrl}/${scooter.id}/status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'isEnabled': false}),
      );

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        // Güncel scooter bilgisini al
        final scooterResponse = await http.get(
          Uri.parse('${Secrets.baseUrl}/${scooter.id}'),
          headers: {
            'Accept': 'application/json',
          },
        );

        Navigator.pop(context); // Yükleniyor dialogunu kapat

        if (scooterResponse.statusCode == 200) {
          final updatedScooter = Scooter.fromJson(json.decode(scooterResponse.body));

          setState(() {
            int index = scooters.indexWhere((s) => s.id == scooter.id);
            if (index != -1) {
              scooters[index] = updatedScooter;
              _rentedScooter = scooters[index];
              _selectedCard = selectedCard;
              _startRentalTimer();
              _updateScooterMarkers();
            }
          });

          // Kiralama başlangıç kaydı
          final userEmail = context.read<UserProvider>().userData!['email'];
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userEmail)
              .collection('rides')
              .add({
            'scooterId': scooter.id,
            'scooterBrand': scooter.brand,
            'startLocation': {
              'latitude': scooter.latitude,
              'longitude': scooter.longitude,
            },
            'startTime': DateTime.now().toIso8601String(),
            'status': 'active',
            'batteryLevel': scooter.batteryLevel,
            'paymentMethod': {
              'cardId': selectedCard.id,
              'lastFourDigits': selectedCard.cardNumber.substring(selectedCard.cardNumber.length - 4),
            },
            'promosionCode': selectedPromosion != null ? selectedPromosion!.code : null, // Promosyon kodunu kaydet
          });


          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scooter başarıyla kiralandı!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bir hata oluştu: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _endRental() async {
    if (_rentedScooter == null || currentLocation == null || _selectedCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kiralama bilgilerine ulaşılamadı.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Sayacı durdur
    _rentalTimer?.cancel();

    // QR doğrulama için scanner'ı aç
    bool qrVerified = false;
    String? qrCode;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerPage(
          scooter: _rentedScooter!,
          isEndRide: true,
          onQRMatch: (String code) {
            qrVerified = true;
            qrCode = code;
            Navigator.pop(context);
          },
        ),
      ),
    );

    if (!qrVerified || qrCode == null) {
      // QR tarama iptal edildi, sayacı tekrar başlat
      _restartRentalTimer();
      return;
    }

    _rentDuration = _elapsedSeconds;
    final lastScooterLocation = LatLng(currentLocation!.latitude, currentLocation!.longitude);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // Toplam ücreti hesapla
      double totalCost = (_elapsedSeconds / 60) * _rentedScooter!.price;

// Promosyon indirimi uygula
      if (selectedPromosion != null) {
        totalCost -= selectedPromosion!.discountAmount;
        if (totalCost < 0) totalCost = 0; // Negatif ücreti önle

        // Promosyon kodunu kullanılmış olarak işaretle
        await FirebaseFirestore.instance
            .collection('promosion_codes')
            .doc(selectedPromosion!.id)
            .update({
          'isUsed': true,
          'usedAt': DateTime.now().toIso8601String(),
        });
      }


      // Kullanıcı bilgilerini al
      final userEmail = context.read<UserProvider>().userData?['email'];

      // Kartın mevcut bakiyesini al
      final cardDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .collection('cards')
          .doc(_selectedCard!.id)
          .get();

      final currentBalance = cardDoc.data()?['balance'] ?? 0.0;

      // Karttan ücreti düş (bakiye kontrolü olmadan)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .collection('cards')
          .doc(_selectedCard!.id)
          .update({
        'balance': currentBalance - totalCost,
      });

      // Harcama kaydı ekle
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .collection('cards')
          .doc(_selectedCard!.id)
          .collection('transactions')
          .add({
        'amount': totalCost,
        'type': 'expense',
        'description': 'Scooter kiralama (${_rentedScooter!.brand})',
        'date': Timestamp.now(),
        'scooterId': _rentedScooter!.id,
        'duration': _rentDuration,
        'promosionApplied': selectedPromosion != null ? selectedPromosion!.code : null, // Promosyon kodu eklendi
      });

      // Sürüş kaydını güncelle
      final ridesQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .collection('rides')
          .where('scooterId', isEqualTo: _rentedScooter!.id)
          .where('status', isEqualTo: 'active')
          .get();

      if (ridesQuery.docs.isNotEmpty) {
        await ridesQuery.docs.first.reference.update({
          'endLocation': {
            'latitude': lastScooterLocation.latitude,
            'longitude': lastScooterLocation.longitude,
          },
          'endTime': DateTime.now().toIso8601String(),
          'duration': _rentDuration,
          'cost': totalCost,
          'status': 'completed',
        });
      }

      // Scooter'ın konumunu güncelle
      await http.put(
        Uri.parse('${Secrets.baseUrl}/${_rentedScooter!.id}/location'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'latitude': lastScooterLocation.latitude,
          'longitude': lastScooterLocation.longitude,
        }),
      );

      // Scooter'ı serbest bırak
      final response = await http.put(
        Uri.parse('${Secrets.baseUrl}/${_rentedScooter!.id}/status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'isEnabled': true}),
      );

      Navigator.pop(context);

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        setState(() {
          _rentedScooter = null;
          _selectedCard = null;
          _rentalTimer?.cancel();
          _rentalTimer = null;
          _totalCost = totalCost;
          _elapsedSeconds = 0;
          _polylines.clear();
        });

        _showRentalSummary();
        //await _loadScooters();
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kiralama sonlandırılırken hata oluştu: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _restartRentalTimer() {
    _rentalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _showRentalSummary() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.yellow.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.yellow,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Kiralama Sonlandırıldı',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Rental Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _summaryRow(
                      'Toplam Süre',
                      _formatTime(_rentDuration),
                      Icons.timer,
                    ),
                    const Divider(height: 24),
                    _summaryRow(
                      'Toplam Ücret',
                      '${_totalCost.toStringAsFixed(2)} TL',
                      Icons.payment,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'TAMAM',
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
    );
  }

  void _startRentalTimer() {
    _elapsedSeconds = 0;
    _rentalTimer?.cancel();
    _rentalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationData locationData = await location.getLocation();

      LatLng newLocation = LatLng(
        locationData.latitude!,
        locationData.longitude!,
      );

      // State'i güncelle
      setState(() {
        currentLocation = newLocation;
        _updateCurrentLocationMarker();
      });

      // Haritayı konuma taşı
      if (mapController != null) {
        await mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(newLocation, 17),
        );
      }

    } catch (e) {
      print("Error getting location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konum alınamadı. Lütfen konum izinlerini kontrol edin.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _setupLocationListener() {
    location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        this.currentLocation = LatLng(
          currentLocation.latitude!,
          currentLocation.longitude!,
        );
        _updateCurrentLocationMarker();
      });
    });
  }

  void _updateCurrentLocationMarker() {
    if (currentLocation != null) {
      markers.removeWhere((marker) => marker.markerId.value == 'current_location');
      markers.add(
        Marker(
          markerId: MarkerId('current_location'),
          position: currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: 'Konumunuz'),
        ),
      );
    }
  }

  Future<void> _loadScooters() async {
    if ( !mounted) return;

    try {
      print('API isteği yapılıyor: ${Secrets.baseUrl}');

      final response = await http.get(
        Uri.parse(Secrets.baseUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> scooterData = json.decode(response.body);
        if (mounted) {
          setState(() {
            scooters =
                scooterData.map((data) => Scooter.fromJson(data)).toList();
            _updateScooterMarkers();
          });
        }
      } else {
        print('API Hatası: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Veri yüklenirken hata oluştu: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Bir hata oluştu: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bağlantı hatası: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }



  Future<void> _createClusters() async {
    if (mapController == null) return;

    try {
      final enabledScooters = scooters.where((s) => s.isEnabled).toList();
      Map<String, List<Scooter>> newClusters = {};

      for (var i = 0; i < enabledScooters.length; i++) {
        var scooter = enabledScooters[i];
        bool addedToCluster = false;

        // Scooter'ın ekran koordinatlarını hesapla
        final ScreenCoordinate scooterScreenPoint = await mapController!.getScreenCoordinate(
            LatLng(scooter.latitude, scooter.longitude)
        );
        final Point scooterPoint = Point(scooterScreenPoint.x.toDouble(), scooterScreenPoint.y.toDouble());

        // Mevcut kümeleri kontrol et
        for (var clusterId in newClusters.keys) {
          var clusterScooters = newClusters[clusterId]!;
          var firstScooter = clusterScooters.first;

          // Kümenin merkez noktasının ekran koordinatlarını hesapla
          final ScreenCoordinate clusterScreenPoint = await mapController!.getScreenCoordinate(
              LatLng(firstScooter.latitude, firstScooter.longitude)
          );
          final Point clusterPoint = Point(clusterScreenPoint.x.toDouble(), clusterScreenPoint.y.toDouble());

          // İki nokta arasındaki mesafeyi hesapla
          double distance = _calculateDistance(scooterPoint, clusterPoint);

          if (distance <= CLUSTER_DISTANCE) {
            newClusters[clusterId]!.add(scooter);
            addedToCluster = true;
            break;
          }
        }

        if (!addedToCluster) {
          String newClusterId = 'cluster_${newClusters.length}';
          newClusters[newClusterId] = [scooter];
        }
      }

      if (mounted) {
        setState(() {
          _clusters = newClusters;
        });
        await _updateClusteredMarkers();
      }

    } catch (e) {
      print('Cluster oluşturma hatası: $e');
    }
  }

  // Ekran koordinatları arasındaki mesafeyi hesapla
  double _calculateDistance(Point p1, Point p2) {
    return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));
  }

  // Küme ikonu oluştur
  Future<BitmapDescriptor> _createClusterIcon(int count) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(65,65);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 30.0; // Daire boyutunu küçülttük

    // Arka plan gölgesi
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(
      center.translate(0, 2), // Gölgeyi biraz aşağı kaydır
      radius + 2,
      shadowPaint,
    );

    // Ana daire (ana renk)
    final backgroundPaint = Paint()
      ..color = Colors.yellow.shade600 // Daha koyu sarı
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, backgroundPaint);

    // İç daire (daha açık ton)
    final innerCirclePaint = Paint()
      ..color = Colors.yellow.shade400
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 4, innerCirclePaint);

    // Metin boyutu ve stili
    double fontSize = count < 100 ? 16 : 14; // Sayı büyükse font küçülsün
    final textPainter = TextPainter(
      text: TextSpan(
        text: count.toString(),
        style: TextStyle(
          color: Colors.black87,
          fontSize: fontSize,
          fontWeight: FontWeight.w600, // Daha ince font weight
          letterSpacing: -0.5, // Karakterler arası mesafeyi azalt
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(minWidth: 0, maxWidth: size.width);
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final bytes = await image.toByteData(format: ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  void _showClusterContent(List<Scooter> scooters) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bu Konumda ${scooters.length} Scooter',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: scooters.length,
                itemBuilder: (context, index) {
                  final scooter = scooters[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.yellow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.electric_scooter),
                    ),
                    title: Text(
                      scooter.brand,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Batarya: ${scooter.batteryLevel}% • ${scooter.price} TL/dk',
                    ),
                    trailing: Icon(
                      Icons.circle,
                      color: scooter.isEnabled ? Colors.green : Colors.red,
                      size: 12,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedScooter = scooter;
                        _updateClusteredMarkers();
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _updateClusteredMarkers() async {
    if (!mounted || mapController == null) return;

    _normalMarkerSize = await _getMarkerSize(mapController!);
    _selectedMarkerSize = _normalMarkerSize * 1.2;

    Set<Marker> newMarkers = {};

    final currentLocationMarker = markers
        .whereType<Marker>()
        .where((m) => m.markerId.value == 'current_location')
        .firstOrNull;

    if (currentLocationMarker != null) {
      newMarkers.add(currentLocationMarker);
    }

    for (var clusterId in _clusters.keys) {
      var clusterScooters = _clusters[clusterId]!;

      if (clusterScooters.length == 1) {
        var scooter = clusterScooters.first;
        double markerSize = scooter.id == _selectedScooter?.id
            ? _selectedMarkerSize * _selectedAnimationScale
            : _normalMarkerSize;

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final size = Size(markerSize * 2, markerSize * 2);
        final center = Offset(size.width / 2, size.height / 2);

        // Arka plan efektleri
        final bgPath = Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: markerSize * 1.4, height: markerSize * 1.4),
            Radius.circular(markerSize * 0.7),
          ));

        // Dış parıltı
        canvas.drawPath(
          bgPath,
          Paint()
            ..color = Colors.yellow.withOpacity(0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12)
            ..style = PaintingStyle.fill,
        );

        // Gölge
        canvas.drawPath(
          bgPath,
          Paint()
            ..color = Colors.black.withOpacity(0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
            ..style = PaintingStyle.fill,
        );

        // Gradient arkaplan
        final gradient = RadialGradient(
          center: Alignment(0.2, -0.2),
          radius: 1.0,
          colors: [
            Colors.white,
            Colors.yellow.shade50,
            Colors.yellow.shade100,
          ],
          stops: const [0.0, 0.7, 1.0],
        );

        canvas.drawPath(
          bgPath,
          Paint()
            ..shader = gradient.createShader(bgPath.getBounds())
            ..style = PaintingStyle.fill,
        );

        // Parlaklık efekti
        final highlightPaint = Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

        canvas.drawCircle(
          center.translate(-markerSize * 0.2, -markerSize * 0.2),
          markerSize * 0.2,
          highlightPaint,
        );

        // Scooter ikonu
        final imageConfiguration = ImageConfiguration(size: Size(markerSize, markerSize));

        AssetImage imageProvider;

        if(scooter.brand == 'Martı'){
          imageProvider = AssetImage('image/marti_icon.png');
        } else {
          imageProvider = AssetImage('image/binbin_icon.jpg');
        }

        final imageStream = imageProvider.resolve(imageConfiguration);
        final completer = Completer<void>();

        late ImageInfo imageInfo;
        imageStream.addListener(ImageStreamListener(
              (info, _) {
            imageInfo = info;
            completer.complete();
          },
          onError: completer.completeError,
        ));

        await completer.future;

        // İkon boyutunu ve pozisyonunu ayarla
        final iconSize = markerSize * 0.8;
        final iconRect = Rect.fromCenter(
          center: center,
          width: iconSize,
          height: iconSize,
        );

        canvas.drawImageRect(
          imageInfo.image,
          Rect.fromLTWH(0, 0, imageInfo.image.width.toDouble(), imageInfo.image.height.toDouble()),
          iconRect,
          Paint(),
        );

        // İnce kenar çizgisi
        canvas.drawPath(
          bgPath,
          Paint()
            ..color = Colors.yellow.shade200
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );

        final picture = recorder.endRecording();
        final image = await picture.toImage(size.width.toInt(), size.height.toInt());
        final bytes = await image.toByteData(format: ImageByteFormat.png);
        final customIcon = BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());

        newMarkers.add(
          Marker(
            markerId: MarkerId('scooter_${scooter.id}'),
            position: LatLng(scooter.latitude, scooter.longitude),
            icon: customIcon,
            anchor: const Offset(0.5, 0.5),
            onTap: () => setState(() {
              _selectedScooter = scooter;
              _updateClusteredMarkers();
            }),
          ),
        );
      } else {
        final avgLat = clusterScooters.map((s) => s.latitude).reduce((a, b) => a + b) / clusterScooters.length;
        final avgLng = clusterScooters.map((s) => s.longitude).reduce((a, b) => a + b) / clusterScooters.length;

        final clusterIcon = await _createClusterIcon(clusterScooters.length);
        newMarkers.add(
          Marker(
            markerId: MarkerId(clusterId),
            position: LatLng(avgLat, avgLng),
            icon: clusterIcon,
            anchor: const Offset(0.5, 0.5),
            onTap: () => _showClusterContent(clusterScooters),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => markers = newMarkers);
    }
  }


  void _onCameraMove(CameraPosition position) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: 150),
      _createClusters,
    );
  }

  void _onCameraIdle() {
    _createClusters();
  }

  void _updateScooterMarkers() {
    _createClusters();
  }

  Future<double> _getMarkerSize(GoogleMapController controller) async {
    final double zoom = await controller.getZoomLevel();
    if (zoom <= 12) return 36;
    if (zoom <= 14) return 42;
    if (zoom <= 16) return 48;
    return 54;
  }




  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            // Map base layer
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: currentLocation ?? const LatLng(38.6191, 27.4289),
                zoom: 17,

              ),
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              markers: markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false, // Disabled because we'll add custom button
              mapType: MapType.normal,
              zoomControlsEnabled: false,
              compassEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
                _createClusters();
              },
              onTap: (LatLng position) {
                // When tapping on empty area, deselect the scooter
                setState(() {
                  _selectedScooter = null;
                  _updateScooterMarkers();
                });
              },
            ),

            if (_rentedScooter != null)
              Positioned(
                top: 16,
                left: 80,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Scooter Info Row
                      Row(
                        children: [
                          // Scooter Icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.yellow.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.electric_scooter,
                              color: Colors.black,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Scooter Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _rentedScooter!.brand,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Batarya: ${_rentedScooter!.batteryLevel}%',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Timer Display
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer,
                                  size: 18,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatTime(_elapsedSeconds),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Cost Info Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.payment,
                                  size: 20,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Toplam Ücret:',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${(_elapsedSeconds / 60 * _rentedScooter!.price).toStringAsFixed(2)} TL',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // End Rental Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('KİRALAMAYI SONLANDIR'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _endRental,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Map Control Buttons (Right side)
            Positioned(
              right: 16,
              bottom: 100,
              child: Column(
                children: [
                  // Zoom In Button
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        mapController?.animateCamera(CameraUpdate.zoomIn());
                      },
                    ),
                  ),
                  // Zoom Out Button
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        mapController?.animateCamera(CameraUpdate.zoomOut());
                      },
                    ),
                  ),
                  // Location Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.my_location),
                      onPressed: () => _getCurrentLocation(),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Action Buttons
            if (_selectedScooter != null)
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    // Info Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () => _showDetailedInfo(_selectedScooter!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Scan to Ride Button
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: _rentedScooter == null ? Colors.yellow : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _rentedScooter == null ? () => _rentScooter(_selectedScooter!) : null,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.qr_code_scanner, color: Colors.black),
                                  SizedBox(width: 8),
                                  Text(
                                    'SCAN TO RIDE',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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

  void _showDetailedInfo(Scooter scooter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              scooter.brand,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _infoRow(Icons.battery_charging_full, 'Batarya', '${scooter.batteryLevel}%'),
            _infoRow(Icons.attach_money, 'Fiyat', '${scooter.price}/dk'),
            _infoRow(
              Icons.circle,
              'Durum',
              scooter.isEnabled ? 'Müsait' : 'Meşgul',
              color: scooter.isEnabled ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _rentedScooter == null ? Colors.yellow : Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: (scooter.isEnabled && _rentedScooter == null) ? () => _rentScooter(scooter) : null,
                child: Text(
                  'SCAN TO RIDE',
                  style: TextStyle(
                    color: (scooter.isEnabled && _rentedScooter == null) ? Colors.black : Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _infoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.black54),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }}

Widget _summaryRow(String label, String value, IconData icon) {
  return Row(
    children: [
      Icon(
        icon,
        size: 24,
        color: Colors.black54,
      ),
      const SizedBox(width: 12),
      Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black54,
        ),
      ),
      const Spacer(),
      Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}