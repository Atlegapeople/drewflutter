import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/inventory_service.dart';
import '../services/sound_service.dart';
import '../services/authentication_service.dart';
import '../services/database_service.dart';
import '../widgets/rfid_scanner.dart';
import '../widgets/card_registration_dialog.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryService = Provider.of<InventoryService>(context);
    final soundService = Provider.of<SoundService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Inventory', icon: Icon(Icons.inventory)),
            Tab(text: 'Cards', icon: Icon(Icons.credit_card)),
            Tab(text: 'Logs', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Inventory Tab
          _buildInventoryTab(inventoryService, soundService),
          
          // Card Management Tab
          _buildCardManagementTab(context),
          
          // Logs Tab
          _buildLogsTab(inventoryService),
        ],
      ),
    );
  }
  
  Widget _buildInventoryTab(InventoryService inventoryService, SoundService soundService) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inventory Management',
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: inventoryService.products.length,
              itemBuilder: (context, index) {
                final product = inventoryService.products[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Current Stock:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${product.stock} units',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: product.stock < 10 
                                        ? Colors.red 
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                _buildStockAdjustButton(
                                  icon: Icons.add_circle,
                                  onPressed: () {
                                    soundService.playSound(SoundType.buttonPress);
                                    inventoryService.restockProduct(product.type, 5);
                                  },
                                  tooltip: 'Add 5 units',
                                ),
                                const SizedBox(width: 8),
                                _buildStockAdjustButton(
                                  icon: Icons.remove_circle,
                                  onPressed: product.stock >= 5 ? () {
                                    soundService.playSound(SoundType.buttonPress);
                                    inventoryService.restockProduct(product.type, -5);
                                  } : null,
                                  tooltip: 'Remove 5 units',
                                ),
                                const SizedBox(width: 8),
                                _buildStockAdjustButton(
                                  icon: Icons.edit,
                                  onPressed: () {
                                    soundService.playSound(SoundType.buttonPress);
                                    _showStockEditDialog(context, product, inventoryService);
                                  },
                                  tooltip: 'Set stock level',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              soundService.playSound(SoundType.buttonPress);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset Inventory'),
                  content: const Text(
                    'Are you sure you want to reset all inventory levels to default?'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        soundService.playSound(SoundType.buttonPress);
                        Navigator.of(context).pop();
                      },
                      child: const Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () {
                        soundService.playSound(SoundType.success);
                        inventoryService.resetInventory();
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Inventory has been reset to default')),
                        );
                      },
                      child: const Text('RESET'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset to Default'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStockAdjustButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(12),
          minimumSize: Size.zero,
        ),
        child: Icon(icon),
      ),
    );
  }
  
  void _showStockEditDialog(
    BuildContext context,
    Product product,
    InventoryService inventoryService,
  ) {
    final TextEditingController controller = TextEditingController(
      text: product.stock.toString(),
    );
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set ${product.name} Stock'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Stock Quantity',
            ),
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                final newValue = int.tryParse(controller.text) ?? 0;
                if (newValue >= 0) {
                  inventoryService.setProductStock(product.type, newValue);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    ).then((_) => controller.dispose());
  }
  
  Widget _buildCardManagementTab(BuildContext context) {
    final authService = Provider.of<AuthenticationService>(context);
    final soundService = Provider.of<SoundService>(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RFID Card Management',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Register new card section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Register New Card',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      soundService.playSound(SoundType.buttonPress);
                      _showCardRegistrationDialog(context, authService, soundService);
                    },
                    icon: const Icon(Icons.add_card),
                    label: const Text('Register Card'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Registered cards list
          const Text(
            'Registered Cards',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: authService.getRegisteredCards(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No registered cards',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final card = snapshot.data![index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          card['user_role'] == 'admin' 
                            ? Icons.admin_panel_settings 
                            : Icons.person,
                          color: card['user_role'] == 'admin' 
                            ? Colors.orange 
                            : Colors.blue,
                        ),
                        title: Text(card['user_name'] ?? 'Unnamed User'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('UID: ${card['card_uid']}'),
                            Text('Role: ${card['user_role']}'),
                            Text('Registered: ${_formatDate(card['created_at'])}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            soundService.playSound(SoundType.buttonPress);
                            _showDeactivateCardDialog(
                              context, 
                              card['card_uid'], 
                              card['user_name'] ?? 'Unnamed User',
                              authService,
                              soundService,
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  void _showCardRegistrationDialog(
    BuildContext context,
    AuthenticationService authService,
    SoundService soundService,
  ) {
    showDialog(
      context: context,
      builder: (context) => CardRegistrationDialog(
        authService: authService,
        soundService: soundService,
      ),
    );
  }
  
  void _showDeactivateCardDialog(
    BuildContext context,
    String cardUid,
    String userName,
    AuthenticationService authService,
    SoundService soundService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Card'),
        content: Text('Are you sure you want to deactivate the card for $userName?\n\nUID: $cardUid'),
        actions: [
          TextButton(
            onPressed: () {
              soundService.playSound(SoundType.buttonPress);
              Navigator.of(context).pop();
            },
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              final success = await authService.deactivateCard(cardUid);
              if (success) {
                soundService.playSound(SoundType.success);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Card for $userName has been deactivated')),
                );
                setState(() {}); // Refresh the card list
              } else {
                soundService.playSound(SoundType.error);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to deactivate card')),
                );
              }
            },
            child: const Text('DEACTIVATE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsTab(InventoryService inventoryService) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Dispense Logs',
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Shows the 100 most recent dispense activities',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseService.getDispenseHistory(limit: 100),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading logs: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No dispense logs available yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                
                final logs = snapshot.data!;
                return ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          log['product_type'] == 'tampon' 
                            ? Icons.circle 
                            : Icons.crop_square,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          '${log['user_name']} dispensed ${log['product_type']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Time: ${_formatDate(log['dispensed_at'])}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            if (log['card_uid'] != null)
                              Text(
                                'Card: ${log['card_uid']}',
                                style: const TextStyle(color: Colors.white54),
                              ),
                          ],
                        ),
                        dense: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
