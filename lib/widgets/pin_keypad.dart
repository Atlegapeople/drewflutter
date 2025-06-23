import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sound_service.dart';

class PinKeypad extends StatelessWidget {
  final Function(String) onKeyPress;
  final bool disabled;

  const PinKeypad({
    super.key,
    required this.onKeyPress,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth <= 800;
    
    return AspectRatio(
      aspectRatio: isSmallScreen ? 4/3 : 3/4, // More compact for small screens
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: isSmallScreen ? 8 : 12, // Reduced spacing for 7"
        crossAxisSpacing: isSmallScreen ? 8 : 12,
        padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
        children: [
          // First row: 1, 2, 3
          _buildKeyButton(context, '1', null),
          _buildKeyButton(context, '2', null),
          _buildKeyButton(context, '3', null),
          // Second row: 4, 5, 6
          _buildKeyButton(context, '4', null),
          _buildKeyButton(context, '5', null),
          _buildKeyButton(context, '6', null),
          // Third row: 7, 8, 9
          _buildKeyButton(context, '7', null),
          _buildKeyButton(context, '8', null),
          _buildKeyButton(context, '9', null),
          // Fourth row: clear, 0, enter
          _buildKeyButton(context, 'clear', Icons.clear_all),
          _buildKeyButton(context, '0', null),
          _buildKeyButton(context, 'enter', Icons.check_circle_outline),
        ],
      ),
    );
  }
  
  Widget _buildKeyButton(BuildContext context, String value, IconData? icon) {
    final soundService = Provider.of<SoundService>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth <= 800;
    
    // Determine button styling based on button type
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
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 15),
        ),
        padding: EdgeInsets.zero,
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade900,
        disabledForegroundColor: Colors.grey.shade700,
        elevation: isSmallScreen ? 2 : 4,
      ),
      child: Center(
        child: icon != null
          ? Icon(icon, size: isSmallScreen ? 24 : 40, color: Colors.white) 
          : Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 24 : 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
      ),
    );
  }
}
