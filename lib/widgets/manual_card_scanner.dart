import 'package:flutter/material.dart';

class ManualCardScanner extends StatefulWidget {
  final Function(String) onCardScanned;

  const ManualCardScanner({
    super.key,
    required this.onCardScanned,
  });

  @override
  State<ManualCardScanner> createState() => _ManualCardScannerState();
}

class _ManualCardScannerState extends State<ManualCardScanner> {
  final TextEditingController _cardController = TextEditingController();

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  void _simulateCardScan(String cardUid) {
    if (cardUid.isNotEmpty) {
      widget.onCardScanned(cardUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
        color: Colors.orange.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'WebSocket Debug Mode',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Manual Card Scanner (for testing when WebSocket is unavailable)',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cardController,
                  decoration: const InputDecoration(
                    labelText: 'Card UID',
                    hintText: 'Enter card UID (e.g., 955b3900)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: _simulateCardScan,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _simulateCardScan(_cardController.text.trim()),
                child: const Text('Scan'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Quick test buttons
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => _simulateCardScan('955b3900'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Your Card'),
              ),
              ElevatedButton(
                onPressed: () => _simulateCardScan('A955AF02'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Demo Admin'),
              ),
              ElevatedButton(
                onPressed: () => _simulateCardScan('B7621C45'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Demo User'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}