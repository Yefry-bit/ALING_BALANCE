import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/utils/formatters.dart';
import '../data/api_client.dart';

/// Una copia de seguridad guardada en el servidor.
class BackupInfo {
  const BackupInfo({
    required this.name,
    required this.sizeBytes,
    required this.createdAt,
  });

  final String name;
  final int sizeBytes;
  final DateTime createdAt;

  factory BackupInfo.fromJson(Map<String, dynamic> json) => BackupInfo(
    name: json['name']?.toString() ?? '',
    sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
    createdAt:
        (DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
                DateTime.now())
            .toLocal(),
  );

  /// "1,2 MB" / "350 KB"
  String get sizeLabel {
    if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB';
    }
    return '${(sizeBytes / 1024).ceil()} KB';
  }
}

/// Copias de seguridad de la base de datos (solo administradores): cuándo
/// fue la última, dónde se guardan y un botón para hacer una ahora.
class BackupPanel extends StatefulWidget {
  const BackupPanel({super.key, required this.api});

  final ApiClient api;

  @override
  State<BackupPanel> createState() => _BackupPanelState();
}

class _BackupPanelState extends State<BackupPanel> {
  bool _loading = true;
  bool _creating = false;
  bool _available = false;
  String _folder = '';
  int _keep = 0;
  List<BackupInfo> _files = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.api.getObject('/api/backups');
      if (!mounted) return;
      setState(() {
        _available = data['available'] == true;
        _folder = data['folder']?.toString() ?? '';
        _keep = (data['keep'] as num?)?.toInt() ?? 0;
        _files = [
          for (final item in (data['files'] as List? ?? const []))
            BackupInfo.fromJson(Map<String, dynamic>.from(item as Map)),
        ];
        _error = null;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _createNow() async {
    setState(() => _creating = true);
    String message;
    try {
      await widget.api.postObject('/api/backups', const {});
      message = 'Copia de seguridad creada.';
      await _load();
    } on ApiException catch (error) {
      message = error.message;
    }
    if (!mounted) return;
    setState(() => _creating = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    const small = TextStyle(color: AppColors.secondaryText, fontSize: 12);
    final latest = _files.isEmpty ? null : _files.first;

    Widget body;
    if (_loading) {
      body = const Padding(
        padding: EdgeInsets.all(8),
        child: LinearProgressIndicator(color: AppColors.accent),
      );
    } else if (_error != null) {
      body = Text(_error!, style: const TextStyle(color: AppColors.danger));
    } else if (!_available) {
      body = const Text(
        'Las copias automáticas están desactivadas o la base no es SQLite '
        '(en SQL Server se usan las copias del propio SQL Server).',
        style: small,
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                latest == null
                    ? Icons.warning_amber_rounded
                    : Icons.verified_outlined,
                size: 18,
                color: latest == null ? AppColors.warning : AppColors.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  latest == null
                      ? 'Aún no hay copias.'
                      : 'Última copia: ${formatDateTime(latest.createdAt)} '
                            '(${latest.sizeLabel})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Se hace una copia al día automáticamente y se guardan las '
            'últimas $_keep (hay ${_files.length}). Carpeta en el servidor:',
            style: small,
          ),
          const SizedBox(height: 4),
          SelectableText(
            _folder,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.panel(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.backup_outlined, color: AppColors.accent),
                  SizedBox(width: 10),
                  Text(
                    'Copias de seguridad',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (_available)
                OutlinedButton.icon(
                  onPressed: _creating ? null : _createNow,
                  icon: _creating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_alt_rounded),
                  label: Text(_creating ? 'Copiando…' : 'Hacer copia ahora'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }
}
