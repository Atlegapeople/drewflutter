import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
  bool _isInitialized = false;
  bool _useSystemSounds = false;
  
  bool get soundEnabled => _soundEnabled;
  
  SoundService() {
    _initializeAudio();
    _loadSoundPreference();
  }
  
  Future<void> _initializeAudio() async {
    try {
      // Set audio context for desktop platforms
      if (!kIsWeb) {
        await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
      }
      _isInitialized = true;
      if (kDebugMode) {
        print('Audio player initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize audio player: $e');
      }
    }
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
    if (!_soundEnabled) {
      if (kDebugMode) {
        print('Sound is disabled, not playing $soundType');
      }
      return;
    }
    
    if (!_isInitialized) {
      if (kDebugMode) {
        print('Audio player not initialized, attempting to initialize...');
      }
      await _initializeAudio();
      if (!_isInitialized) {
        if (kDebugMode) {
          print('Failed to initialize audio player, cannot play sound');
        }
        return;
      }
    }
    
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
      if (kDebugMode) {
        print('Attempting to play sound: $soundAsset');
      }
      
      // Check if player is already playing something
      if (await _audioPlayer.getCurrentPosition() != null) {
        await _audioPlayer.stop();
      }
      
      // Set volume to maximum
      await _audioPlayer.setVolume(1.0);
      
      // Play the sound
      await _audioPlayer.play(AssetSource(soundAsset));
      
      if (kDebugMode) {
        print('Successfully started playing: $soundAsset');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing sound $soundAsset: $e');
        print('Falling back to system sounds...');
      }
      
      // Fallback to system sounds if audio files fail
      _useSystemSounds = true;
      await _playSystemSound(soundType);
    }
  }
  
  Future<void> _playSystemSound(SoundType soundType) async {
    try {
      SystemSoundType systemSound;
      switch (soundType) {
        case SoundType.buttonPress:
          systemSound = SystemSoundType.click;
          break;
        case SoundType.success:
          systemSound = SystemSoundType.alert;
          break;
        case SoundType.error:
          systemSound = SystemSoundType.alert;
          break;
        case SoundType.cardScan:
          systemSound = SystemSoundType.click;
          break;
        case SoundType.dispensing:
          systemSound = SystemSoundType.alert;
          break;
        case SoundType.dispensingComplete:
          systemSound = SystemSoundType.alert;
          break;
      }
      
      await SystemSound.play(systemSound);
      
      if (kDebugMode) {
        print('Played system sound: $systemSound');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing system sound: $e');
      }
    }
  }
  
  Future<void> testSound() async {
    if (kDebugMode) {
      print('Testing sound system...');
      print('Sound enabled: $_soundEnabled');
      print('Audio player initialized: $_isInitialized');
      print('Using system sounds: $_useSystemSounds');
    }
    
    // Test both audio file and system sound
    await playSound(SoundType.buttonPress);
    
    // Also test system sound directly
    await Future.delayed(const Duration(milliseconds: 500));
    await _playSystemSound(SoundType.success);
  }
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
