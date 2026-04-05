import 'package:flutter/material.dart';
import 'package:foto_flow2/app_state.dart';
import 'package:foto_flow2/features/review_photo/photo_local_image.dart';
import 'package:foto_flow2/features/review_photo/photo_local_read.dart';

String _savePhotoBasename(String path) {
  final n = path.replaceAll(r'\', '/');
  final i = n.lastIndexOf('/');
  return i < 0 ? n : n.substring(i + 1);
}

/// UI-only: Zielalbum anzeigen, gespeicherte Fotos als Bilder, Speichern-Button.
class SavePhotoScreen extends StatefulWidget {
  const SavePhotoScreen({super.key});

  @override
  State<SavePhotoScreen> createState() => _SavePhotoScreenState();
}

class _SavePhotoScreenState extends State<SavePhotoScreen> {
  String? _previewPath;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final trimmed = activeAlbumName?.trim();
    final albumLabel = (trimmed != null && trimmed.isNotEmpty) ? trimmed : '—';

    return Stack(
      fit: StackFit.expand,
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF7F7F7),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Foto speichern',
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Das Foto wird in diesem Album gespeichert.',
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Gewähltes Album',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          albumLabel,
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: FutureBuilder<List<String>>(
                      future: listSavedPhotoPaths(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Fotos konnten nicht geladen werden.',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.black54,
                              ),
                            ),
                          );
                        }
                        final paths = snapshot.data ?? [];
                        if (paths.isEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '0 Fotos',
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'Noch keine gespeicherten Fotos.',
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        final visiblePaths = paths.take(10).toList();
                        final totalCount = paths.length;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              totalCount == 1 ? '1 Foto' : '$totalCount Fotos',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: GridView.builder(
                                itemCount: visiblePaths.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      childAspectRatio: 4 / 3,
                                    ),
                                itemBuilder: (context, index) {
                                  final path = visiblePaths[index];
                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => _previewPath = path),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: savedPhotoFileImage(path),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _savePhotoBasename(path),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: textTheme.labelSmall?.copyWith(
                                            color: Colors.black54,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (totalCount > 10) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${totalCount - 10} weitere Fotos',
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        surfaceTintColor: Colors.transparent,
                      ),
                      child: const Text(
                        'Speichern',
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
        ),
        if (_previewPath != null)
          Positioned.fill(
            child: Material(
              color: Colors.black,
              child: SafeArea(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _previewPath = null),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: savedPhotoFileImage(_previewPath!),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
