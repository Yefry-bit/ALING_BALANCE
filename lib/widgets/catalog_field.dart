import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/vehicle_catalog.dart';

/// Ancho por debajo del cual se usa la hoja de selección (celular).
const double _phoneWidth = 600;

/// Opción especial "Otra marca / Otro modelo" dentro de las sugerencias.
const String _other = '\u0000otro';

/// Campo para elegir la marca o el modelo de una lista, con la opción
/// "Otra marca" / "Otro modelo" para escribir uno que no esté.
///
/// - En pantallas anchas se escribe y aparecen sugerencias debajo.
/// - En el celular, al tocarlo se abre una hoja con buscador y la lista
///   completa, con botones grandes.
/// - Si se elige "Otra…", el campo pasa a ser de texto libre; el botón de la
///   derecha vuelve a la lista.
class CatalogField extends StatefulWidget {
  const CatalogField({
    super.key,
    required this.controller,
    required this.options,
    required this.decoration,
    required this.otherLabel,
    required this.pickerTitle,
    required this.customHint,
    this.validator,
    this.enabled = true,
    this.maxLength,
    this.onSelected,
    this.onChanged,
  });

  final TextEditingController controller;

  /// Lista completa de opciones. Si está vacía, el campo es de texto libre.
  final List<String> options;

  final InputDecoration decoration;

  /// "Otra marca", "Otro modelo".
  final String otherLabel;

  /// Título de la hoja de selección: "Elige la marca".
  final String pickerTitle;

  /// Texto de ayuda cuando se escribe a mano: "Escribe la marca".
  final String customHint;

  final FormFieldValidator<String>? validator;
  final bool enabled;
  final int? maxLength;

  /// Se llama al elegir una opción o al pasar a "Otra…".
  final ValueChanged<String>? onSelected;
  final ValueChanged<String>? onChanged;

  @override
  State<CatalogField> createState() => _CatalogFieldState();
}

class _CatalogFieldState extends State<CatalogField> {
  final _focusNode = FocusNode();
  late bool _custom = _startsCustom();

  /// Lo último que se escribió (para conservarlo al pasar a "Otra…").
  String _lastQuery = '';

  bool _startsCustom() {
    if (widget.options.isEmpty) return true;
    final text = widget.controller.text.trim();
    if (text.isEmpty) return false;
    final wanted = VehicleCatalog.key(text);
    return !widget.options.any((o) => VehicleCatalog.key(o) == wanted);
  }

