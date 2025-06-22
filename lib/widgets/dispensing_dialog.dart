import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lottie/lottie.dart';
import '../services/inventory_service.dart';
import '../services/sound_service.dart';
import '../services/dispense_service.dart';
import '../services/authentication_service.dart';

class DispensingDialog extends StatefulWidget {
  final ProductType productType;
  
  const DispensingDialog({
    super.key,
    required this.productType,
  });

  @override
  State<DispensingDialog> createState() => _DispensingDialogState();
}

class _DispensingDialogState extends State<DispensingDialog> {
  bool _isComplete = false;
  
  @override
  void initState() {
    super.initState();
    _startDispensing();
  }

  void _startDispensing() async {
    final dispenseService = Provider.of<DispenseService>(context, listen: false);
    final soundService = Provider.of<SoundService>(context, listen: false);
    final authService = Provider.of<AuthenticationService>(context, listen: false);
    
    // Start dispensing sound
    soundService.playSound(SoundType.dispensing);
    
    // Start the actual dispensing via file system with user tracking
    final success = await dispenseService.dispenseProduct(
      widget.productType,
      userName: authService.currentUser,
      cardUid: null, // Could track specific card if needed
    );
    
    if (success) {
      // Wait for hardware completion
      await dispenseService.waitForCompletion();
      
      // Update UI and play completion sound
      if (mounted) {
        setState(() {
          _isComplete = true;
        });
        
        soundService.playSound(SoundType.dispensingComplete);
        
        // Auto-close after 10 seconds and return success
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop(true); // Return success
          }
        });
      }
    } else {
      // Handle error
      if (mounted) {
        soundService.playSound(SoundType.error);
        Navigator.of(context).pop(false); // Return failure
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productName = widget.productType == ProductType.tampon ? 'Tampon' : 'Pad';
        
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: Container(
        width: 260,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            // Animation/Loading container
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _isComplete 
                    ? Lottie.asset(
                        'assets/animations/dispense - success -Animation - 1750619846326.json',
                        fit: BoxFit.contain,
                        repeat: false,
                        animate: true,
                        frameRate: FrameRate.max,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 40,
                          );
                        },
                      )
                    : SpinKitCubeGrid(
                        color: Theme.of(context).colorScheme.primary,
                        size: 40.0,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            // Loading text
            if (!_isComplete)
              Text(
                'Dispensing $productName...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            // Loading spinner
            if (!_isComplete) ...[
              const SizedBox(height: 16),
              SpinKitWave(
                color: Theme.of(context).colorScheme.primary,
                size: 30.0,
              ),
            ],
            // Collection instructions
            if (_isComplete) ...[
              Container(
                width: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.south,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'COLLECT ITEM',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Dispenser Below',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
      actions: _isComplete
          ? [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text('CLOSE'),
              ),
            ]
          : null,
    );
  }
}
