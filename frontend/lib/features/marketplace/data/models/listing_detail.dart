import 'listing_summary.dart';

class ListingDetail {
  final ListingSummary summary;
  final String description;
  final int availableStock;
  final List<String> partNumbers;
  final List<String> imageUrls;

  const ListingDetail({
    required this.summary,
    this.description = '',
    this.availableStock = 0,
    this.partNumbers = const [],
    this.imageUrls = const [],
  });

  factory ListingDetail.fromJson(Map<String, dynamic> json) {
    final product = json['product'] is Map
        ? Map<String, dynamic>.from(json['product'] as Map)
        : const <String, dynamic>{};
    final media =
        product['media'] is List ? product['media'] as List : const [];
    final rawImages =
        (json['images'] as List?) ?? (json['imageUrls'] as List?) ?? media;
    final explicitPartNumbers =
        json['partNumbers'] is List ? json['partNumbers'] as List : const [];
    final rawPartNumbers = explicitPartNumbers.isNotEmpty
        ? explicitPartNumbers
        : [
            product['sku'],
            product['oemNumber'],
            product['aftermarketCode'],
          ];

    return ListingDetail(
      summary: ListingSummary.fromJson(json),
      description:
          (json['description'] ?? product['description'] ?? '').toString(),
      availableStock: int.tryParse(
            (json['availableQuantity'] ??
                    json['availableStock'] ??
                    json['available_stock'] ??
                    0)
                .toString(),
          ) ??
          0,
      partNumbers: rawPartNumbers
          .where((value) => value != null && value.toString().isNotEmpty)
          .map((value) => value.toString())
          .toList(),
      imageUrls: rawImages
          .map((value) => value is Map ? value['mediaUrl'] : value)
          .where((value) => value != null && value.toString().isNotEmpty)
          .map((value) => value.toString())
          .toList(),
    );
  }

  factory ListingDetail.fromMap(Map<String, dynamic> map) =>
      ListingDetail.fromJson(map);

  Map<String, dynamic> toJson() => {
        ...summary.toJson(),
        'description': description,
        'availableStock': availableStock,
        'partNumbers': partNumbers,
        'imageUrls': imageUrls,
      };
}