  @override
  void didUpdateWidget(CatalogField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Cambió la lista (por ejemplo, otra marca para el modelo).
    if (!listEquals(oldWidget.options, widget.options)) {
      _custom = _startsCustom();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool get _hasList => widget.options.isNotEmpty;

  void _choose(String value) {
    widget.controller.text = value;
    widget.onSelected?.call(value);
  }

  void _writeByHand([String text = '']) {
    setState(() => _custom = true);
    widget.controller.text = text;
    widget.onSelected?.call(text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _backToList() {
    setState(() => _custom = false);
    widget.controller.clear();
    widget.onSelected?.call('');
    if (MediaQuery.sizeOf(context).width < _phoneWidth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openPicker();
      });
    }
  }

  Future<void> _openPicker() async {
    if (!widget.enabled) return;
    final result = await showModalBottomSheet<_Pick>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.panel,
      builder: (_) => _PickerSheet(
        title: widget.pickerTitle,
        options: widget.options,
        otherLabel: widget.otherLabel,
        current: widget.controller.text,
      ),
    );
    if (!mounted || result == null) return;
    if (result.custom) {
      _writeByHand(result.value);
    } else {
      _choose(result.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_custom || !_hasList) return _customField();
    if (MediaQuery.sizeOf(context).width < _phoneWidth) return _phoneField();
    return _typeAheadField();
  }

  /// Texto libre (marca o modelo que no está en la lista).
  Widget _customField() {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      maxLength: widget.maxLength,
      textCapitalization: TextCapitalization.words,
      decoration: widget.decoration.copyWith(
        counterText: '',
        hintText: widget.customHint,
        helperText: _hasList
            ? 'Fuera de la lista: se guarda como lo escribas'
            : null,
        suffixIcon: _hasList
            ? IconButton(
                tooltip: 'Elegir de la lista',
                icon: const Icon(Icons.format_list_bulleted_rounded),
                onPressed: widget.enabled ? _backToList : null,
              )
            : null,
      ),
      validator: widget.validator,
      onChanged: widget.onChanged,
    );
  }

  /// Celular: el campo no abre el teclado, abre la hoja con la lista.
  Widget _phoneField() {
    return TextFormField(
      controller: widget.controller,
      readOnly: true,
      showCursor: false,
      enableInteractiveSelection: false,
      enabled: widget.enabled,
      onTap: _openPicker,
      decoration: widget.decoration.copyWith(
        counterText: '',
        hintText: 'Toca para elegir',
        suffixIcon: const Icon(Icons.expand_more_rounded),
      ),
      validator: widget.validator,
    );
  }

  /// Pantalla ancha: se escribe y aparecen sugerencias, con "Otra…" al final.
  Widget _typeAheadField() {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      displayStringForOption: (o) => o == _other ? '' : o,
      optionsBuilder: (value) {
        if (!widget.enabled) return const [];
        _lastQuery = value.text.trim();
        final wanted = VehicleCatalog.key(value.text);
        final exact =
            wanted.isNotEmpty &&
            widget.options.any((o) => VehicleCatalog.key(o) == wanted);
        return [
          ...VehicleCatalog.suggest(widget.options, value.text),
          if (!exact) _other,
        ];
      },
      onSelected: (option) {
        if (option == _other) {
          _writeByHand(_lastQuery);
        } else {
          widget.onSelected?.call(option);
        }
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: widget.enabled,
          maxLength: widget.maxLength,
          textCapitalization: TextCapitalization.words,
          decoration: widget.decoration.copyWith(
            counterText: '',
            suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
          ),
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: (_) => onSubmit(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Material(
              color: AppColors.panelHigh,
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 300,
                  maxWidth: 380,
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    final highlighted =
                        AutocompleteHighlightedOption.of(context) == index;
                    return InkWell(
                      onTap: () => onSelected(option),
                      child: Container(
                        decoration: BoxDecoration(
                          color: highlighted
                              ? AppColors.accent.withValues(alpha: 0.12)
                              : null,
                          border: option == _other && index > 0
                              ? const Border(
                                  top: BorderSide(color: AppColors.border),
                                )
                              : null,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        child: option == _other
                            ? _OtherLabel(text: widget.otherLabel)
                            : Text(option),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OtherLabel extends StatelessWidget {
  const _OtherLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.edit_outlined, size: 18, color: AppColors.accent),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            '$text…',
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Resultado de la hoja: una opción de la lista o texto escrito a mano.
typedef _Pick = ({String value, bool custom});

/// Hoja de selección para el celular: buscador, lista completa con botones
/// grandes y "Otra…" siempre visible abajo.
class _PickerSheet extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.options,
    required this.otherLabel,
    required this.current,
  });

  final String title;
  final List<String> options;
  final String otherLabel;
  final String current;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<String> _matches(String query) {
    final wanted = VehicleCatalog.key(query);
    if (wanted.isEmpty) return widget.options;
    final starts = <String>[];
    final contains = <String>[];
    for (final option in widget.options) {
      final k = VehicleCatalog.key(option);
      if (k.startsWith(wanted)) {
        starts.add(option);
      } else if (k.contains(wanted)) {
        contains.add(option);
      }
    }
    return [...starts, ...contains];
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim();
    final matches = _matches(query);
    final exact = matches.any(
      (o) => VehicleCatalog.key(o) == VehicleCatalog.key(query),
    );
    final currentKey = VehicleCatalog.key(widget.current);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _search,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Buscar…',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  if (query.isNotEmpty && !exact)
                    ListTile(
                      minTileHeight: 56,
                      leading: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.accent,
                      ),
                      title: Text('Usar "$query"'),
                      subtitle: const Text('No está en la lista'),
                      onTap: () =>
                          Navigator.of(context)
                              .pop<_Pick>((value: query, custom: true)),
                    ),
                  for (final option in matches)
                    ListTile(
                      minTileHeight: 52,
                      title: Text(option, style: const TextStyle(fontSize: 16)),
                      trailing: VehicleCatalog.key(option) == currentKey
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.accent,
                            )
                          : null,
                      onTap: () =>
                          Navigator.of(context)
                              .pop<_Pick>((value: option, custom: false)),
                    ),
                  if (matches.isEmpty && query.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No hay opciones en la lista.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.mutedText),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            SafeArea(
              top: false,
              child: ListTile(
                minTileHeight: 60,
                leading: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.accent,
                ),
                title: Text(
                  widget.otherLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Para escribir a mano lo que no esté en la lista',
                ),
                onTap: () =>
                    Navigator.of(context).pop<_Pick>((value: '', custom: true)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
