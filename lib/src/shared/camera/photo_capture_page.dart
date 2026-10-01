import 'dart:io';
import 'package:bs_mobile/src/shared/ui/widgets/app_text.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// หน้ากล้องถ่ายรูป (UI) — เรียกผ่าน [CameraService.takePicture] เท่านั้น
class PhotoCapturePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const PhotoCapturePage({super.key, required this.cameras});

  @override
  State<PhotoCapturePage> createState() => _PhotoCapturePageState();
}

class _PhotoCapturePageState extends State<PhotoCapturePage>
    with SingleTickerProviderStateMixin {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  int _selectedCameraIdx = 0;
  bool _isFlashOn = false;
  bool _isTakingPicture = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // ซ่อน status bar ให้ดูเต็มจอ
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeCamera(_selectedCameraIdx);
  }

  void _initializeCamera(int cameraIndex) {
    _controller = CameraController(
      widget.cameras[cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorView(snapshot.error);
          }
          if (snapshot.connectionState == ConnectionState.done) {
            return _buildCameraView();
          }
          return _buildLoadingView();
        },
      ),
    );
  }

  Widget _buildCameraView() {
    final size = MediaQuery.of(context).size;
    final scale = size.aspectRatio * _controller.value.aspectRatio;
    final adjustedScale = scale < 1 ? 1 / scale : scale;

    return Stack(
      fit: StackFit.expand,
      children: [
        // กล้องเต็มจอ
        Center(
          child: Transform.scale(
            scale: adjustedScale,
            child: CameraPreview(_controller),
          ),
        ),

        // Gradient บนล่าง ให้ปุ่มเห็นชัด
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 180,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              ),
            ),
          ),
        ),

        // ปุ่มกลับ (ซ้ายบน)
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: _buildControlButton(
            icon: Icons.arrow_back_ios_new_rounded,
            size: 22,
            onTap: () => Navigator.pop(context),
          ),
        ),

        // ปุ่ม Flash (ขวาบน)
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
          child: _buildControlButton(
            icon: _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            size: 24,
            isActive: _isFlashOn,
            onTap: _toggleFlash,
          ),
        ),

        // ปุ่มล่าง
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 24,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ปุ่มยกเลิก
              _buildBottomButton(
                icon: Icons.close_rounded,
                label: "Cancel",
                onTap: () => Navigator.pop(context),
              ),

              // ปุ่มถ่ายรูป (ใหญ่ตรงกลาง)
              _buildCaptureButton(),

              // ปุ่มสลับกล้อง
              widget.cameras.length > 1
                  ? _buildBottomButton(
                      icon: Icons.flip_camera_ios_rounded,
                      label: "Flip",
                      onTap: _switchCamera,
                    )
                  : const SizedBox(width: 64),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) {
        _animationController.reverse();
        _takePicture();
      },
      onTapCancel: () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isTakingPicture ? Colors.grey : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 24,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.amber.withOpacity(0.9)
              : Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.black : Colors.white,
          size: size,
        ),
      ),
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 6),
            AppText(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            SizedBox(height: 16),
            AppText(
              'Opening camera...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(Object? error) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.redAccent,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              const AppText(
                'Camera Unavailable',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              AppText(
                'Please check camera permissions\nand try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 160,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    elevation: 0,
                  ),
                  child: const AppText(
                    'Go Back',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _takePicture() async {
    if (_isTakingPicture) return;
    setState(() => _isTakingPicture = true);

    try {
      // Flash effect
      HapticFeedback.mediumImpact();
      final image = await _controller.takePicture();
      if (!mounted) return;

      Navigator.pop(context, File(image.path));
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (!mounted) return;
      setState(() => _isTakingPicture = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _toggleFlash() async {
    try {
      if (_isFlashOn) {
        await _controller.setFlashMode(FlashMode.off);
      } else {
        await _controller.setFlashMode(FlashMode.torch);
      }
      HapticFeedback.lightImpact();
      setState(() => _isFlashOn = !_isFlashOn);
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  Future<void> _switchCamera() async {
    try {
      if (widget.cameras.length < 2) return;

      HapticFeedback.lightImpact();
      _selectedCameraIdx = (_selectedCameraIdx + 1) % widget.cameras.length;
      await _controller.dispose();
      _initializeCamera(_selectedCameraIdx);
      setState(() => _isFlashOn = false);
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }
}
