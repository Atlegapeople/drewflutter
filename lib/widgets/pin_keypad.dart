import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sound_service.dart';

class PinKeypad extends StatelessWidget {
  final Function(String) onKeyPress;
  final bool disabled;
  final double? buttonSize;

  const PinKeypad({
    super.key,
    required this.onKeyPress,
    this.disabled = false,
    this.buttonSize,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth <= 800;
    final effectiveButtonSize = buttonSize ?? (isSmallScreen ? 40 : 60);
    
    return AspectRatio(
      aspectRatio: isSmallScreen ? 4/3 : 3/4,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: isSmallScreen ? 8 : 12,
        crossAxisSpacing: isSmallScreen ? 8 : 12,
        padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
        children: [
          _buildKeyButton(context, '1', null, effectiveButtonSize),
          _buildKeyButton(context, '2', null, effectiveButtonSize),
          _buildKeyButton(context, '3', null, effectiveButtonSize),
          _buildKeyButton(context, '4', null, effectiveButtonSize),
          _buildKeyButton(context, '5', null, effectiveButtonSize),
          _buildKeyButton(context, '6', null, effectiveButtonSize),
          _buildKeyButton(context, '7', null, effectiveButtonSize),
          _buildKeyButton(context, '8', null, effectiveButtonSize),
          _buildKeyButton(context, '9', null, effectiveButtonSize),
          _buildKeyButton(context, 'clear', Icons.clear_all, effectiveButtonSize),
          _buildKeyButton(context, '0', null, effectiveButtonSize),
          _buildKeyButton(context, 'enter', Icons.check_circle_outline, effectiveButtonSize),
        ],
      ),
    );
  }
  
  Color _getButtonColor(String value) {
    if (value == 'clear') {
      return Colors.orange.shade800;
    } else if (value == 'enter') {
      return Theme.of(context).colorScheme.primary;
    } else {
      return Colors.grey.shade800;
    }
  }

  Widget _buildKeyButton(BuildContext context, String value, IconData? icon, double size) {
    final soundService = Provider.of<SoundService>(context, listen: false);
    
    return ElevatedButton(
      onPressed: disabled ? null : () {
        soundService.playSound(SoundType.buttonPress); // Play sound on press
        onKeyPress(value);
      },
      style: ElevatedButton.styleFrom(
        minimumSize: Size(size, size),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: _getButtonColor(value),
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade800,
      ),
      child: icon != null 
          ? Icon(icon, size: size * 0.5)
          : Text(
              value,
              style: TextStyle(
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
