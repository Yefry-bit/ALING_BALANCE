/// Datos que se envían al servidor para registrar un empleado.
class NewEmployeeData {
  const NewEmployeeData({
    required this.name,
    required this.document,
    this.phone = '',
  });

  final String name;
  final String document;
  final String phone;

  Map<String, dynamic> toJson() {
    return {'name': name, 'document': document, 'phone': phone};
  }
}
