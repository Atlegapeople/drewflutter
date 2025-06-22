import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';

enum ProductType {
  tampon,
  pad
}

class Product {
  final ProductType type;
  final String name;
  final String description;
  final String imageAsset;
  int stock;

  Product({
    required this.type,
    required this.name,
    required this.description,
    required this.imageAsset,
    required this.stock,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'name': name,
      'description': description,
      'imageAsset': imageAsset,
      'stock': stock,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      type: ProductType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ProductType.tampon,
      ),
      name: json['name'],
      description: json['description'],
      imageAsset: json['imageAsset'],
      stock: json['stock'],
    );
  }
}

class DispensingStatus {
  bool isDispensing;
  ProductType? productType;
  int progress; // 0-100%
  bool isComplete;
  String? errorMessage;

  DispensingStatus({
    this.isDispensing = false,
    this.productType,
    this.progress = 0,
    this.isComplete = false,
    this.errorMessage,
  });
}

class InventoryService extends ChangeNotifier {
  final List<Product> _products = [];
  DispensingStatus _dispensingStatus = DispensingStatus();
  Timer? _dispensingTimer;
  
  List<Product> get products => List.unmodifiable(_products);
  DispensingStatus get dispensingStatus => _dispensingStatus;
  
  InventoryService() {
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    try {
      // Load stock from database
      final tamponStock = await DatabaseService.getStockCount('tampon');
      final padStock = await DatabaseService.getStockCount('pad');
      
      _products.clear();
      _products.addAll([
        Product(
          type: ProductType.tampon,
          name: 'Tampons',
          description: 'Regular absorbency',
          imageAsset: 'assets/images/tampon.png',
          stock: tamponStock,
        ),
        Product(
          type: ProductType.pad,
          name: 'Pads',
          description: 'Regular size',
          imageAsset: 'assets/images/pad.png',
          stock: padStock,
        ),
      ]);
    } catch (e) {
      // Fallback to default inventory if database fails
      _initializeDefaultInventory();
    }
    
    notifyListeners();
  }

  void _initializeDefaultInventory() {
    _products.clear();
    _products.addAll([
      Product(
        type: ProductType.tampon,
        name: 'Tampons',
        description: 'Regular absorbency',
        imageAsset: 'assets/images/tampon.png',
        stock: 50,
      ),
      Product(
        type: ProductType.pad,
        name: 'Pads',
        description: 'Regular size',
        imageAsset: 'assets/images/pad.png',
        stock: 50,
      ),
    ]);
  }

  Future<void> _saveInventory() async {
    // Save to database
    for (final product in _products) {
      final productType = product.type.toString().split('.').last;
      await DatabaseService.updateStockCount(productType, product.stock);
    }
  }

  Future<void> restockProduct(ProductType type, int quantity) async {
    final product = _findProductByType(type);
    if (product != null) {
      // Update database first
      final productTypeStr = type.toString().split('.').last;
      await DatabaseService.incrementStock(productTypeStr, quantity);
      
      // Update local cache
      product.stock += quantity;
      notifyListeners();
      
      // Log restock event
      await _logInventoryEvent('restock', type, quantity);
    }
  }
  
  Future<void> setProductStock(ProductType type, int newStockLevel) async {
    final product = _findProductByType(type);
    if (product != null) {
      // Update database first
      final productTypeStr = type.toString().split('.').last;
      await DatabaseService.updateStockCount(productTypeStr, newStockLevel);
      
      // Update local cache
      product.stock = newStockLevel;
      notifyListeners();
      
      // Log stock update event
      await _logInventoryEvent('set_stock', type, newStockLevel);
    }
  }

  Product? _findProductByType(ProductType type) {
    try {
      return _products.firstWhere((p) => p.type == type);
    } catch (e) {
      return null;
    }
  }

  int getStockLevel(ProductType type) {
    final product = _findProductByType(type);
    return product?.stock ?? 0;
  }

  bool hasStock(ProductType type) {
    return getStockLevel(type) > 0;
  }

