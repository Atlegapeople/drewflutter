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
  
  Widget _buildKeyButton(BuildContext context, String value, IconData? icon, double buttonSize) {
    final soundService = Provider.of<SoundService>(context, listen: false);
    
    Color backgroundColor;
    if (value == 'clear') {
      backgroundColor = Colors.orange.shade800;
    } else if (value == 'enter') {
      backgroundColor = Theme.of(context).colorScheme.primary;
    } else {
      backgroundColor = Colors.grey.shade800;
    }

    return ElevatedButton(
      onPressed: disabled
          ? null
          : () {
              soundService.playSound(SoundType.buttonPress);
              onKeyPress(value);
            },
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonSize / 4),
        ),
        padding: EdgeInsets.zero,
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade900,
        disabledForegroundColor: Colors.grey.shade700,
        elevation: 2,
        minimumSize: Size(buttonSize, buttonSize),
      ),
      child: Center(
        child: icon != null
          ? Icon(icon, size: buttonSize * 0.6, color: Colors.white) 
          : Text(
              value,
              style: TextStyle(
                fontSize: buttonSize * 0.6,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
      ),
    );
  }
}
