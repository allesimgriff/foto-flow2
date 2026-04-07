import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:foto_flow2/app_state.dart';
import 'package:foto_flow2/features/choose_album/choose_album_screen.dart';
import 'package:foto_flow2/features/create_album/create_album_screen.dart';
import 'package:foto_flow2/features/privacy_notice/privacy_notice_screen.dart';
import 'package:foto_flow2/features/review_photo/photo_local_save.dart';
import 'package:foto_flow2/features/save_photo/save_photo_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void _startCamera() {
  debugPrint('Dummy: Kamera gestartet');
}

void _dummyTakePhoto() {
  debugPrint('Dummy: Foto aufnehmen');
}

bool _useRealCamera() =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

class ReviewPhotoScreen extends StatefulWidget {
  const ReviewPhotoScreen({super.key});

  @override
  State<ReviewPhotoScreen> createState() => _ReviewPhotoScreenState();
}

class _ReviewPhotoScreenState extends State<ReviewPhotoScreen>
    with WidgetsBindingObserver {
  /// Minimales gültiges JPEG (1×1 px), nur wenn keine echte Aufnahme möglich ist.
  static final Uint8List _kFallbackJpegBytes = Uint8List.fromList(
    base64Decode(
      '/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAb/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCDwAD//2Q==',
    ),
  );

  bool _photoTaken = false;
  bool _capturing = false;
  CameraController? _cameraController;
  bool _hadAppPaused = false;
  bool _androidCameraSetupBusy = false;
  Uint8List? _lastPreviewBytes;
  /// Pfad der zuletzt unter `ohne_album` gespeicherten Datei (für nachträgliche Album-Zuordnung).
  String? _lastOhneAlbumSavedPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_useRealCamera()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initAndroidCamera());
    } else {
      _startCamera();
    }
  }

  Future<void> _disposeCameraAndClear() async {
    final old = _cameraController;
    _cameraController = null;
    if (old != null) {
      await old.dispose();
    }
  }

  void _pauseCameraPreviewSafely() {
    final c = _cameraController;
    if (c == null || !c.value.isInitialized) return;
    c.pausePreview().catchError((Object e, StackTrace st) {
      debugPrint('Kamera pause: $e\n$st');
    });
  }

  void _restoreCameraAfterBackground() {
    _restoreCameraAfterBackgroundAsync().catchError((Object e, StackTrace st) {
      debugPrint('Kamera nach Hintergrund: $e\n$st');
    });
  }

  Future<void> _restoreCameraAfterBackgroundAsync() async {
    if (!_useRealCamera() || !mounted) return;
    final perm = await Permission.camera.status;
    if (!perm.isGranted) return;
    final c = _cameraController;
    if (c != null && c.value.isInitialized && !c.value.hasError) {
      if (c.value.isPreviewPaused) {
        try {
          await c.resumePreview();
        } catch (e, st) {
          debugPrint('Kamera resume: $e\n$st');
          await _disposeCameraAndClear();
          if (mounted) await _initAndroidCamera();
        }
      }
      if (mounted) setState(() {});
      return;
    }
    await _disposeCameraAndClear();
    if (mounted) await _initAndroidCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_useRealCamera()) return;
    if (state == AppLifecycleState.paused) {
      _hadAppPaused = true;
      _pauseCameraPreviewSafely();
    } else if (state == AppLifecycleState.resumed && _hadAppPaused) {
      _hadAppPaused = false;
      _restoreCameraAfterBackground();
    }
  }

  Future<void> _initAndroidCamera() async {
    debugPrint('[cam] _initAndroidCamera start');
    if (!_useRealCamera()) return;
    while (_androidCameraSetupBusy) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      if (!mounted) return;
    }
    final ready = _cameraController;
    if (ready != null &&
        ready.value.isInitialized &&
        !ready.value.hasError) {
      return;
    }

    _androidCameraSetupBusy = true;
    try {
      final status = await Permission.camera.request();
      debugPrint('[cam] Permission.camera.request → $status');
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kamera-Berechtigung verweigert.')),
          );
        }
        return;
      }

      final cameras = await availableCameras();
      debugPrint('[cam] availableCameras → count=${cameras.length}');
      if (cameras.isEmpty || !mounted) return;

      CameraDescription cam;
      try {
        cam = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
        );
      } catch (_) {
        cam = cameras.first;
      }

      final next = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      try {
        await next.initialize();
        debugPrint('[cam] initialize() OK');
      } catch (e, st) {
        debugPrint('[cam] initialize() Fehler');
        debugPrint('Kamera: $e\n$st');
        await next.dispose();
        return;
      }

      if (!mounted) {
        await next.dispose();
        return;
      }

      final old = _cameraController;
      _cameraController = next;
      await old?.dispose();
      if (mounted) setState(() {});
    } finally {
      _androidCameraSetupBusy = false;
    }
  }

  Future<String?> _writeFallbackJpegTempPath() async {
    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/foto_flow2_fallback_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(path).writeAsBytes(_kFallbackJpegBytes);
      debugPrint('[cam] Fallback-JPEG → $path');
      return path;
    } catch (e, st) {
      debugPrint('[cam] Fallback-JPEG fehlgeschlagen: $e\n$st');
      return null;
    }
  }

  Future<void> _completeRealCameraSaveFromPath(String sourcePath) async {
    final albumAtSave = activeAlbumName;
    String? savedPath;
    try {
      debugPrint('[cam] vor saveCapturedPhotoToAppDir path=$sourcePath');
      savedPath =
          await saveCapturedPhotoToAppDir(sourcePath, activeAlbumName);
      debugPrint('[cam] nach saveCapturedPhotoToAppDir OK');
    } catch (e, st) {
      debugPrint('[cam] nach saveCapturedPhotoToAppDir Fehler');
      debugPrint('Speichern: $e\n$st');
    }
    if (mounted) {
      if (albumAtSave == null) {
        _lastOhneAlbumSavedPath = savedPath;
      } else {
        _lastOhneAlbumSavedPath = null;
      }
    }
    if (!mounted) return;
    if (activeAlbumName == null) {
      final bytes = await File(sourcePath).readAsBytes();
      if (!mounted) return;
      setState(() {
        _photoTaken = true;
        _lastPreviewBytes = bytes;
      });
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
  }

  Future<void> _onShutterPressed() async {
    debugPrint('[cam] _onShutterPressed start');
    if (_useRealCamera()) {
      if (_capturing) return;
      final c = _cameraController;

      setState(() => _capturing = true);
      try {
        String? sourcePath;
        if (c != null && c.value.isInitialized) {
          try {
            final xfile = await c.takePicture();
            debugPrint('[cam] takePicture() → ${xfile.path}');
            sourcePath = xfile.path;
          } catch (e, st) {
            debugPrint('[cam] takePicture fehlgeschlagen → Fallback\n$e\n$st');
          }
        } else {
          debugPrint('[cam] Kamera nicht bereit → Fallback');
        }
        sourcePath ??= await _writeFallbackJpegTempPath();
        if (sourcePath == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Foto konnte nicht aufgenommen werden.'),
              ),
            );
          }
          return;
        }
        await _completeRealCameraSaveFromPath(sourcePath);
      } catch (e, st) {
        debugPrint('Aufnahme: $e\n$st');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto konnte nicht aufgenommen werden.')),
          );
        }
      } finally {
        if (mounted) setState(() => _capturing = false);
      }
      return;
    }

    _dummyTakePhoto();
    if (activeAlbumName == null) {
      setState(() => _photoTaken = true);
    } else {
      debugPrint(
        'Dummy: Foto dem Album „$activeAlbumName" zugeordnet',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Demo: Foto dem Album „$activeAlbumName" zugeordnet.',
          ),
        ),
      );
    }
  }

  Future<void> _assignLastOhneAlbumIfNeeded() async {
    final path = _lastOhneAlbumSavedPath;
    final name = activeAlbumName?.trim();
    if (path == null || name == null || name.isEmpty) return;
    try {
      await moveSavedPhotoIntoAlbumDir(path, name);
      _lastOhneAlbumSavedPath = null;
    } catch (e, st) {
      debugPrint('Album-Zuordnung: $e\n$st');
    }
  }

  void _openCreateAlbum() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) => const CreateAlbumScreen(),
      ),
    ).then((saved) async {
      if (saved != true || !mounted) return;
      await _assignLastOhneAlbumIfNeeded();
      if (!mounted) return;
      setState(() {
        _photoTaken = false;
        _lastPreviewBytes = null;
      });
    });
  }

  void _openChooseAlbum() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) => const ChooseAlbumScreen(),
      ),
    ).then((saved) async {
      if (saved != true || !mounted) return;
      await _assignLastOhneAlbumIfNeeded();
      if (!mounted) return;
      setState(() {
        _photoTaken = false;
        _lastPreviewBytes = null;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final c = _cameraController;
    _cameraController = null;
    c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final c = _cameraController;
    final previewReady =
        _useRealCamera() && c != null && c.value.isInitialized;

    return PopScope(
      canPop: !(_photoTaken && activeAlbumName == null),
      child: Scaffold(
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
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _lastPreviewBytes != null
                            ? Image.memory(
                                _lastPreviewBytes!,
                                fit: BoxFit.contain,
                              )
                            : Text(
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
                    TextButton(
                      onPressed: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const SavePhotoScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.75),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Gespeicherte Fotos'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const PrivacyNoticeScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.75),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Datenschutz'),
                    ),
                    if (activeAlbumName != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Fotos werden dem Album „$activeAlbumName" zugeordnet.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              activeAlbumName = null;
                              hasAlbum = false;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black54,
                            side: const BorderSide(
                              color: Color(0xFFBDBDBD),
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          child: const Text('Album verlassen'),
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
                        clipBehavior: Clip.antiAlias,
                        child: previewReady
                            ? LayoutBuilder(
                                builder: (context, constraints) {
                                  final maxW = constraints.maxWidth;
                                  final maxH = constraints.maxHeight;
                                  final ar = c.value.aspectRatio;
                                  var w = maxW;
                                  var h = w / ar;
                                  if (h > maxH) {
                                    h = maxH;
                                    w = h * ar;
                                  }
                                  return Center(
                                    child: SizedBox(
                                      width: w,
                                      height: h,
                                      child: CameraPreview(c),
                                    ),
                                  );
                                },
                              )
                            : Align(
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'Hier erscheint dein Foto',
                                    textAlign: TextAlign.center,
                                    style: textTheme.titleMedium?.copyWith(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _capturing ? null : () => _onShutterPressed(),
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
      ),
    );
  }
}
