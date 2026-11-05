import 'package:aling_balance/core/constants/vehicle_catalog.dart';
import 'package:aling_balance/widgets/catalog_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Formulario de prueba con marca y modelo, como en los diálogos reales.
class _Form extends StatefulWidget {
  const _Form({required this.brand, required this.model});

  final TextEditingController brand;
  final TextEditingController model;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CatalogField(
                controller: widget.brand,
                options: VehicleCatalog.brands,
                otherLabel: 'Otra marca',
                pickerTitle: 'Elige la marca',
                customHint: 'Escribe la marca',
                onSelected: (_) => setState(widget.model.clear),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(),
              ),
              const SizedBox(height: 16),
              CatalogField(
                controller: widget.model,
                options: VehicleCatalog.modelsFor(widget.brand.text),
                otherLabel: 'Otro modelo',
                pickerTitle: 'Elige el modelo',
                customHint: 'Escribe el modelo',
                decoration: const InputDecoration(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<(TextEditingController, TextEditingController)> _pump(
  WidgetTester tester,
  Size size,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final brand = TextEditingController();
  final model = TextEditingController();
  addTearDown(brand.dispose);
  addTearDown(model.dispose);
  await tester.pumpWidget(_Form(brand: brand, model: model));
  return (brand, model);
}

void main() {
  testWidgets('computador: "Otra marca…" permite escribir una marca rara', (
    tester,
  ) async {
    final (brand, model) = await _pump(tester, const Size(1200, 800));
    final fields = find.byType(TextFormField);

    await tester.tap(fields.at(0));
    await tester.enterText(fields.at(0), 'tata');
    await tester.pumpAndSettle();
    // No está en la lista: solo aparece la opción de escribirla a mano.
    expect(find.text('Otra marca…'), findsOneWidget);
    await tester.tap(find.text('Otra marca…'));
    await tester.pumpAndSettle();

    // Queda en texto libre conservando lo escrito, con botón para volver.
    expect(brand.text, 'tata');
    expect(find.byTooltip('Elegir de la lista'), findsOneWidget);
    await tester.enterText(fields.at(0), 'Tata Motors');
    await tester.pump();

    // Marca fuera del catálogo: el modelo se escribe a mano.
    await tester.enterText(fields.at(1), 'Xenon');
    await tester.pump();
    expect(model.text, 'Xenon');
    expect(VehicleCatalog.canonicalBrand(brand.text), 'Tata Motors');

    // Volver a la lista borra lo escrito.
    await tester.tap(find.byTooltip('Elegir de la lista'));
    await tester.pumpAndSettle();
    expect(brand.text, isEmpty);
    expect(find.byTooltip('Elegir de la lista'), findsNothing);
  });

  testWidgets('celular: se elige de una hoja con buscador y "Otro modelo"', (
    tester,
  ) async {
    final (brand, model) = await _pump(tester, const Size(390, 844));
    final fields = find.byType(TextFormField);

    // Al tocar la marca se abre la hoja con la lista completa.
    await tester.tap(fields.at(0));
    await tester.pumpAndSettle();
    expect(find.text('Elige la marca'), findsOneWidget);
    expect(find.text('Otra marca'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'ren');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Renault'));
    await tester.pumpAndSettle();
    expect(brand.text, 'Renault');

    // Modelo: hoja con los modelos de Renault y "Otro modelo".
    await tester.tap(fields.at(1));
    await tester.pumpAndSettle();
    expect(find.text('Elige el modelo'), findsOneWidget);
    expect(find.text('Logan'), findsOneWidget);
    await tester.tap(find.text('Otro modelo'));
    await tester.pumpAndSettle();

    expect(find.text('Elige el modelo'), findsNothing);
    await tester.enterText(fields.at(1), 'Logan Familiar');
    await tester.pump();
    expect(model.text, 'Logan Familiar');
  });

  testWidgets('celular: buscar algo que no está ofrece usarlo tal cual', (
    tester,
  ) async {
    final (brand, _) = await _pump(tester, const Size(390, 844));

    await tester.tap(find.byType(TextFormField).at(0));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Tata Motors');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar "Tata Motors"'));
    await tester.pumpAndSettle();

    expect(brand.text, 'Tata Motors');
    expect(find.byTooltip('Elegir de la lista'), findsOneWidget);
  });
}
