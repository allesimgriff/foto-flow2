import 'package:flutter/material.dart';

/// UI-only: Albumname eingeben und Hauptbutton (ohne Navigation/Speicherung).
class CreateAlbumScreen extends StatefulWidget {
  const CreateAlbumScreen({super.key});

  @override
  State<CreateAlbumScreen> createState() => _CreateAlbumScreenState();
}

class _CreateAlbumScreenState extends State<CreateAlbumScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _hasName => _nameController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Album erstellen',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Geben Sie einen Namen für das Album ein.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: Colors.black54,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 20,
                ),
                child: TextField(
                  controller: _nameController,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.done,
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Name des Albums',
                    hintStyle: textTheme.titleMedium?.copyWith(
                      color: Colors.black38,
                      height: 1.4,
                    ),
                    border: InputBorder.none,
                    isDense: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _hasName ? () {} : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE0E0E0),
                    disabledForegroundColor: Colors.black38,
                    surfaceTintColor: Colors.transparent,
                  ),
                  child: const Text(
                    'Album erstellen',
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
