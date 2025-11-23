class ProductItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String? videoUrl;
  final String sellerId;
  final String sellerName;
  final int views;
  final int purchases;
  final bool isPromoted;
  final int boostScore;
  final DateTime createdAt;

  ProductItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    this.videoUrl,
    required this.sellerId,
    required this.sellerName,
    this.views = 0,
    this.purchases = 0,
    this.isPromoted = false,
    this.boostScore = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'views': views,
        'purchases': purchases,
        'isPromoted': isPromoted,
        'boostScore': boostScore,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ProductItem.fromJson(Map<String, dynamic> json) => ProductItem(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        price: (json['price'] as num).toDouble(),
        imageUrl: json['imageUrl'] as String?,
        videoUrl: json['videoUrl'] as String?,
        sellerId: json['sellerId'] as String,
        sellerName: json['sellerName'] as String,
        views: json['views'] as int? ?? 0,
        purchases: json['purchases'] as int? ?? 0,
        isPromoted: json['isPromoted'] as bool? ?? false,
        boostScore: json['boostScore'] as int? ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );
}

