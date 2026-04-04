import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:foto_flow2/app_state.dart';
import 'package:foto_flow2/features/choose_album/choose_album_screen.dart';
import 'package:foto_flow2/features/create_album/create_album_screen.dart';
import 'package:foto_flow2/features/review_photo/photo_local_save.dart';
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
  bool _photoTaken = false;
  bool _capturing = false;
  CameraController? _cameraController;
  bool _hadAppPaused = false;
  bool _androidCameraSetupBusy = false;

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
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kamera-Berechtigung verweigert.')),
          );
        }
        return;
      }

      final cameras = await availableCameras();
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
      } catch (e, st) {
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

  Future<void> _onShutterPressed() async {
    if (_useRealCamera()) {
      if (_capturing) return;
      final c = _cameraController;
      if (c == null || !c.value.isInitialized) return;

      setState(() => _capturing = true);
      try {
        final xfile = await c.takePicture();
        try {
          await saveCapturedPhotoToAppDir(xfile.path, activeAlbumName);
        } catch (e, st) {
          debugPrint('Speichern: $e\n$st');
        }
        if (!mounted) return;
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
                    if (activeAlbumName != null) ...[
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
                      const SizedBox(height: 12),
                    ],
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
    );
  }
}
