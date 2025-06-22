import 'package:flutter/material.dart';
import '../services/authentication_service.dart';
import '../services/sound_service.dart';
import 'rfid_scanner.dart';

class CardRegistrationDialog extends StatefulWidget {
  final AuthenticationService authService;
  final SoundService soundService;

  const CardRegistrationDialog({
    super.key,
    required this.authService,
    required this.soundService,
  });

  @override
  State<CardRegistrationDialog> createState() => _CardRegistrationDialogState();
}

class _CardRegistrationDialogState extends State<CardRegistrationDialog> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedRole = 'user';
  String? _scannedCardUid;
  bool _isScanning = true;
  bool _isRegistering = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onCardScanned(String cardUid) {
    setState(() {
      _scannedCardUid = cardUid;
      _isScanning = false;
    });
    widget.soundService.playSound(SoundType.success);
  }

  Future<void> _registerCard() async {
    if (_scannedCardUid == null || _nameController.text.trim().isEmpty) return;

    setState(() {
      _isRegistering = true;
    });

    final success = await widget.authService.registerCard(
      _scannedCardUid!,
      _selectedRole,
      _nameController.text.trim(),
    );

    setState(() {
      _isRegistering = false;
    });

    if (success) {
      widget.soundService.playSound(SoundType.success);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Card registered successfully for ${_nameController.text.trim()}'),
        ),
      );
    } else {
      widget.soundService.playSound(SoundType.error);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to register card. It may already be registered.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetScanning() {
    setState(() {
      _scannedCardUid = null;
      _isScanning = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Dialog(
      child: Container(
        width: screenWidth * 0.8,
        height: screenHeight * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Register New Card',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {
                    widget.soundService.playSound(SoundType.buttonPress);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Step 1: Scan Card
            if (_isScanning) ...[
              const Text(
                'Step 1: Scan Card',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Please tap the card on the RFID scanner to register it.'),
              const SizedBox(height: 16),
              
              // Manual input option
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Or enter Card UID manually',
                        hintText: 'e.g., 955b3900',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          _onCardScanned(value.trim());
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Use your known card UID for testing
                      _onCardScanned('955b3900');
                    },
                    child: const Text('Use Test Card'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              Expanded(
                child: RfidScanner(
                  onCardScanned: _onCardScanned,
                  isLocked: false,
                ),
              ),
            ],

            // Step 2: Enter Details
            if (!_isScanning && _scannedCardUid != null) ...[
              const Text(
                'Step 2: Enter Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Card UID Display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('Card UID: $_scannedCardUid'),
                    const Spacer(),
                    TextButton(
                      onPressed: _resetScanning,
                      child: const Text('Scan Different Card'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // User Name Input
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'User Name',
                  hintText: 'Enter the user\'s name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),

              // Role Selection
              const Text(
                'User Role',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRole = value;
                    });
                  }
                },
              ),
              const Spacer(),

              // Register Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRegistering ||
                          _nameController.text.trim().isEmpty
                      ? null
                      : _registerCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isRegistering
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Register Card',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}