  Future<bool> dispenseProduct(ProductType type, {String? userName, String? cardUid}) async {
    // Check if dispenser is already running
    if (_dispensingStatus.isDispensing) {
      return false;
    }
    
    // Check stock
    final product = _findProductByType(type);
    if (product == null || product.stock <= 0) {
      return false;
    }
    
    // Start dispensing process
    _dispensingStatus = DispensingStatus(
      isDispensing: true,
      productType: type,
      progress: 0,
      isComplete: false,
    );
    notifyListeners();
    
    // In a real app, we'd create a dispense request file here
    // for the hardware service to process. Instead we'll simulate dispensing
    await _simulateDispensingProcess(type, userName: userName, cardUid: cardUid);
    
    return true;
  }
  
  Future<void> _simulateDispensingProcess(ProductType type, {String? userName, String? cardUid}) async {
    // Simulate the dispensing process with progress updates
    const totalDurationMs = 5000; // 5 seconds to dispense
    const updateIntervalMs = 100; // Update progress every 100ms
    const steps = totalDurationMs ~/ updateIntervalMs;
    
    _dispensingTimer?.cancel();
    _dispensingTimer = Timer.periodic(const Duration(milliseconds: updateIntervalMs), (timer) {
      final currentStep = timer.tick;
      
      if (currentStep >= steps) {
        // Dispensing complete
        timer.cancel();
        _completeDispensing(type, userName: userName, cardUid: cardUid);
      } else {
        // Update progress
        _dispensingStatus.progress = ((currentStep / steps) * 100).round();
        notifyListeners();
      }
    });
  }
  
  Future<void> _completeDispensing(ProductType type, {String? userName, String? cardUid}) async {
    // Update dispensing status
    _dispensingStatus = DispensingStatus(
      isDispensing: false,
      productType: type,
      progress: 100,
      isComplete: true,
    );
    notifyListeners();
    
    // Decrement stock
    final product = _findProductByType(type);
    if (product != null) {
      product.stock--;
      
      // Update database
      final productType = type.toString().split('.').last;
      await DatabaseService.decrementStock(productType);
      
      // Log dispense event to database
      await DatabaseService.logDispense(
        userName ?? 'Unknown User',
        cardUid,
        productType,
      );
      
      // Log inventory event for backwards compatibility
      await _logInventoryEvent('dispense', type, 1);
    }
    
    // Reset dispensing status after a delay
    Timer(const Duration(seconds: 3), () {
      _dispensingStatus = DispensingStatus();
      notifyListeners();
    });
  }
  
  Future<void> _logInventoryEvent(String action, ProductType type, int quantity) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> logs = [];
    
    final logsJson = prefs.getString('inventory_logs');
    if (logsJson != null) {
      logs = List<Map<String, dynamic>>.from(jsonDecode(logsJson));
    }
    
    // Add new log entry
    logs.add({
      'timestamp': DateTime.now().toIso8601String(),
      'action': action,
      'productType': type.toString(),
      'quantity': quantity,
    });
    
    // Keep only last 100 logs to avoid excessive storage usage
    if (logs.length > 100) {
      logs = logs.sublist(logs.length - 100);
    }
    
    await prefs.setString('inventory_logs', jsonEncode(logs));
  }
  
  List<Map<String, String>> getInventoryLogs() {
    // In a real app, this would retrieve logs from the database
    // For now, we'll return a simulated list of recent logs
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final now = DateTime.now();
    
    return [
      {
        'timestamp': formatter.format(now.subtract(const Duration(hours: 2))),
        'message': 'Tampon dispensed. Remaining: ${getStockLevel(ProductType.tampon)}',
      },
      {
        'timestamp': formatter.format(now.subtract(const Duration(hours: 1))),
        'message': 'Pad dispensed. Remaining: ${getStockLevel(ProductType.pad)}',
      },
      {
        'timestamp': formatter.format(now.subtract(const Duration(minutes: 30))),
        'message': 'Tampon dispensed. Remaining: ${getStockLevel(ProductType.tampon)}',
      },
    ];
  }
  
  Future<void> refreshInventory() async {
    await _loadInventory();
  }

  Future<void> resetInventory() async {
    _initializeDefaultInventory();
    await _saveInventory(); // Save the reset values to database
    notifyListeners();
  }
  
  @override
  void dispose() {
    _dispensingTimer?.cancel();
    super.dispose();
  }
}
