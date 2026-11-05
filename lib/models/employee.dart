/// Un empleado del taller.
class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.document,
    this.phone = '',
    this.active = true,
  });

  final int id;
  final String name;

  /// Número de identificación (único por empleado).
  final String document;
  final String phone;
  final bool active;

  Employee copyWith({bool? active}) {
    return Employee(
      id: id,
      name: name,
      document: document,
      phone: phone,
      active: active ?? this.active,
    );
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      document: json['document']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      active: json['active'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'document': document,
      'phone': phone,
      'active': active,
    };
  }
}
