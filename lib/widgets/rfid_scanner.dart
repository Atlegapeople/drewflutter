import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'manual_card_scanner.dart';
import '../services/file_card_service.dart';

class RfidScanner extends StatefulWidget {
  final Function(String) onCardScanned;
  final bool isLocked;

  const RfidScanner({
    super.key,
    required this.onCardScanned,
    this.isLocked = false,
  });

  @override
  State<RfidScanner> createState() => RfidScannerState();
}

class RfidScannerState extends State<RfidScanner> {
  bool _isScanning = false;
  bool _showAccessDenied = false;
  FileCardService? _cardService;
  Timer? _accessDeniedTimer;

  @override
  void initState() {
    super.initState();
    _initializeCardService();
    _startScanning();
  }
  
  void _initializeCardService() {
    _cardService = Provider.of<FileCardService>(context, listen: false);
    _cardService?.startMonitoring(widget.onCardScanned);
  }


  void _startScanning() {
    if (!widget.isLocked) {
      setState(() {
        _isScanning = true;
      });
    }
  }

  @override
  void dispose() {
    _cardService?.stopMonitoring();
    _accessDeniedTimer?.cancel();
    super.dispose();
  }

  void showAccessDenied() {
    setState(() {
      _showAccessDenied = true;
    });
    
    _accessDeniedTimer?.cancel();
    _accessDeniedTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showAccessDenied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FileCardService>(
      builder: (context, cardService, child) {
        final isConnected = cardService.isConnected;
        final status = cardService.status;
        
        final borderColor = widget.isLocked
            ? Colors.grey.shade700
            : _isScanning && isConnected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth <= 800;
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final scannerSize = (maxWidth < maxHeight ? maxWidth : maxHeight) * (isSmallScreen ? 0.6 : 0.7);
        
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  
                  Flexible(
                    child: Container(
                      width: scannerSize,
                      height: scannerSize,
                      decoration: BoxDecoration(
                        color: widget.isLocked
                            ? Colors.grey.shade900
                            : _isScanning && isConnected
                                ? Colors.grey.shade800
                                : Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: widget.isLocked
                          ? Container(
                              width: scannerSize,
                              height: scannerSize,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                image: const DecorationImage(
                                  image: AssetImage('assets/images/locked.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          : _showAccessDenied
                              ? Container(
                                  width: scannerSize,
                                  height: scannerSize,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Lottie.asset(
                                      'assets/animations/denied - Animation - 1750594815870.json',
                                      fit: BoxFit.contain,
                                      repeat: false,
                                      animate: true,
                                    ),
                                  ),
                                )
                              : Stack(
                              alignment: Alignment.center,
                              children: [
                                // Background image
                                Container(
                                  width: scannerSize,
                                  height: scannerSize,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    image: const DecorationImage(
                                      image: AssetImage('assets/images/scan-card.png'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                // Overlay with animation and text
                                Container(
                                  width: scannerSize,
                                  height: scannerSize,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.black.withOpacity(0.3), // Subtle overlay
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SpinKitRipple(
                                        color: Theme.of(context).colorScheme.primary,
                                        size: scannerSize * 0.6,
                                      ),
                                      SizedBox(height: scannerSize * 0.05),
                                      Text(
                                        'Tap your card',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isSmallScreen ? 16 : scannerSize * 0.08,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              offset: const Offset(1, 1),
                                              blurRadius: 3,
                                              color: Colors.black.withOpacity(0.7),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 8 : 16),
                  if (widget.isLocked)
                    Text(
                      'Scanner is locked',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
      },
    );
  }
}
