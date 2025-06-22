import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SoundType {
  buttonPress,
  success,
  error,
  cardScan,
  dispensing,
  dispensingComplete
}

class SoundService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _soundEnabled = true;
  
  bool get soundEnabled => _soundEnabled;
  
  SoundService() {
    _loadSoundPreference();
  }
  
  Future<void> _loadSoundPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    notifyListeners();
  }
  
  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', _soundEnabled);
    
    notifyListeners();
  }
  
  Future<void> playSound(SoundType soundType) async {
    if (!_soundEnabled) return;
    
    String soundAsset;
    switch (soundType) {
      case SoundType.buttonPress:
        soundAsset = 'sounds/button_press.mp3';
        break;
      case SoundType.success:
        soundAsset = 'sounds/success.mp3';
        break;
      case SoundType.error:
        soundAsset = 'sounds/error.mp3';
        break;
      case SoundType.cardScan:
        soundAsset = 'sounds/card_scan.mp3';
        break;
      case SoundType.dispensing:
        soundAsset = 'sounds/dispensing.mp3';
        break;
      case SoundType.dispensingComplete:
        soundAsset = 'sounds/dispensing_complete.mp3';
        break;
    }
    
    try {
      await _audioPlayer.play(AssetSource(soundAsset));
    } catch (e) {
      if (kDebugMode) {
        print('Error playing sound: $e');
      }
    }
  }
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
