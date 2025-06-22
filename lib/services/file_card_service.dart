import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class FileCardService extends ChangeNotifier {
  static const String cardDir = 'card_scans';
  static const String statusFile = 'card_reader_status.json';
  
  Timer? _pollingTimer;
  bool _isPolling = false;
  String _status = 'disconnected';
  String _lastMessage = '';
  DateTime? _lastUpdate;
  
  Function(String)? _onCardScanned;
  Set<String> _processedScans = {};

  // Getters
  bool get isConnected => _status == 'running';
  String get status => _status;
  String get statusMessage => _lastMessage;
  DateTime? get lastUpdate => _lastUpdate;

  /// Start monitoring for card scans
  void startMonitoring(Function(String) onCardScanned) {
    _onCardScanned = onCardScanned;
    
    if (_isPolling) {
      print("⚠️ Already monitoring card scans");
      return;
    }
    
    _isPolling = true;
    
    // Check status every second, scan for cards every 50ms (more frequent)
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _checkForCardScans();
      
      // Check status less frequently
      if (timer.tick % 20 == 0) {
        _checkReaderStatus();
      }
    });
    
    // Initial status check
    _checkReaderStatus();
  }

  /// Stop monitoring
  void stopMonitoring() {
    _isPolling = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Check card reader status
  Future<void> _checkReaderStatus() async {
    try {
      final statusFileObj = File(statusFile);
      
      if (!statusFileObj.existsSync()) {
        _updateStatus('disconnected', 'Card reader not running');
        return;
      }
      
      final content = await statusFileObj.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      
      final newStatus = data['status'] as String? ?? 'unknown';
      final message = data['message'] as String? ?? '';
      final timestampStr = data['timestamp'] as String?;
      
      DateTime? timestamp;
      if (timestampStr != null) {
        try {
          timestamp = DateTime.parse(timestampStr);
        } catch (e) {
          print("⚠️ Invalid timestamp in status file: $timestampStr");
        }
      }
      
      // Check if status is stale (older than 10 seconds)
      if (timestamp != null) {
        final age = DateTime.now().difference(timestamp);
        if (age.inSeconds > 10) {
          _updateStatus('stale', 'Card reader status is stale (${age.inSeconds}s old)');
          return;
        }
      }
      
      _updateStatus(newStatus, message);
      _lastUpdate = timestamp;
      
    } catch (e) {
      _updateStatus('error', 'Failed to read status: $e');
    }
  }

  /// Check for new card scan files
  Future<void> _checkForCardScans() async {
    if (!_isPolling) return;
    
    try {
      final cardDirObj = Directory(cardDir);
      
      if (!cardDirObj.existsSync()) {
        return; // Directory doesn't exist yet
      }
      
      // Find all card scan files
      final files = cardDirObj
          .listSync()
          .whereType<File>()
          .where((file) => file.path.contains('card_') && file.path.endsWith('.json'))
          .toList();
      
      for (final file in files) {
        await _processCardScanFile(file);
      }
      
    } catch (e) {
      print("❌ Error checking for card scans: $e");
    }
  }

  /// Process a single card scan file
  Future<void> _processCardScanFile(File file) async {
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      
      final scanId = data['scan_id'] as String?;
      final cardUid = data['card_uid'] as String?;
      final status = data['status'] as String?;
      
      // Skip if we've already processed this scan
      if (scanId != null && _processedScans.contains(scanId)) {
        return;
      }
      
      // Validate data
      if (cardUid == null || cardUid.isEmpty) {
        print("⚠️ Invalid card scan data: missing card_uid");
        await _deleteFile(file);
        return;
      }
      
      if (status != 'new') {
        print("⚠️ Skipping processed card scan: $scanId");
        return;
      }
      
      // Mark as processed
      if (scanId != null) {
        _processedScans.add(scanId);
      }
      
      // Notify the callback
      print("🎫 Processing card scan: $cardUid (ID: $scanId)");
      _onCardScanned?.call(cardUid);
      
      // Delete the processed file
      await _deleteFile(file);
      print("🗑️ Deleted processed scan file: ${path.basename(file.path)}");
      
    } catch (e) {
      print("❌ Error processing card scan file ${file.path}: $e");
      // Delete corrupted files
      await _deleteFile(file);
    }
  }

  /// Safely delete a file
  Future<void> _deleteFile(File file) async {
    try {
      if (file.existsSync()) {
        await file.delete();
      }
    } catch (e) {
      print("❌ Failed to delete file ${file.path}: $e");
    }
  }

  /// Update status and notify listeners
  void _updateStatus(String newStatus, String message) {
    if (_status != newStatus || _lastMessage != message) {
      _status = newStatus;
      _lastMessage = message;
      notifyListeners();
    }
  }

  /// Simulate a card scan for testing
  Future<void> simulateCardScan(String cardUid) async {
    try {
      final cardDirObj = Directory(cardDir);
      if (!cardDirObj.existsSync()) {
        cardDirObj.createSync(recursive: true);
      }
      
      final scanId = DateTime.now().millisecondsSinceEpoch.toString();
      final filename = '$cardDir/card_$scanId.json';
      
      final cardData = {
        'card_uid': cardUid,
        'timestamp': DateTime.now().toIso8601String(),
        'scan_id': scanId,
        'status': 'new'
      };
      
      final file = File(filename);
      await file.writeAsString(jsonEncode(cardData));
      
    } catch (e) {
      print("❌ Failed to simulate card scan: $e");
    }
  }

  /// Clean up old processed scan IDs from memory
  void _cleanupProcessedScans() {
    if (_processedScans.length > 100) {
      // Keep only the most recent 50
      final recentScans = _processedScans.toList()..sort();
      _processedScans = recentScans.skip(50).toSet();
    }
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}