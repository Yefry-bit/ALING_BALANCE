import 'package:aling_balance/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalización', () {
    test('la placa queda como ABC-123', () {
      expect(Validators.normalizePlate('abc123'), 'ABC-123');
      expect(Validators.normalizePlate(' ABC 123 '), 'ABC-123');
      expect(Validators.normalizePlate('abc-123'), 'ABC-123');
    });

    test('el teléfono queda solo con dígitos y sin +57', () {
      expect(Validators.normalizePhone('+57 300 123 4567'), '3001234567');
      expect(Validators.normalizePhone('(300) 123-4567'), '3001234567');
    });

    test('el texto junta espacios repetidos', () {
      expect(Validators.normalizeText('  Spark   GT '), 'Spark GT');
    });

    test('el usuario se guarda en minúsculas', () {
      expect(Validators.normalizeUsername(' María.G '), 'maría.g');
    });
  });

  group('placa', () {
    test('acepta el formato ABC-123', () {
      expect(Validators.plate('ABC-123'), isNull);
      expect(Validators.plate('abc123'), isNull);
    });

    test('rechaza formatos inválidos', () {
      expect(Validators.plate(''), isNotNull);
      expect(Validators.plate('AB-1234'), isNotNull);
      expect(Validators.plate('ABCD-12'), isNotNull);
    });
  });

  group('nombre', () {
    test('acepta nombres con tildes, apóstrofes y guiones', () {
      expect(Validators.personName('Carlos Pérez'), isNull);
      expect(Validators.personName("María-José O'Neil"), isNull);
    });

    test('rechaza nombres vacíos, cortos o con números', () {
      expect(Validators.personName(''), isNotNull);
      expect(Validators.personName('Al'), isNotNull);
      expect(Validators.personName('Carlos123'), isNotNull);
    });
  });

  group('identificación y teléfono', () {
    test('la identificación exige entre 5 y 12 dígitos', () {
      expect(Validators.document('1234567890'), isNull);
      expect(Validators.document('1234'), isNotNull);
      expect(Validators.document('12AB567'), isNotNull);
      expect(Validators.document(''), isNotNull);
    });

    test('el teléfono es opcional pero debe ser válido si se escribe', () {
      expect(Validators.phone(''), isNull);
      expect(Validators.phone('3001234567'), isNull);
      expect(Validators.phone('6012345678'), isNull);
      expect(Validators.phone('1234567'), isNull);
      expect(Validators.phone('12345'), isNotNull);
      expect(Validators.phone('2001234567'), isNotNull);
    });

    test('el celular de contacto es obligatorio y debe tener WhatsApp', () {
      expect(Validators.mobilePhone(''), isNotNull);
      expect(Validators.mobilePhone('   '), isNotNull);
      expect(Validators.mobilePhone('3001234567'), isNull);
      expect(Validators.mobilePhone('300 123 4567'), isNull);
      expect(Validators.mobilePhone('+57 300 123 4567'), isNull);
      expect(Validators.mobilePhone('6012345678'), isNotNull); // fijo
      expect(Validators.mobilePhone('1234567'), isNotNull);
      expect(Validators.mobilePhone('300123456'), isNotNull); // 9 dígitos
    });
  });

  group('vehículo', () {
    test('acepta marcas y modelos comunes', () {
      expect(Validators.vehicleText('Chevrolet', 'La marca'), isNull);
      expect(Validators.vehicleText('Spark GT', 'El modelo'), isNull);
      expect(Validators.vehicleText('CX-5', 'El modelo'), isNull);
    });

    test('rechaza textos vacíos, cortos o con caracteres raros', () {
      expect(Validators.vehicleText('', 'La marca'), isNotNull);
      expect(Validators.vehicleText('A', 'La marca'), isNotNull);
      expect(Validators.vehicleText('<script>', 'La marca'), isNotNull);
    });
  });

  group('usuario y contraseña', () {
    test('el usuario exige 4 a 20 caracteres válidos', () {
      expect(Validators.username('maria'), isNull);
      expect(Validators.username('maria.gomez_2'), isNull);
      expect(Validators.username('ana'), isNotNull);
      expect(Validators.username('maria gomez'), isNotNull);
    });

    test('la contraseña exige 8 caracteres, una letra y un número', () {
      expect(Validators.password('clave123'), isNull);
      expect(Validators.password('corta1'), isNotNull);
      expect(Validators.password('sololetras'), isNotNull);
      expect(Validators.password('12345678'), isNotNull);
      expect(Validators.password(''), isNotNull);
    });

    test('la confirmación debe coincidir', () {
      expect(Validators.confirmPassword('clave123', 'clave123'), isNull);
      expect(Validators.confirmPassword('otra1234', 'clave123'), isNotNull);
      expect(Validators.confirmPassword('', 'clave123'), isNotNull);
    });
  });

  group('precio', () {
    test('acepta valores entre 1 y 5.000.000', () {
      expect(Validators.price('1'), isNull);
      expect(Validators.price('20000'), isNull);
      expect(Validators.price('5000000'), isNull);
    });

    test('rechaza vacío, cero, negativos y valores enormes', () {
      expect(Validators.price(''), isNotNull);
      expect(Validators.price('0'), isNotNull);
      expect(Validators.price('-5'), isNotNull);
      expect(Validators.price('5000001'), isNotNull);
      expect(Validators.price('abc'), isNotNull);
    });
  });
}
