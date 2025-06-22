import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class AuthenticationService extends ChangeNotifier {
  bool _isAuthenticated = false;
  String _currentUser = '';
  Timer? _autoLogoutTimer;
  int _failedAttempts = 0;
  bool _isLockedOut = false;
  DateTime? _lockoutEndTime;
  final int _maxFailedAttempts = 3;
  final int _lockoutDurationSeconds = 60;

  bool get isAuthenticated => _isAuthenticated;
  String get currentUser => _currentUser;
  bool get isLockedOut => _isLockedOut;
  int get remainingAttempts => _maxFailedAttempts - _failedAttempts;
  
  // Demo users for testing - in real app would be in SQLite DB
  final Map<String, String> _demoUsers = {
    '9999': 'admin',   // Admin PIN
    '1234': 'user',    // User PIN
  };
  
  // Demo RFID cards - in real app would be in SQLite DB
  final Map<String, String> _demoRfidCards = {
    'A955AF02': 'admin',
    'B7621C45': 'user',
    '955b3900': 'admin',  // Your current card for testing
    '7a373b00': 'Thabo', // Thabo's card
  };

  AuthenticationService() {
    _checkLockoutStatus();
    _checkSavedSession();
  }

  Future<void> _checkLockoutStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutEndTimeStr = prefs.getString('lockout_end_time');
    final savedFailedAttempts = prefs.getInt('failed_attempts') ?? 0;
    
    if (lockoutEndTimeStr != null) {
      final lockoutEndTime = DateTime.parse(lockoutEndTimeStr);
      if (DateTime.now().isBefore(lockoutEndTime)) {
        _isLockedOut = true;
        _lockoutEndTime = lockoutEndTime;
        _failedAttempts = savedFailedAttempts;
        
        // Set timer to check when lockout ends
        final remainingSeconds = lockoutEndTime.difference(DateTime.now()).inSeconds;
        Timer(Duration(seconds: remainingSeconds + 1), () {
          _isLockedOut = false;
          _lockoutEndTime = null;
          _failedAttempts = 0;
          _saveLockoutData();
          notifyListeners();
        });
      } else {
        // Lockout period has already ended
        await prefs.remove('lockout_end_time');
        await prefs.remove('failed_attempts');
        _isLockedOut = false;
        _failedAttempts = 0;
      }
    }
  }
  
  Future<void> _saveLockoutData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_isLockedOut && _lockoutEndTime != null) {
      await prefs.setString('lockout_end_time', _lockoutEndTime!.toIso8601String());
      await prefs.setInt('failed_attempts', _failedAttempts);
    } else {
      await prefs.remove('lockout_end_time');
      await prefs.remove('failed_attempts');
    }
  }

  Future<void> _checkSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionData = prefs.getString('session');
    
    if (sessionData != null) {
      final session = jsonDecode(sessionData);
      final expiryTime = DateTime.parse(session['expiry']);
      
      if (DateTime.now().isBefore(expiryTime)) {
        _isAuthenticated = true;
        _currentUser = session['user'];
        _startAutoLogoutTimer(expiryTime);
        notifyListeners();
      } else {
        await prefs.remove('session');
      }
    }
  }

  void _startAutoLogoutTimer(DateTime expiryTime) {
    _autoLogoutTimer?.cancel();
    
    final remaining = expiryTime.difference(DateTime.now());
    _autoLogoutTimer = Timer(remaining, () {
      logout();
    });
  }

  Future<bool> authenticateWithPin(String pin) async {
    if (_isLockedOut) return false;
    
    // In a real app, we would check against hashed PINs in a database
    if (_demoUsers.containsKey(pin)) {
      _successfulAuthentication(_demoUsers[pin]!);
      return true;
    } else {
      _failedAuthentication();
      return false;
    }
  }
  
  Future<bool> authenticateWithRfid(String cardUid) async {
    if (_isLockedOut) return false;
    
    // Check database for registered card
    final cardData = await DatabaseService.getCardByUid(cardUid);
    if (cardData != null) {
      // Use user_name if available, otherwise fall back to user_role
      final userName = cardData['user_name'] ?? cardData['user_role'];
      _successfulAuthentication(userName);
      return true;
    }
    
    // Fallback to demo cards for backward compatibility
    if (_demoRfidCards.containsKey(cardUid)) {
      _successfulAuthentication(_demoRfidCards[cardUid]!);
      return true;
    }
    
    _failedAuthentication();
    return false;
  }
  
  Future<void> _successfulAuthentication(String user) async {
    _isAuthenticated = true;
    _currentUser = user;
    _failedAttempts = 0;
    
    // Create a session that expires after 30 seconds of inactivity
    final expiryTime = DateTime.now().add(const Duration(seconds: 30));
    
    // Save session to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session', jsonEncode({
      'user': user,
      'expiry': expiryTime.toIso8601String(),
    }));
    
    _startAutoLogoutTimer(expiryTime);
    await _saveLockoutData(); // Reset lockout data
    notifyListeners();
  }
  
  Future<void> _failedAuthentication() async {
    _failedAttempts++;
    
    if (_failedAttempts >= _maxFailedAttempts) {
      _isLockedOut = true;
      _lockoutEndTime = DateTime.now().add(Duration(seconds: _lockoutDurationSeconds));
      
      Timer(Duration(seconds: _lockoutDurationSeconds), () {
        _isLockedOut = false;
        _lockoutEndTime = null;
        _failedAttempts = 0;
        _saveLockoutData();
        notifyListeners();
      });
    }
    
    await _saveLockoutData();
    notifyListeners();
  }
  
  Future<void> resetSession() async {
    // Reset the session timer without logging out
    if (_isAuthenticated) {
      final expiryTime = DateTime.now().add(const Duration(seconds: 30));
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('session', jsonEncode({
        'user': _currentUser,
        'expiry': expiryTime.toIso8601String(),
      }));
      
      _startAutoLogoutTimer(expiryTime);
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _currentUser = '';
    _autoLogoutTimer?.cancel();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session');
    
    notifyListeners();
  }
  
  // Card registration methods
  Future<bool> registerCard(String cardUid, String userRole, String? userName) async {
    try {
      // Check if card already exists
      if (await DatabaseService.cardExists(cardUid)) {
        return false; // Card already registered
      }
      
      await DatabaseService.registerCard(cardUid, userRole, userName);
      return true;
    } catch (e) {
      print('Error registering card: $e');
      return false;
    }
  }
  
  Future<List<Map<String, dynamic>>> getRegisteredCards() async {
    return await DatabaseService.getAllCards();
  }
  
  Future<bool> deactivateCard(String cardUid) async {
    try {
      await DatabaseService.deactivateCard(cardUid);
      return true;
    } catch (e) {
      print('Error deactivating card: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _autoLogoutTimer?.cancel();
    super.dispose();
  }
}
