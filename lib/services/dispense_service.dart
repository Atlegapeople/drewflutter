import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'inventory_service.dart';
import 'database_service.dart';

class DispenseService extends ChangeNotifier {
  static const String serialPortPath = '/dev/ttyUSB0';
  static const int baudRate = 9600;
  
  bool _isDispensing = false;
  String? _currentProduct;
  String? _lastDispenseId;
  SerialPort? _serialPort;

  // Getters
  bool get isDispensing => _isDispensing;
  String? get currentProduct => _currentProduct;
  String? get lastDispenseId => _lastDispenseId;

  /// Dispense a product
  Future<bool> dispenseProduct(ProductType productType, {String? userName, String? cardUid}) async {
    if (_isDispensing) {
      print("⚠️ Already dispensing, please wait");
      return false;
    }

    try {
      _setDispensing(true, productType.name);
      
      final success = await _sendSerialDispenseCommand(productType);
      
      if (success) {
        print("🎯 Serial dispense command sent for ${productType.name}");
        
        // Update database inventory and log dispense
        final productTypeStr = productType.toString().split('.').last;
        await DatabaseService.decrementStock(productTypeStr);
        await DatabaseService.logDispense(
          userName ?? 'Unknown User',
          cardUid,
          productTypeStr,
        );
        
        // Wait a moment for the command to be processed
        await Future.delayed(const Duration(milliseconds: 500));
        
        return true;
      } else {
        _setDispensing(false, null);
        return false;
      }
      
    } catch (e) {
      print("❌ Error dispensing ${productType.name}: $e");
      _setDispensing(false, null);
      return false;
    }
  }

  /// Send dispense command via serial port
  Future<bool> _sendSerialDispenseCommand(ProductType productType) async {
    try {
      _serialPort = SerialPort(serialPortPath);
      
      if (!_serialPort!.openReadWrite()) {
        print("❌ Failed to open serial port: ${SerialPort.lastError}");
        return false;
      }
      
      final config = SerialPortConfig();
      config.baudRate = baudRate;
      config.bits = 8;
      config.parity = SerialPortParity.none;
      config.stopBits = 1;
      config.setFlowControl(SerialPortFlowControl.none);
      
      _serialPort!.config = config;
      
      final commandId = DateTime.now().millisecondsSinceEpoch.toString();
      final command = '${productType.name}\n';
      
      final bytesWritten = _serialPort!.write(Uint8List.fromList(command.codeUnits));
      
      _serialPort!.close();
      _lastDispenseId = commandId;
      
      print("📡 Sent serial command: $command (${bytesWritten} bytes)");
      return bytesWritten > 0;
      
    } catch (e) {
      print("❌ Serial communication error: $e");
      _serialPort?.close();
      return false;
    }
  }

  /// Check if a dispense command was processed (simplified for serial)
  Future<bool> isCommandProcessed(String commandId) async {
    // For serial communication, assume command is processed immediately
    // In a real implementation, you might read response from serial port
    return true;
  }

  /// Wait for dispense completion and reset state
  Future<void> waitForCompletion() async {
    if (_lastDispenseId == null) return;
    
    // Wait up to 30 seconds for the command to be processed
    const maxWaitTime = Duration(seconds: 30);
    const checkInterval = Duration(milliseconds: 500);
    
    final startTime = DateTime.now();
    
    while (DateTime.now().difference(startTime) < maxWaitTime) {
      final processed = await isCommandProcessed(_lastDispenseId!);
      
      if (processed) {
        print("✅ Dispense command processed");
        break;
      }
      
      await Future.delayed(checkInterval);
    }
    
    // Reset dispensing state
    _setDispensing(false, null);
  }

  /// Set dispensing state and notify listeners
  void _setDispensing(bool dispensing, String? product) {
    _isDispensing = dispensing;
    _currentProduct = product;
    notifyListeners();
    
    if (dispensing) {
      print("🔄 Started dispensing: $product");
    } else {
      print("⏹️ Stopped dispensing");
    }
  }

  /// Simulate a dispense for testing
  Future<bool> simulateDispense(ProductType productType) async {
    print("🧪 Simulating dispense: ${productType.name}");
    
    _setDispensing(true, productType.name);
    
    // Simulate dispensing time
    await Future.delayed(const Duration(seconds: 2));
    
    _setDispensing(false, null);
    
    print("✅ Simulated dispense complete");
    return true;
  }

  /// Clean up old command files (no longer needed for serial)
  Future<void> cleanupOldCommands() async {
    // No cleanup needed for serial communication
    print("🧹 Serial communication doesn't require file cleanup");
  }

  @override
  void dispose() {
    _serialPort?.close();
    super.dispose();
  }
}