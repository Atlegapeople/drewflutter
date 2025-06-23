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
  static const String dispenseDir = 'dispense_commands';
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
      
      final success = await _createDispenseCommand(productType);
      
      if (success) {
        print("🎯 Dispense command created for ${productType.name}");
        
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

  /// Create a dispense command file
  Future<bool> _createDispenseCommand(ProductType productType) async {
    try {
      final dispenseDirObj = Directory(dispenseDir);
      if (!dispenseDirObj.existsSync()) {
        dispenseDirObj.createSync(recursive: true);
      }
      
      final commandId = DateTime.now().millisecondsSinceEpoch.toString();
      final filename = '$dispenseDir/dispense_$commandId.json';
      
      final commandData = {
        'command_id': commandId,
        'product_type': productType.name,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending'
      };
      
      final file = File(filename);
      
      // Write to temporary file first, then rename (atomic operation)
      final tempFile = File('$filename.tmp');
      await tempFile.writeAsString(jsonEncode(commandData));
      await tempFile.rename(filename);
      
      _lastDispenseId = commandId;
      
      print("📝 Created dispense command: $filename");
      return true;
      
    } catch (e) {
      print("❌ Failed to create dispense command: $e");
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

  /// Check if a dispense command was processed
  Future<bool> isCommandProcessed(String commandId) async {
    try {
      final filename = '$dispenseDir/dispense_$commandId.json';
      final file = File(filename);
      
      // File was deleted, meaning it was processed
      return !file.existsSync();
      
    } catch (e) {
      print("❌ Error checking command status: $e");
      return false;
    }
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

  /// Clean up old command files
  Future<void> cleanupOldCommands() async {
    try {
      final dispenseDirObj = Directory(dispenseDir);
      if (!dispenseDirObj.existsSync()) return;
      
      final now = DateTime.now();
      
      for (final file in dispenseDirObj.listSync().whereType<File>()) {
        if (file.path.contains('dispense_') && file.path.endsWith('.json')) {
          final stat = file.statSync();
          final age = now.difference(stat.modified);
          
          // Delete files older than 10 minutes
          if (age.inMinutes > 10) {
            await file.delete();
            print("🗑️ Cleaned up old dispense command: ${path.basename(file.path)}");
          }
        }
      }
      
    } catch (e) {
      print("❌ Error cleaning up commands: $e");
    }
  }

  @override
  void dispose() {
    _serialPort?.close();
    super.dispose();
  }
}