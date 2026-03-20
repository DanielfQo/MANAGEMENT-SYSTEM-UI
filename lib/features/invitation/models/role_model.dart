class RoleModel {
  final String value;
  final String label;

  RoleModel({required this.value, required this.label});

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      value: json['value'],
      label: json['label'],
    );
  }
}