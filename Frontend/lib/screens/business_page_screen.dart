import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../theme/vyra_theme.dart';
import '../models/product_item.dart';
import '../services/api_service.dart';
import '../services/local_storage.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';

class BusinessPageScreen extends StatefulWidget {
  const BusinessPageScreen({super.key});

  @override
  State<BusinessPageScreen> createState() => _BusinessPageScreenState();
}

class _BusinessPageScreenState extends State<BusinessPageScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final LocalStorageService _storage = LocalStorageService();
  late TabController _tabController;
  
  List<ProductItem> _myProducts = [];
  bool _isLoading = true;
  String? _businessName;
  String? _businessDescription;
  String? _businessCategory;
  File? _businessLogo;
  bool _hasBusiness = false;
  
  late TextEditingController _businessNameController;
  late TextEditingController _businessDescriptionController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _businessNameController = TextEditingController();
    _businessDescriptionController = TextEditingController();
    _loadBusinessData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _apiService.getProfile();
      final username = profile.username;
      
      final products = await _apiService.getProducts(seller: username);
      
      if (profile.bio != null && profile.bio!.isNotEmpty) {
        final bio = profile.bio!;
        if (bio.contains('Business:')) {
          final lines = bio.split('\n');
          for (var line in lines) {
            if (line.startsWith('Business:')) {
              _businessName = line.replaceFirst('Business:', '').trim();
              _businessNameController.text = _businessName ?? '';
            } else if (line.startsWith('Description:')) {
              _businessDescription = line.replaceFirst('Description:', '').trim();
              _businessDescriptionController.text = _businessDescription ?? '';
            } else if (line.startsWith('Category:')) {
              _businessCategory = line.replaceFirst('Category:', '').trim();
            }
          }
          _hasBusiness = true;
        }
      }
      
      if (mounted) {
        setState(() {
          _myProducts = products;
          _hasBusiness = products.isNotEmpty || _hasBusiness;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading business data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VyRaTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                VyRaTheme.primaryBlack,
                VyRaTheme.darkGrey.withOpacity(0.5),
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  VyRaTheme.darkGrey,
                  VyRaTheme.darkGrey.withOpacity(0.7),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: VyRaTheme.primaryCyan.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: VyRaTheme.primaryCyan.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_rounded, color: VyRaTheme.textWhite, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    VyRaTheme.primaryCyan.withOpacity(0.3),
                    VyRaTheme.primaryCyan.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: VyRaTheme.primaryCyan,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'My Business',
              style: TextStyle(
                color: VyRaTheme.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  VyRaTheme.primaryCyan.withOpacity(0.3),
                  VyRaTheme.primaryCyan.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: VyRaTheme.primaryCyan.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.add_rounded, color: VyRaTheme.primaryCyan, size: 22),
              onPressed: () => _showAddProductDialog(),
              tooltip: 'Add Product',
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: VyRaTheme.primaryCyan,
          indicatorWeight: 3,
          labelColor: VyRaTheme.primaryCyan,
          unselectedLabelColor: VyRaTheme.textGrey,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.business_rounded, size: 20),
              text: 'Profile',
            ),
            Tab(
              icon: Icon(Icons.inventory_2_rounded, size: 20),
              text: 'Products',
            ),
            Tab(
              icon: Icon(Icons.rocket_launch_rounded, size: 20),
              text: 'Advertising',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          VyRaTheme.primaryCyan.withOpacity(0.3),
                          VyRaTheme.primaryCyan.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: const CircularProgressIndicator(
                      color: VyRaTheme.primaryCyan,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Loading your business...',
                    style: TextStyle(
                      color: VyRaTheme.textGrey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBusinessProfileTab(),
                _buildProductsTab(),
                _buildAdvertisingTab(),
              ],
            ),
    );
  }

  Widget _buildBusinessProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickBusinessLogo,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          VyRaTheme.primaryCyan.withOpacity(0.3),
                          VyRaTheme.primaryCyan.withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                        color: VyRaTheme.primaryCyan,
                        width: 3.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: VyRaTheme.primaryCyan.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: _businessLogo != null
                        ? ClipOval(
                            child: Image.file(
                              _businessLogo!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.store_rounded,
                                color: VyRaTheme.primaryCyan,
                                size: 50,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add Logo',
                                style: TextStyle(
                                  color: VyRaTheme.textGrey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        VyRaTheme.primaryCyan.withOpacity(0.2),
                        VyRaTheme.primaryCyan.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: VyRaTheme.primaryCyan.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.camera_alt_rounded,
                        color: VyRaTheme.primaryCyan,
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Tap to change',
                        style: TextStyle(
                          color: VyRaTheme.primaryCyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          _buildTextField(
            label: 'Business Name',
            hint: 'Enter your business name',
            controller: _businessNameController,
            onChanged: (value) => _businessName = value,
            icon: Icons.business_rounded,
          ),
          const SizedBox(height: 20),
          
          _buildCategoryDropdown(),
          const SizedBox(height: 20),
          
          _buildTextField(
            label: 'Business Description',
            hint: 'Tell customers about your business...',
            controller: _businessDescriptionController,
            onChanged: (value) => _businessDescription = value,
            icon: Icons.description_rounded,
            maxLines: 5,
          ),
          const SizedBox(height: 32),
          
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  VyRaTheme.primaryCyan,
                  VyRaTheme.primaryCyan.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: VyRaTheme.primaryCyan.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _saveBusinessProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: VyRaTheme.primaryBlack,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_rounded, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Save Business Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    if (_myProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    VyRaTheme.primaryCyan.withOpacity(0.2),
                    VyRaTheme.primaryCyan.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: VyRaTheme.primaryCyan,
                size: 70,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 28),
            const Text(
              'No products yet',
              style: TextStyle(
                color: VyRaTheme.textWhite,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Start selling by adding your first product',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: VyRaTheme.textGrey,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ).animate(delay: 300.ms).fadeIn(),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    VyRaTheme.primaryCyan,
                    VyRaTheme.primaryCyan.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: VyRaTheme.primaryCyan.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _showAddProductDialog(),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Add Product',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: VyRaTheme.primaryBlack,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ).animate(delay: 400.ms).fadeIn().scale(),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myProducts.length,
      itemBuilder: (context, index) {
        return _buildProductListItem(_myProducts[index], index);
      },
    );
  }

  Widget _buildProductListItem(ProductItem product, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VyRaTheme.darkGrey,
            VyRaTheme.darkGrey.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: VyRaTheme.primaryCyan.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: VyRaTheme.primaryCyan.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  VyRaTheme.mediumGrey,
                  VyRaTheme.mediumGrey.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: product.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_outlined,
                        color: VyRaTheme.textGrey,
                        size: 32,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.image_outlined,
                    color: VyRaTheme.textGrey,
                    size: 32,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: VyRaTheme.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        VyRaTheme.primaryCyan.withOpacity(0.3),
                        VyRaTheme.primaryCyan.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: VyRaTheme.primaryCyan,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: VyRaTheme.mediumGrey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.visibility_rounded, color: VyRaTheme.textGrey, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '${product.views}',
                            style: const TextStyle(
                              color: VyRaTheme.textGrey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (product.boostScore > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFFD700),
                              Color(0xFFFFA500),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.rocket_launch, color: Colors.black, size: 11),
                            const SizedBox(width: 4),
                            Text(
                              '${product.boostScore}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: VyRaTheme.mediumGrey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.more_vert_rounded,
                color: VyRaTheme.textWhite,
                size: 20,
              ),
            ),
            color: VyRaTheme.darkGrey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: VyRaTheme.primaryCyan.withOpacity(0.3),
                width: 1,
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: VyRaTheme.primaryCyan.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit_rounded, color: VyRaTheme.primaryCyan, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('Edit', style: TextStyle(color: VyRaTheme.textWhite)),
                  ],
                ),
                onTap: () => Future.delayed(
                  const Duration(milliseconds: 100),
                  () => _showEditProductDialog(product),
                ),
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_rounded, color: Colors.red, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
                onTap: () => Future.delayed(
                  const Duration(milliseconds: 100),
                  () => _deleteProduct(product.id),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.1, end: 0);
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    TextEditingController? controller,
    String? initialValue,
    required Function(String) onChanged,
    required IconData icon,
    int maxLines = 1,
  }) {
    final textController = controller ?? TextEditingController(text: initialValue);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    VyRaTheme.primaryCyan.withOpacity(0.3),
                    VyRaTheme.primaryCyan.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: VyRaTheme.primaryCyan, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: VyRaTheme.textWhite,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: VyRaTheme.primaryCyan.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: TextField(
            controller: textController,
            onChanged: onChanged,
            maxLines: maxLines,
            style: const TextStyle(
              color: VyRaTheme.textWhite,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: VyRaTheme.textGrey.withOpacity(0.6),
                fontSize: 14,
              ),
              filled: true,
              fillColor: VyRaTheme.darkGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: VyRaTheme.primaryCyan.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: VyRaTheme.primaryCyan.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: VyRaTheme.primaryCyan,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = [
      'Retail',
      'Food & Beverage',
      'Fashion',
      'Electronics',
      'Services',
      'Digital Products',
      'Art & Crafts',
      'Other',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    VyRaTheme.primaryCyan.withOpacity(0.3),
                    VyRaTheme.primaryCyan.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.category_rounded, color: VyRaTheme.primaryCyan, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Business Category',
              style: TextStyle(
                color: VyRaTheme.textWhite,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: VyRaTheme.darkGrey,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: VyRaTheme.primaryCyan.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: VyRaTheme.primaryCyan.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: _businessCategory,
            dropdownColor: VyRaTheme.darkGrey,
            style: const TextStyle(color: VyRaTheme.textWhite, fontSize: 14),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
            ),
            hint: Text(
              'Select category',
              style: TextStyle(
                color: VyRaTheme.textGrey.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: VyRaTheme.primaryCyan,
            ),
            items: categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _businessCategory = value);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _pickBusinessLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickMedia(
      imageQuality: 85,
    );
    if (pickedFile != null) {
      try {
        // Check if it's an image by checking mime type first, then file extension
        bool isImage = false;
        
        // Check mime type if available
        final mimeType = pickedFile.mimeType?.toLowerCase() ?? '';
        if (mimeType.startsWith('image/')) {
          isImage = true;
        } else {
          // Fallback to file extension check
          final fileName = pickedFile.name.toLowerCase();
          final imageExtensions = [
            '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', 
            '.heic', '.heif', '.tiff', '.tif', '.ico', '.svg',
            '.raw', '.cr2', '.nef', '.orf', '.sr2', '.dng'
          ];
          isImage = imageExtensions.any((ext) => fileName.endsWith(ext)) || 
                    fileName.contains('image') ||
                    fileName.isEmpty; // If no extension, assume it's valid from pickMedia
        }
        
        if (isImage || pickedFile.mimeType == null) {
          // Accept the image - pickMedia should only return images anyway
          setState(() {
            _businessLogo = File(pickedFile.path);
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a valid image file'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        // If there's any error, try to accept it anyway since pickMedia should filter
        debugPrint('Business logo picker error: $e');
        try {
          setState(() {
            _businessLogo = File(pickedFile.path);
          });
        } catch (fileError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading image: ${fileError.toString()}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _saveBusinessProfile() async {
    final businessName = _businessNameController.text.trim();
    if (businessName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a business name'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _businessName = businessName;
      _businessDescription = _businessDescriptionController.text.trim();
    });
    
    try {
      final businessInfo = StringBuffer();
      businessInfo.writeln('Business: $businessName');
      if (_businessDescription != null && _businessDescription!.isNotEmpty) {
        businessInfo.writeln('Description: $_businessDescription');
      }
      if (_businessCategory != null && _businessCategory!.isNotEmpty) {
        businessInfo.writeln('Category: $_businessCategory');
      }
      
      final updates = <String, dynamic>{
        'bio': businessInfo.toString(),
      };
      
      // Upload business logo if selected
      final success = await _apiService.updateProfile(
        updates,
        profileImage: _businessLogo,
      );
      
      if (mounted) {
        if (success) {
          // Clear business logo from local state if it was uploaded
          if (_businessLogo != null) {
            setState(() {
              _businessLogo = null; // Will use server image after reload
            });
          }
          
          setState(() {
            _hasBusiness = true;
            _isLoading = false;
          });
          
          await _loadBusinessData();
          
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _tabController.index != 0) {
                _tabController.animateTo(0);
              }
            });
            
            if (_tabController.index != 0) {
              _tabController.animateTo(0);
            }
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(child: Text('Business profile saved successfully!')),
                ],
              ),
              backgroundColor: VyRaTheme.primaryCyan,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save business profile'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving business profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAddProductDialog() {
    _showProductDialog();
  }

  void _showEditProductDialog(ProductItem product) {
    _showProductDialog(product: product);
  }

  void _showProductDialog({ProductItem? product}) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final descController = TextEditingController(text: product?.description ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    File? productImage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: VyRaTheme.darkGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: VyRaTheme.primaryCyan.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      VyRaTheme.primaryCyan.withOpacity(0.3),
                      VyRaTheme.primaryCyan.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  product == null ? Icons.add_shopping_cart_rounded : Icons.edit_rounded,
                  color: VyRaTheme.primaryCyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                product == null ? 'Add Product' : 'Edit Product',
                style: const TextStyle(
                  color: VyRaTheme.textWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickMedia(
                      imageQuality: 85,
                    );
                    if (pickedFile != null) {
                      try {
                        // Check if it's an image by checking mime type first, then file extension
                        bool isImage = false;
                        
                        // Check mime type if available
                        final mimeType = pickedFile.mimeType?.toLowerCase() ?? '';
                        if (mimeType.startsWith('image/')) {
                          isImage = true;
                        } else {
                          // Fallback to file extension check
                          final fileName = pickedFile.name.toLowerCase();
                          final imageExtensions = [
                            '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', 
                            '.heic', '.heif', '.tiff', '.tif', '.ico', '.svg',
                            '.raw', '.cr2', '.nef', '.orf', '.sr2', '.dng'
                          ];
                          isImage = imageExtensions.any((ext) => fileName.endsWith(ext)) || 
                                    fileName.contains('image') ||
                                    fileName.isEmpty; // If no extension, assume it's valid from pickMedia
                        }
                        
                        if (isImage || pickedFile.mimeType == null) {
                          // Accept the image - pickMedia should only return images anyway
                          setDialogState(() {
                            productImage = File(pickedFile.path);
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a valid image file'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        // If there's any error, try to accept it anyway since pickMedia should filter
                        debugPrint('Product image picker error: $e');
                        try {
                          setDialogState(() {
                            productImage = File(pickedFile.path);
                          });
                        } catch (fileError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error loading image: ${fileError.toString()}'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          VyRaTheme.mediumGrey,
                          VyRaTheme.mediumGrey.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: VyRaTheme.primaryCyan.withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: VyRaTheme.primaryCyan.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: productImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(productImage!, fit: BoxFit.cover),
                          )
                        : product?.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  product!.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.add_photo_alternate_rounded,
                                        color: VyRaTheme.textGrey,
                                        size: 40,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Add Photo',
                                        style: TextStyle(
                                          color: VyRaTheme.textGrey.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_photo_alternate_rounded,
                                    color: VyRaTheme.textGrey,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add Photo',
                                    style: TextStyle(
                                      color: VyRaTheme.textGrey.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: VyRaTheme.textWhite, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    labelStyle: const TextStyle(color: VyRaTheme.textGrey, fontSize: 14),
                    prefixIcon: const Icon(Icons.shopping_bag_rounded, color: VyRaTheme.primaryCyan, size: 20),
                    filled: true,
                    fillColor: VyRaTheme.primaryBlack,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: VyRaTheme.primaryCyan.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: VyRaTheme.primaryCyan.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: VyRaTheme.primaryCyan,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: VyRaTheme.textWhite, fontSize: 14),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: const TextStyle(color: VyRaTheme.textGrey, fontSize: 14),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 50),
                      child: Icon(Icons.description_rounded, color: VyRaTheme.primaryCyan, size: 20),
                    ),
                    filled: true,
                    fillColor: VyRaTheme.primaryBlack,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: VyRaTheme.primaryCyan.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: VyRaTheme.primaryCyan.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: VyRaTheme.primaryCyan,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  style: const TextStyle(color: VyRaTheme.textWhite, fontSize: 14),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Price (\$)',
                    labelStyle: const TextStyle(color: VyRaTheme.textGrey, fontSize: 14),
                    prefixIcon: const Icon(Icons.attach_money_rounded, color: VyRaTheme.primaryCyan, size: 20),
                    filled: true,
                    fillColor: VyRaTheme.primaryBlack,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: VyRaTheme.primaryCyan.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: VyRaTheme.primaryCyan.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: VyRaTheme.primaryCyan,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: VyRaTheme.textGrey,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    VyRaTheme.primaryCyan,
                    VyRaTheme.primaryCyan.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: VyRaTheme.primaryCyan.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty || priceController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all required fields'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  final price = double.tryParse(priceController.text);
                  if (price == null || price <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid price'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Saving product...'),
                        backgroundColor: VyRaTheme.primaryCyan,
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }

                  try {
                    if (product == null) {
                      final createdProduct = await _apiService.createProduct(
                        name: nameController.text.trim(),
                        description: descController.text.trim(),
                        price: price,
                        imageFile: productImage,
                      );

                      if (mounted) {
                        if (createdProduct != null) {
                          _loadBusinessData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Colors.white),
                                  SizedBox(width: 10),
                                  Expanded(child: Text('Product added successfully!')),
                                ],
                              ),
                              backgroundColor: VyRaTheme.primaryCyan,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to add product'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    } else {
                      final updatedProduct = await _apiService.updateProduct(
                        product.id,
                        name: nameController.text.trim(),
                        description: descController.text.trim(),
                        price: price,
                        imageUrl: productImage != null ? null : product.imageUrl,
                      );

                      if (mounted) {
                        if (updatedProduct != null) {
                          _loadBusinessData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Colors.white),
                                  SizedBox(width: 10),
                                  Expanded(child: Text('Product updated successfully!')),
                                ],
                              ),
                              backgroundColor: VyRaTheme.primaryCyan,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to update product'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    }
                  } catch (e) {
                    debugPrint('Error saving product: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: VyRaTheme.primaryBlack,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  product == null ? 'Add' : 'Update',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProduct(String productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VyRaTheme.darkGrey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.red.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Product',
              style: TextStyle(
                color: VyRaTheme.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this product? This action cannot be undone.',
          style: TextStyle(
            color: VyRaTheme.textGrey,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: VyRaTheme.textGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await _apiService.deleteProduct(productId);
        if (mounted) {
          if (success) {
            _loadBusinessData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(child: Text('Product deleted successfully')),
                  ],
                ),
                backgroundColor: VyRaTheme.primaryCyan,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete product'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error deleting product: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _buildAdvertisingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFD700),
                      Color(0xFFFFA500),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: Colors.black,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Advertising Tools',
                      style: TextStyle(
                        color: VyRaTheme.textWhite,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Boost your products and reach more customers',
                      style: TextStyle(
                        color: VyRaTheme.textGrey,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  VyRaTheme.darkGrey,
                  VyRaTheme.darkGrey.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: VyRaTheme.primaryCyan.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: VyRaTheme.primaryCyan.withOpacity(0.15),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFD700),
                            Color(0xFFFFA500),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.rocket_launch_rounded,
                        color: Colors.black,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Boost Products',
                            style: TextStyle(
                              color: VyRaTheme.textWhite,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Increase visibility with VyRa Points',
                            style: TextStyle(
                              color: VyRaTheme.textGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_myProducts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: VyRaTheme.mediumGrey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: VyRaTheme.textGrey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Add products first to boost them',
                        style: TextStyle(
                          color: VyRaTheme.textGrey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _myProducts.length,
                    itemBuilder: (context, index) {
                      final product = _myProducts[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              VyRaTheme.mediumGrey.withOpacity(0.4),
                              VyRaTheme.mediumGrey.withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: product.boostScore > 0
                                ? const Color(0xFFFFD700).withOpacity(0.5)
                                : VyRaTheme.primaryCyan.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: product.imageUrl != null
                                    ? Image.network(
                                        product.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: VyRaTheme.mediumGrey,
                                          child: const Icon(
                                            Icons.image_outlined,
                                            color: VyRaTheme.textGrey,
                                            size: 24,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: VyRaTheme.mediumGrey,
                                        child: const Icon(
                                          Icons.image_outlined,
                                          color: VyRaTheme.textGrey,
                                          size: 24,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      color: VyRaTheme.textWhite,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: product.boostScore > 0
                                          ? const LinearGradient(
                                              colors: [
                                                Color(0xFFFFD700),
                                                Color(0xFFFFA500),
                                              ],
                                            )
                                          : LinearGradient(
                                              colors: [
                                                VyRaTheme.textGrey.withOpacity(0.3),
                                                VyRaTheme.textGrey.withOpacity(0.2),
                                              ],
                                            ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.rocket_launch_rounded,
                                          color: product.boostScore > 0
                                              ? Colors.black
                                              : VyRaTheme.textGrey,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            'Boost: ${product.boostScore}',
                                            style: TextStyle(
                                              color: product.boostScore > 0
                                                  ? Colors.black
                                                  : VyRaTheme.textGrey,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD700),
                                    Color(0xFFFFA500),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700).withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  try {
                                    final result = await _apiService.boostProduct(product.id);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.rocket_launch_rounded, color: Colors.white),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  'Product boosted! ${result['remainingPoints'] ?? 0} points remaining',
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: VyRaTheme.primaryCyan,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      _loadBusinessData();
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.black,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    minimumSize: const Size(0, 40),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.rocket_launch_rounded, size: 14),
                                      SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Boost',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  VyRaTheme.darkGrey,
                  VyRaTheme.darkGrey.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: VyRaTheme.primaryCyan.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: VyRaTheme.primaryCyan.withOpacity(0.15),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            VyRaTheme.primaryCyan.withOpacity(0.3),
                            VyRaTheme.primaryCyan.withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: VyRaTheme.primaryCyan,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Business Analytics',
                            style: TextStyle(
                              color: VyRaTheme.textWhite,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Track your business performance',
                            style: TextStyle(
                              color: VyRaTheme.textGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _buildStatCard(
                      'Total Products',
                      '${_myProducts.length}',
                      Icons.inventory_2_rounded,
                      VyRaTheme.primaryCyan,
                    ),
                    _buildStatCard(
                      'Total Views',
                      '${_myProducts.fold<int>(0, (sum, p) => sum + p.views)}',
                      Icons.visibility_rounded,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Total Sales',
                      '${_myProducts.fold<int>(0, (sum, p) => sum + p.purchases)}',
                      Icons.shopping_cart_rounded,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Boost Score',
                      '${_myProducts.fold<int>(0, (sum, p) => sum + p.boostScore)}',
                      Icons.rocket_launch_rounded,
                      const Color(0xFFFFD700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VyRaTheme.mediumGrey.withOpacity(0.4),
            VyRaTheme.mediumGrey.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: VyRaTheme.textGrey,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}