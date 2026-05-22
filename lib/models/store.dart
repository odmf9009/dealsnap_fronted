class Store {
  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String? websiteUrl;
  final bool isActive;

  const Store({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.websiteUrl,
    this.isActive = true,
  });

  factory Store.fromJson(Map<String, dynamic> json) => Store(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        name: json['name'] ?? '',
        slug: json['slug'] ?? '',
        logoUrl: json['logoUrl'] as String?,
        websiteUrl: json['websiteUrl'] as String?,
        isActive: json['isActive'] ?? true,
      );

  @override
  bool operator ==(Object other) => other is Store && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Info del store embebida en un producto (subset de Store)
class StoreInfo {
  final String id;
  final String name;
  final String slug;

  const StoreInfo({required this.id, required this.name, required this.slug});

  factory StoreInfo.fromJson(Map<String, dynamic> json) => StoreInfo(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        name: json['name'] ?? '',
        slug: json['slug'] ?? '',
      );
}
