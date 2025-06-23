import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/authentication_service.dart';
import '../services/inventory_service.dart';
import '../services/sound_service.dart';
import '../services/dispense_service.dart';
import '../widgets/product_card.dart';
import '../widgets/dispensing_dialog.dart';
import 'lock_screen.dart';
import '../widgets/screensaver_overlay.dart';
import 'admin_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  bool _hasDispensed = false;
  int _remainingSeconds = 30;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _setupUserActivityListener();
    _startCountdown();
    _refreshInventory();
  }

  void _refreshInventory() async {
    final inventoryService = Provider.of<InventoryService>(context, listen: false);
    await inventoryService.refreshInventory();
  }

  void _setupUserActivityListener() {
    // Rely on widget interaction for activity detection
  }

  void _startCountdown() {
    _remainingSeconds = 30;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
        
        if (_remainingSeconds <= 0) {
          timer.cancel();
          _handleLogout();
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _resetCountdown() {
    if (mounted) {
      setState(() {
        _remainingSeconds = 30;
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _handleLogout() {
    final soundService = Provider.of<SoundService>(context, listen: false);
    soundService.playSound(SoundType.buttonPress);

    Provider.of<AuthenticationService>(context, listen: false).logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ScreensaverOverlay(child: LockScreen())),
    );
  }

  void _openAdminScreen() {
    final soundService = Provider.of<SoundService>(context, listen: false);
    soundService.playSound(SoundType.buttonPress);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthenticationService>(context);
    final inventoryService = Provider.of<InventoryService>(context);
    final soundService = Provider.of<SoundService>(context);
    final isAdmin = authService.currentUser == 'admin';

    void resetActivityTimer() {
      authService.resetSession();
      _resetCountdown();
    }

    // The dispensing dialog is now shown directly when a product is selected

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'D.R.E.W. Products',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Settings',
              onPressed: _openAdminScreen,
            ),
          IconButton(
            icon: Icon(
              soundService.soundEnabled ? Icons.volume_up : Icons.volume_off,
              color: soundService.soundEnabled
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            tooltip: 'Sound ${soundService.soundEnabled ? "On" : "Off"}',
            onPressed: () {
              soundService.toggleSound();
              if (soundService.soundEnabled) {
                soundService.playSound(SoundType.buttonPress);
              }
            },
          ),
          // Temporary debug sound test button
          IconButton(
            icon: const Icon(Icons.music_note),
            tooltip: 'Test Sound',
            onPressed: () {
              print('Testing sound from UI button...');
              soundService.testSound();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: resetActivityTimer,
        onPanDown: (_) => resetActivityTimer(),
        onVerticalDragStart: (_) => resetActivityTimer(),
        onHorizontalDragStart: (_) => resetActivityTimer(),
        behavior: HitTestBehavior.translucent,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF121212),
                Color(0xFF1E1E1E),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Logo and tagline section
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Dignity • Respect • Empowerment for Women',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Welcome, ${authService.currentUser.isNotEmpty ? authService.currentUser : 'User'}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3, // Reduced from 4 to 3 for bigger cards
                    childAspectRatio: 1.0, // Square cards
                    mainAxisSpacing: 30,
                    crossAxisSpacing: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                    children: inventoryService.products.map((product) {
                      return ProductCard(
                        product: product,
                        onSelectProduct: (productType) async {
                          soundService.playSound(SoundType.buttonPress);

                          // Check if user has already dispensed in this session
                          if (_hasDispensed) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Only one dispense allowed per session'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          if (!inventoryService.hasStock(productType)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('This product is out of stock'),
                              ),
                            );
                            return;
                          }

                          // Show dispensing dialog (which handles file-based dispensing)
                          final result = await showDialog<bool>(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => DispensingDialog(productType: productType),
                          );

                          // Update inventory if dispensing was successful
                          if (result == true) {
                            _hasDispensed = true;
                            
                            // Reduce stock count
                            final product = inventoryService.products.firstWhere(
                              (p) => p.type == productType,
                            );
                            if (product.stock > 0) {
                              // This is a simplified stock reduction - in a real app you'd have a proper method
                              // For now, we'll assume the dispensing was successful based on hardware feedback
                            }

                            // Auto-logout after successful dispense
                            Future.delayed(const Duration(seconds: 1), () {
                              if (mounted) {
                                _handleLogout();
                              }
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Auto-logout in ${_remainingSeconds}s - Tap screen to reset timer',
                    style: TextStyle(
                      color: _remainingSeconds <= 10 ? Colors.orange : Colors.grey, 
                      fontSize: 12,
                      fontWeight: _remainingSeconds <= 10 ? FontWeight.bold : FontWeight.normal,
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
