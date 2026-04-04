import 'package:flutter/material.dart';
import 'package:foto_flow2/app_state.dart';
import 'package:foto_flow2/features/choose_album/choose_album_screen.dart';
import 'package:foto_flow2/features/create_album/create_album_screen.dart';

void _startCamera() {
  debugPrint('Dummy: Kamera gestartet');
}

void _dummyTakePhoto() {
  debugPrint('Dummy: Foto aufnehmen');
}

class ReviewPhotoScreen extends StatefulWidget {
  const ReviewPhotoScreen({super.key});

  @override
  State<ReviewPhotoScreen> createState() => _ReviewPhotoScreenState();
}

class _ReviewPhotoScreenState extends State<ReviewPhotoScreen> {
  bool _photoTaken = false;

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  void _openCreateAlbum() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) => const CreateAlbumScreen(),
      ),
    ).then((saved) {
      if (saved == true && mounted) {
        setState(() => _photoTaken = false);
      }
    });
  }

  void _openChooseAlbum() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) => const ChooseAlbumScreen(),
      ),
    ).then((saved) {
      if (saved == true && mounted) {
        setState(() => _photoTaken = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: _photoTaken
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 28),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Foto aufgenommen (Demo)',
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge?.copyWith(
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _openCreateAlbum,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          surfaceTintColor: Colors.transparent,
                        ),
                        child: const Text(
                          'Neues Album',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _openChooseAlbum,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
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
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Foto aufnehmen',
                      textAlign: TextAlign.center,
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.black87,
                      ),
                    ),
                    if (activeAlbumName != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Fotos werden dem Album „$activeAlbumName“ zugeordnet.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Hier erscheint dein Foto',
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          _dummyTakePhoto();
                          if (activeAlbumName == null) {
                            setState(() => _photoTaken = true);
                          } else {
                            debugPrint(
                              'Dummy: Foto dem Album „$activeAlbumName“ zugeordnet',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Demo: Foto dem Album „$activeAlbumName“ zugeordnet.',
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          surfaceTintColor: Colors.transparent,
                        ),
                        child: const Text(
                          'Foto aufnehmen',
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
