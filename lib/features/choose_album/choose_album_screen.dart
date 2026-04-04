import 'package:flutter/material.dart';
import 'package:foto_flow2/app_state.dart';

/// UI-only: Albumliste mit lokaler Auswahl und Hauptbutton (ohne Navigation/Logik).
class ChooseAlbumScreen extends StatefulWidget {
  const ChooseAlbumScreen({super.key});

  @override
  State<ChooseAlbumScreen> createState() => _ChooseAlbumScreenState();
}

class _ChooseAlbumScreenState extends State<ChooseAlbumScreen> {
  static const List<String> _demoAlbums = [
    'Auto',
    'Familie',
    'Garten',
    'Urlaub',
  ];

  String? _selected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasSelection = _selected != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Album wählen',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Wählen Sie ein Album aus.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: Colors.black54,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _demoAlbums.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final name = _demoAlbums[index];
                    final isSelected = _selected == name;
                    return _AlbumTile(
                      label: name,
                      selected: isSelected,
                      onTap: () => setState(() => _selected = name),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: hasSelection
                      ? () {
                          activeAlbumName = _selected!;
                          hasAlbum = true;
                          Navigator.pop(context, true);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE0E0E0),
                    disabledForegroundColor: Colors.black38,
                    surfaceTintColor: Colors.transparent,
                  ),
                  child: const Text(
                    'Album auswählen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlbumTile extends StatelessWidget {
  const _AlbumTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFE8E8E8),
              width: selected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.black87,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
