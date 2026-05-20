class PromoInfo {
  final String id;
  final List<String> promoCodes;
  final String title;
  final String? expiresAt;
  final String? startsAt;

  const PromoInfo({
    required this.id,
    required this.promoCodes,
    required this.title,
    this.expiresAt,
    this.startsAt,
  });

  factory PromoInfo.fromJson(Map<String, dynamic> json) => PromoInfo(
        id: json['_id'] ?? '',
        promoCodes: List<String>.from(json['promoCodes'] ?? []),
        title: json['title'] ?? '',
        expiresAt: json['expiresAt'],
        startsAt: json['startsAt'],
      );

  String? get firstCode => promoCodes.isNotEmpty ? promoCodes.first : null;
}

class Product {
  final String id;
  final String asin;
  final String title;
  final String? image;
  final double currentPrice;
  final double originalPrice;
  final int discountPercentage;
  final String category;
  final String url;
  final PromoInfo? promo;
  final bool isBestDeal;
  final double? dealScore;
  final String? source;
  final bool isGroup;
  final int groupCount;
  final String? groupKey;
  final bool favorite;

  const Product({
    required this.id,
    required this.asin,
    required this.title,
    this.image,
    required this.currentPrice,
    required this.originalPrice,
    required this.discountPercentage,
    required this.category,
    required this.url,
    this.promo,
    this.isBestDeal = false,
    this.dealScore,
    this.source,
    this.isGroup = false,
    this.groupCount = 1,
    this.groupKey,
    this.favorite = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '',
      asin: json['asin'] ?? '',
      title: json['title'] ?? '',
      image: json['image'],
      currentPrice: (json['currentPrice'] ?? 0).toDouble(),
      originalPrice: (json['originalPrice'] ?? 0).toDouble(),
      discountPercentage: (json['discountPercentage'] ?? 0).toInt(),
      category: json['category'] ?? '',
      url: json['url'] ?? '',
      promo: (json['promo'] is Map<String, dynamic>) ? PromoInfo.fromJson(json['promo'] as Map<String, dynamic>) : null,
      isBestDeal: json['isBestDeal'] ?? false,
      dealScore: json['dealScore']?.toDouble(),
      source: json['source'],
      isGroup: json['isGroup'] ?? false,
      groupCount: (json['groupCount'] ?? 1).toInt(),
      groupKey: json['groupKey'] as String?,
      favorite: (json['favorite'] as bool?) ?? false,
    );
  }

  bool get hasPromoCode => promo?.firstCode != null;
  String? get promoCode => promo?.firstCode;
}
