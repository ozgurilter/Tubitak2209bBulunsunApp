class PromosionCode {
  final String id;
  final String code;
  final double discountAmount;
  final DateTime expiryDate;
  final String? userEmail; // Kodu aktif olarak kullanan kullanıcı
  final bool isUsed;      // Kod sürüşte kullanıldı mı
  final String description;
  final DateTime? assignedAt;  // Kullanıcıya ne zaman atandı
  final DateTime? usedAt;      // Ne zaman kullanıldı

  PromosionCode({
    required this.id,
    required this.code,
    required this.discountAmount,
    required this.expiryDate,
    this.userEmail,
    required this.isUsed,
    required this.description,
    this.assignedAt,
    this.usedAt,
  });

  factory PromosionCode.fromJson(Map<String, dynamic> json) {
    return PromosionCode(
      id: json['id'],
      code: json['code'],
      discountAmount: json['discountAmount'].toDouble(),
      expiryDate: DateTime.parse(json['expiryDate']),
      userEmail: json['userEmail'],
      isUsed: json['isUsed'] ?? false,
      description: json['description'],
      assignedAt: json['assignedAt'] != null ? DateTime.parse(json['assignedAt']) : null,
      usedAt: json['usedAt'] != null ? DateTime.parse(json['usedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'discountAmount': discountAmount,
      'expiryDate': expiryDate.toIso8601String(),
      'userEmail': userEmail,
      'isUsed': isUsed,
      'description': description,
      'assignedAt': assignedAt?.toIso8601String(),
      'usedAt': usedAt?.toIso8601String(),
    };
  }

  bool isValid() {
    return !isUsed && DateTime.now().isBefore(expiryDate);
  }
}