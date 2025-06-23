import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/authentication_service.dart';
import '../services/sound_service.dart';
import '../widgets/pin_keypad.dart';
import '../widgets/rfid_scanner.dart';
import '../widgets/screensaver_overlay.dart';
import 'product_screen.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  late TabController _tabController;
  bool _isAuthenticating = false;
  String? _errorMessage;
  Timer? _errorTimer;
  final GlobalKey<RfidScannerState> _rfidScannerKey = GlobalKey<RfidScannerState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1); // Start with RFID tab
    
    // Add listener to pin controller to rebuild UI when text changes
    _pinController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _tabController.dispose();
    _errorTimer?.cancel();
    super.dispose();
  }

  void _handlePinSubmit() async {
    if (_pinController.text.isEmpty) return;
    
    final authService = Provider.of<AuthenticationService>(context, listen: false);
    final soundService = Provider.of<SoundService>(context, listen: false);
    
    if (authService.isLockedOut) {
      setState(() {
        _errorMessage = 'System is locked due to too many failed attempts';
      });
      soundService.playSound(SoundType.error);
      return;
    }
    
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });
    
    final success = await authService.authenticateWithPin(_pinController.text);
    
    if (success) {
      soundService.playSound(SoundType.success);
      _pinController.clear();
      // Navigate to product screen
      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const ProductScreen())
        );
      }
    } else {
      soundService.playSound(SoundType.error);
      
      // Clear PIN input on failed attempt
      _pinController.clear();
      
      setState(() {
        _isAuthenticating = false;
        if (authService.isLockedOut) {
          _errorMessage = 'Too many failed attempts. System locked.';
        } else {
          _errorMessage = 'Invalid PIN. ${authService.remainingAttempts} attempts remaining.';
        }
      });
      
      // Clear error message after 3 seconds
      _errorTimer?.cancel();
      _errorTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
    }
  }

  void _onRfidScanned(String cardId) async {
    final authService = Provider.of<AuthenticationService>(context, listen: false);
    final soundService = Provider.of<SoundService>(context, listen: false);
    
    // Reset screensaver timer on card activity
    if (context.mounted) {
      final overlay = context.findAncestorStateOfType<ScreensaverOverlayState>();
      overlay?.resetInactivityTimer();
    }
    
    if (authService.isLockedOut) {
      setState(() {
        _errorMessage = 'System is locked due to too many failed attempts';
      });
      soundService.playSound(SoundType.error);
      return;
    }
    
    soundService.playSound(SoundType.cardScan);
    
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });
    
    final success = await authService.authenticateWithRfid(cardId);
    
    if (success) {
      soundService.playSound(SoundType.success);
      // Navigate to product screen
      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const ProductScreen())
        );
      }
    } else {
      soundService.playSound(SoundType.error);
      
      // Show access denied animation
      _rfidScannerKey.currentState?.showAccessDenied();
      
      setState(() {
        _isAuthenticating = false;
        if (authService.isLockedOut) {
          _errorMessage = 'Too many failed attempts. System locked.';
        } else {
          _errorMessage = 'Invalid card. ${authService.remainingAttempts} attempts remaining.';
        }
      });
      
      // Clear error message after 3 seconds
      _errorTimer?.cancel();
      _errorTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthenticationService>(context);
    final soundService = Provider.of<SoundService>(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxHeight < 600;
          return ScreensaverOverlay(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                child: Column(
                  children: [
                    SizedBox(height: isSmallScreen ? 8 : 16),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey[400],
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.pink,
                        ),
                        tabs: const [
                          Tab(text: 'PIN'),
                          Tab(text: 'RFID'),
                        ],
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 8 : 16),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // PIN Tab
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: isSmallScreen ? 200 : 280,
                                    height: isSmallScreen ? 280 : 380,
                                    child: PinKeypad(
                                      onKeyPress: (key) {
                                        if (authService.isLockedOut) return;
                                        
                                        if (key == 'clear') {
                                          _pinController.clear();
                                        } else if (key == 'backspace') {
                                          final text = _pinController.text;
                                          if (text.isNotEmpty) {
                                            _pinController.text = text.substring(0, text.length - 1);
                                          }
                                        } else if (key == 'enter') {
                                          _handlePinSubmit();
                                        } else {
                                          if (_pinController.text.length < 4) {
                                            _pinController.text += key;
                                          }
                                        }
                                      },
                                      disabled: _isAuthenticating || authService.isLockedOut,
                                      buttonSize: isSmallScreen ? 50 : 70,
                                    ),
                                  ),
                                  SizedBox(width: isSmallScreen ? 16 : 24),
                                  Container(
                                    width: isSmallScreen ? 120 : 160,
                                    height: isSmallScreen ? 280 : 380,
                                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          height: isSmallScreen ? 120 : 180,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade900.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: _pinController.text.isEmpty
                                              ? Text(
                                                  'Enter PIN',
                                                  style: TextStyle(
                                                    fontSize: isSmallScreen ? 14 : 18, 
                                                    color: Colors.grey,
                                                  ),
                                                )
                                              : Text(
                                                  '●' * _pinController.text.length,
                                                  style: TextStyle(
                                                    fontSize: isSmallScreen ? 24 : 32,
                                                    letterSpacing: isSmallScreen ? 8 : 12,
                                                    color: const Color(0xFFF48FB1),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          // RFID Tab
                          Center(
                            child: Container(
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                              width: isSmallScreen ? 200 : 300,
                              height: isSmallScreen ? 200 : 300,
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFF48FB1)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/scan-card.png',
                                        width: isSmallScreen ? 100 : 150,
                                        height: isSmallScreen ? 100 : 150,
                                      ),
                                      Container(
                                        width: isSmallScreen ? 120 : 180,
                                        height: isSmallScreen ? 120 : 180,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFFF48FB1).withOpacity(0.1),
                                        ),
                                        child: PulseAnimation(
                                          child: Container(
                                            margin: const EdgeInsets.all(20),
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFFF48FB1),
                                            ),
                                            child: Icon(
                                              Icons.nfc,
                                              size: isSmallScreen ? 40 : 60,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isSmallScreen ? 8 : 16),
                                  Text(
                                    'Tap your card',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 20,
                                      color: const Color(0xFFF48FB1),
                                    ),
                                  ),
                                  RfidScanner(
                                    key: _rfidScannerKey,
                                    onCardScanned: _onRfidScanned,
                                    isLocked: authService.isLockedOut,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      SizedBox(height: isSmallScreen ? 8 : 16),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 12 : 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    if (authService.isLockedOut) ...[
                      SizedBox(height: isSmallScreen ? 8 : 16),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'System is locked for 60 seconds due to too many failed attempts',
                          style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 12 : 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    SizedBox(height: isSmallScreen ? 8 : 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PulseAnimation extends StatefulWidget {
  final Widget child;
  
  const PulseAnimation({super.key, required this.child});
  
  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
