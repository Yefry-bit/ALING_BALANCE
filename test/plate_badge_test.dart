import 'package:aling_balance/core/constants/app_colors.dart';
import 'package:aling_balance/widgets/plate_badge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la placa del taxi es blanca y la de los demás amarilla', () {
    expect(PlateBadge.colorFor('Taxi'), AppColors.plateTaxi);
    expect(PlateBadge.colorFor(' taxi '), AppColors.plateTaxi);
    expect(PlateBadge.colorFor('Particular'), AppColors.plate);
    expect(PlateBadge.colorFor('Camioneta'), AppColors.plate);
    expect(PlateBadge.colorFor(null), AppColors.plate);
  });
}
