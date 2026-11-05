/// Estado de una operación de servicio.
///
/// [label] es el texto que se muestra en pantalla y el mismo que se guarda
/// en el almacenamiento, así los datos ya guardados siguen siendo válidos.
enum ServiceStatus {
  inProgress('En proceso'),
  finished('Terminado');

  const ServiceStatus(this.label);

  final String label;

  /// Convierte el texto guardado en un estado; si no se reconoce, "En proceso".
  static ServiceStatus fromLabel(String? label) {
    return ServiceStatus.values.firstWhere(
      (status) => status.label == label,
      orElse: () => ServiceStatus.inProgress,
    );
  }

  /// El estado contrario (para el botón Finalizar / Reabrir).
  ServiceStatus get toggled {
    return this == ServiceStatus.inProgress
        ? ServiceStatus.finished
        : ServiceStatus.inProgress;
  }
}
