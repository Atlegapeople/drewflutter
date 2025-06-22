import 'package:flutter/material.dart';
import '../services/inventory_service.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final Function(ProductType) onSelectProduct;

  const ProductCard({
    super.key,
    required this.product,
    required this.onSelectProduct,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.product.stock > 0) {
      _controller.forward().then((_) {
        _controller.reverse();
        widget.onSelectProduct(widget.product.type);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock = widget.product.stock <= 0;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 220,
      height: 220,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: MouseRegion(
              onEnter: (_) {
                if (!isOutOfStock) {
                  setState(() => _isHovering = true);
                  _controller.forward();
                }
              },
              onExit: (_) {
                setState(() => _isHovering = false);
                _controller.reverse();
              },
              child: Card(
                elevation: _isHovering ? 12 : 6,
                clipBehavior: Clip.antiAlias,
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isOutOfStock
                        ? Colors.grey.shade800
                        : _isHovering
                            ? colorScheme.primary
                            : colorScheme.primary.withOpacity(0.5),
                    width: _isHovering ? 2.0 : 1.5,
                  ),
                ),
                child: InkWell(
                  onTap: _handleTap,
                  child: Opacity(
                    opacity: isOutOfStock ? 0.6 : 1.0,
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Fixed-size image
                          SizedBox(
                            height: 120,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: child,
                                );
                              },
                              child: _buildProductImage(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Product name
                          Text(
                            widget.product.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Product description
                          Text(
                            widget.product.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          // Availability badge
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(top: 4.0),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isOutOfStock
                                  ? Colors.red.shade900.withOpacity(0.7)
                                  : widget.product.stock < 10
                                      ? Colors.orange.shade900.withOpacity(0.7)
                                      : Colors.green.shade900.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _isHovering
                                  ? [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
                                  : null,
                            ),
                            child: Text(
                              isOutOfStock
                                  ? 'OUT OF STOCK'
                                  : 'Available: ${widget.product.stock}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          // Tap instruction
                          if (_isHovering && !isOutOfStock)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                'Tap to dispense',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductImage() {
    String imagePath;
    switch (widget.product.type) {
      case ProductType.tampon:
        imagePath = 'assets/images/tampon.png';
        break;
      case ProductType.pad:
        imagePath = 'assets/images/pad.png';
        break;
      default:
        imagePath = 'assets/images/pad.png';
    }

    return AnimatedRotation(
      turns: _isHovering ? 0.02 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedScale(
        scale: _isHovering ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          height: 100,
          width: 100,
        ),
      ),
    );
  }
}
