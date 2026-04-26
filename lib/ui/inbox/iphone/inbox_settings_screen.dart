import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musa/modules/inbox/providers/inbox_folder_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kInboxDeviceLabelKey = 'inbox.deviceLabel.v1';
const String kInboxHistoryLimitKey = 'inbox.historyLimit.v1';

final inboxDeviceLabelProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(kInboxDeviceLabelKey) ?? 'iPhone';
});

final inboxHistoryLimitProvider = FutureProvider<int>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(kInboxHistoryLimitKey) ?? 20;
});

class InboxSettingsScreen extends ConsumerStatefulWidget {
  const InboxSettingsScreen({super.key});

  @override
  ConsumerState<InboxSettingsScreen> createState() =>
      _InboxSettingsScreenState();
}

class _InboxSettingsScreenState extends ConsumerState<InboxSettingsScreen> {
  late TextEditingController _label;
  int _limit = 20;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _label.text = prefs.getString(kInboxDeviceLabelKey) ?? 'iPhone';
      _limit = prefs.getInt(kInboxHistoryLimitKey) ?? 20;
      _ready = true;
    });
  }

  Future<void> _saveLabel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kInboxDeviceLabelKey, _label.text.trim());
    ref.invalidate(inboxDeviceLabelProvider);
  }

  Future<void> _saveLimit(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kInboxHistoryLimitKey, v);
    if (!mounted) return;
    setState(() => _limit = v);
    ref.invalidate(inboxHistoryLimitProvider);
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final folder = ref.watch(inboxFolderProvider);
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Bandeja')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Carpeta sincronizada',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(folder.path ?? 'Sin configurar',
              style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () =>
                ref.read(inboxFolderProvider.notifier).chooseNewFolder(),
            child: const Text('Cambiar carpeta…'),
          ),
          const Divider(height: 32),
          const Text('Etiqueta de este dispositivo',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          TextField(
            controller: _label,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            onEditingComplete: _saveLabel,
            onTapOutside: (_) => _saveLabel(),
          ),
          const Divider(height: 32),
          const Text('Capturas en historial',
              style: TextStyle(fontWeight: FontWeight.w700)),
          Slider(
            value: _limit.toDouble(),
            min: 5,
            max: 50,
            divisions: 9,
            label: _limit.toString(),
            onChanged: (v) => setState(() => _limit = v.toInt()),
            onChangeEnd: (v) => _saveLimit(v.toInt()),
          ),
          Text('Mostrar las $_limit capturas más recientes.'),
        ],
      ),
    );
  }
}
