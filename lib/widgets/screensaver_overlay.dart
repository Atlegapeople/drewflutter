import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screensaver_widget.dart';
import '../services/sound_service.dart';

class ScreensaverOverlay extends StatefulWidget {
  final Widget child;
  final Duration inactivityDuration;

  const ScreensaverOverlay({
    super.key,
    required this.child,
    this.inactivityDuration = const Duration(seconds: 5),
  });

  @override
  State<ScreensaverOverlay> createState() => ScreensaverOverlayState();
}

class ScreensaverOverlayState extends State<ScreensaverOverlay> 
    with SingleTickerProviderStateMixin {
  Timer? _inactivityTimer;
  bool _isScreensaverActive = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _startInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    print('Starting inactivity timer for ${widget.inactivityDuration.inSeconds} seconds');
    _inactivityTimer = Timer(widget.inactivityDuration, () {
      print('Inactivity timer expired, activating screensaver');
      if (mounted) {
        setState(() {
          _isScreensaverActive = true;
        });
        _animationController.forward();
      }
    });
  }

  void _resetInactivityTimer() {
    print('Resetting inactivity timer - screensaver active: $_isScreensaverActive');
    if (_isScreensaverActive) {
      final soundService = Provider.of<SoundService>(context, listen: false);
      soundService.playSound(SoundType.buttonPress);
      
      // Fade out the screensaver
      _animationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isScreensaverActive = false;
          });
        }
      });
    } else {
      _startInactivityTimer();
    }
  }

  void resetInactivityTimer() {
    if (!_isScreensaverActive) {
      _startInactivityTimer();
    } else {
      _resetInactivityTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (_) => _resetInactivityTimer(),
      child: GestureDetector(
        onTap: _resetInactivityTimer,
        onPanDown: (_) => _resetInactivityTimer(),
        behavior: HitTestBehavior.translucent,
        child: Listener(
          onPointerDown: (_) => _resetInactivityTimer(),
          onPointerMove: (_) => _resetInactivityTimer(),
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              widget.child,
              if (_isScreensaverActive)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScreensaverWidget(
                    onTouch: _resetInactivityTimer,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}