import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HttpCardService {
  static const String baseUrl = 'http://127.0.0.1:8766';
  static Timer? _pollingTimer;
  static bool _isPolling = false;
  
  static Function(String)? _onCardScanned;
  
  static void startPolling(Function(String) onCardScanned) {
    _onCardScanned = onCardScanned;
    if (_isPolling) return;
    
    _isPolling = true;
    print("🔄 Starting HTTP card polling...");
    
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _pollForCard();
    });
  }
  
  static void stopPolling() {
    _isPolling = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    print("⏹️ Stopped HTTP card polling");
  }
  
  static Future<void> _pollForCard() async {
    if (!_isPolling) return;
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/poll'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 2));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'card_scanned' && data['card_uid'] != null) {
          final cardUid = data['card_uid'] as String;
          print("🧲 HTTP received card: $cardUid");
          _onCardScanned?.call(cardUid);
        }
      }
    } catch (e) {
      // Silently handle polling errors to avoid spam
      if (e.toString().contains('Connection refused')) {
        print("🔌 HTTP card server not available");
      }
    }
  }
  
  static Future<bool> checkServerStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/status'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ HTTP card server status: ${data['status']}");
        return data['status'] == 'running';
      }
    } catch (e) {
      print("❌ HTTP card server check failed: $e");
    }
    return false;
  }
  
  static Future<void> simulateCard() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/simulate'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        print("🧪 Card simulation requested");
      }
    } catch (e) {
      print("❌ Card simulation failed: $e");
    }
  }
}