/// Reglas de validación de vehículos. Son las mismas que aplican la web
/// (VehicleFormPage.jsx) y el backend (vehiculo.validation.js) para que los
/// tres canales acepten y rechacen exactamente los mismos datos.
class VehicleValidators {
  VehicleValidators._();

  /// ABC123 (carro) o ABC12D (moto).
  static final RegExp placaRegex = RegExp(r'^(?:[A-Z]{3}[0-9]{3}|[A-Z]{3}[0-9]{2}[A-Z])$');
  static final RegExp _soloLetrasTipo = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s/-]+$');
  static final RegExp _soloLetrasColor = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s/,-]+$');

  static const int minAnio = 1980;
  static int get maxAnio => DateTime.now().year + 1;

  /// Quita espacios y guiones y pasa a mayúsculas ("abc-123" -> "ABC123").
  static String normalizePlaca(String? value) =>
      (value ?? '').replaceAll(RegExp(r'[\s-]'), '').toUpperCase();

  static String? validateTipo(String? value) {
    final val = (value ?? '').trim();
    if (val.isEmpty) return 'El tipo de vehículo es obligatorio.';
    if (val.length < 2 || val.length > 40) {
      return 'El tipo de vehículo debe tener entre 2 y 40 caracteres.';
    }
    if (!_soloLetrasTipo.hasMatch(val)) return 'El tipo de vehículo solo debe contener letras.';
    return null;
  }

  static String? validatePlaca(String? value) {
    final val = normalizePlaca(value);
    if (val.isEmpty) return 'La placa del vehículo es obligatoria.';
    if (!placaRegex.hasMatch(val)) {
      return 'La placa debe tener formato ABC123 (carro) o ABC12D (moto).';
    }
    return null;
  }

  static String? validateMarca(String? value) {
    final val = (value ?? '').trim();
    if (val.isEmpty) return 'La marca del vehículo es obligatoria.';
    if (val.length < 2 || val.length > 50) return 'La marca debe tener entre 2 y 50 caracteres.';
    return null;
  }

  static String? validateModelo(String? value) {
    final val = (value ?? '').trim();
    if (val.isEmpty) return 'El modelo del vehículo es obligatorio.';
    if (val.length < 2 || val.length > 60) return 'El modelo debe tener entre 2 y 60 caracteres.';
    return null;
  }

  static String? validateAnio(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return 'El año del vehículo es obligatorio.';
    if (!RegExp(r'^\d{4}$').hasMatch(raw)) return 'El año debe tener exactamente 4 dígitos numéricos.';
    final anio = int.parse(raw);
    if (anio < minAnio || anio > maxAnio) return 'El año debe estar entre $minAnio y $maxAnio.';
    return null;
  }

  static String? validateColor(String? value) {
    final val = (value ?? '').trim();
    if (val.isEmpty) return 'El color del vehículo es obligatorio.';
    if (val.length < 3 || val.length > 40) return 'El color debe tener entre 3 y 40 caracteres.';
    if (!_soloLetrasColor.hasMatch(val)) return 'El color solo debe contener letras (ej. Negro, Blanco).';
    return null;
  }

  /// SOAT y tecnomecánica: obligatorias y estrictamente posteriores a hoy.
  static String? validateFechaVencimiento(DateTime? fecha, String documento) {
    if (fecha == null) return 'La fecha de vencimiento $documento es obligatoria.';
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    if (!dia.isAfter(hoy)) return 'La fecha de vencimiento $documento debe ser posterior a hoy.';
    return null;
  }

  static DateTime get manana {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  static String? validateTarjetaPropiedad({required bool tieneArchivo, String? url}) {
    if (tieneArchivo || (url != null && url.trim().isNotEmpty)) return null;
    return 'La tarjeta de propiedad es obligatoria (formato JPG, PNG o WEBP).';
  }

  static String? validateCantidadFotos(int cantidad) {
    if (cantidad < 1 || cantidad > 3) {
      return 'Debes subir mínimo 1 y máximo 3 fotos del vehículo (formato JPG, PNG o WEBP).';
    }
    return null;
  }
}
