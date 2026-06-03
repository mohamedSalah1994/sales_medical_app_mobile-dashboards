class CustomerSeriesModel {
  const CustomerSeriesModel({
    required this.series,
    required this.name,
  });

  final int series;
  final String name;

  factory CustomerSeriesModel.fromJson(Map<String, dynamic> json) {
    return CustomerSeriesModel(
      series: (json['series'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
    );
  }
}
