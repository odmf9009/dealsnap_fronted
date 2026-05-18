class AlertModel {
  final String id;
  final String type; // 'product' | 'brand'
  final String? productAsin;
  final String? productTitle;
  final String? brandName;
  final double? discountThreshold;
  final double? priceTarget;
  final bool notifyExpiry;
  final List<String> channels;
  final bool active;
  final DateTime? lastTriggered;

  const AlertModel({
    required this.id,
    required this.type,
    this.productAsin,
    this.productTitle,
    this.brandName,
    this.discountThreshold,
    this.priceTarget,
    this.notifyExpiry = false,
    this.channels = const ['email'],
    this.active = true,
    this.lastTriggered,
  });

  factory AlertModel.fromJson(Map<String, dynamic> j) => AlertModel(
        id:                j['_id'] ?? j['id'] ?? '',
        type:              j['type'] ?? 'product',
        productAsin:       j['productAsin'],
        productTitle:      j['productTitle'],
        brandName:         j['brandName'],
        discountThreshold: (j['discountThreshold'] as num?)?.toDouble(),
        priceTarget:       (j['priceTarget'] as num?)?.toDouble(),
        notifyExpiry:      j['notifyExpiry'] ?? false,
        channels:          List<String>.from(j['channels'] ?? ['email']),
        active:            j['active'] ?? true,
        lastTriggered:     j['lastTriggered'] != null
            ? DateTime.tryParse(j['lastTriggered'])
            : null,
      );

  String get displayName {
    if (type == 'brand') return brandName ?? 'Brand alert';
    return productTitle ?? productAsin ?? 'Product alert';
  }

  String get conditionText {
    final parts = <String>[];
    if (discountThreshold != null) parts.add('≥ ${discountThreshold!.toInt()}% off');
    if (priceTarget != null) parts.add('≤ \$${priceTarget!.toStringAsFixed(2)}');
    if (notifyExpiry) parts.add('expiry < 24h');
    return parts.isEmpty ? 'Any deal' : parts.join(' · ');
  }
}
