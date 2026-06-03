class TargetType {
  final String id;
  final String name;
  final String code;
  final String description;
  final bool isActive;
  final bool canHaveDetails;
  final int displayOrder;

  const TargetType({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.isActive,
    required this.canHaveDetails,
    required this.displayOrder,
  });
}
