class Scooter {
  final int id;
  final String brand;
  final double price;
  final int batteryLevel;
  final double latitude;
  final double longitude;
  final bool isEnabled;




  Scooter({
    required this.id,
    required this.brand,
    required this.latitude,
    required this.longitude,
    required this.batteryLevel,
    required this.price,
    required this.isEnabled
  });

  factory Scooter.fromJson(Map<String, dynamic> json) {
    return Scooter(
      id: json['id'] ?? 0,
      latitude: (json['latitude'] is num) ? json['latitude'].toDouble() : 0.0,
      longitude: (json['longitude'] is num) ? json['longitude'].toDouble() : 0.0,
      batteryLevel: json['battery_level'] ?? 0,
      price: (json['price'] is num) ? json['price'].toDouble() : 0.0,
      isEnabled: json['isEnabled'] ?? false,
      brand: json['brand'] ?? '',
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand': brand,
      'latitude': latitude,
      'longitude': longitude,
      'battery_level': batteryLevel,
      'price': price,
      'isEnabled': isEnabled,
    };
  }

}


