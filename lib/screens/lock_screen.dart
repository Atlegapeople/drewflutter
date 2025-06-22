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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        // Logo and status row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left spacer to center logo
                            const SizedBox(width: 100),
                            // Centered logo
                            Image.asset(
                              'assets/images/logo.png',
                              height: 30,
                              fit: BoxFit.contain,
                            ),
                            // System status on right
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'ONLINE',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Dignity • Respect • Empowerment for Women',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Auth card
                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          color: Colors.black.withOpacity(0.6),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Please authenticate to continue',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Tab Bar for PIN and RFID
                                TabBar(
                                  controller: _tabController,
                                  tabs: [
                                    Tab(
                                      icon: Icon(
                                        Icons.dialpad,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      text: 'PIN Code',
                                    ),
                                    Tab(
                                      icon: Icon(
                                        Icons.credit_card,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      text: 'RFID Card',
                                    ),
                                  ],
                                  labelColor: Theme.of(context).colorScheme.primary,
                                  unselectedLabelColor: Colors.grey,
                                  indicatorColor: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 16),
                                // Tab Content
                                SizedBox(
                                  height: 500, // Further increased height for tab content to fit larger keypad
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      // PIN Tab
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          // PIN input display
                                          Container(
                                            width: 200,
                                            height: 50,
                                            margin: const EdgeInsets.only(bottom: 16),
                                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade900,
                                              borderRadius: BorderRadius.circular(15),
                                              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), width: 1.5),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.3),
                                                  blurRadius: 5,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: _pinController.text.isEmpty
                                                ? const Text(
                                                    'Enter PIN',
                                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                                  )
                                                : Text(
                                                    '●' * _pinController.text.length,
                                                    style: TextStyle(fontSize: 28, letterSpacing: 12, color: Theme.of(context).colorScheme.primary),
                                                  ),
                                            ),
                                          ),
                                          // PIN keypad
                                          SizedBox(
                                            height: 380, // Further increased height for the larger keypad
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
                                                  // Only allow up to 4 digits
                                                  if (_pinController.text.length < 4) {
                                                    _pinController.text += key;
                                                  }
                                                }
                                              },
                                              disabled: _isAuthenticating || authService.isLockedOut,
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      // RFID Tab
                                      RfidScanner(
                                        key: _rfidScannerKey,
                                        onCardScanned: _onRfidScanned,
                                        isLocked: authService.isLockedOut,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                if (authService.isLockedOut) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'System is locked for 60 seconds due to too many failed attempts',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
