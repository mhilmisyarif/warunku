// lib/screens/product_form_screen.dart
import 'dart:io';
import 'dart:convert'; // Still needed for jsonEncode if you build product manually here

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart'; // For MediaType in image upload
import 'package:warunku/blocs/products/product_event.dart';
import 'package:warunku/blocs/products/product_state.dart';
// import 'package:http/http.dart' as http; // REMOVE direct http import for POST products

import '../../models/product.dart';
import '../../blocs/products/product_bloc.dart'; // Import ProductBloc
import '../../services/product_service.dart'; // For image upload, or move to BLoC too

class ProductFormScreen extends StatefulWidget {
  final Product? product; // For editing existing product

  const ProductFormScreen({this.product, super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController();
  final List<TextEditingController> _unitLabelControllers = [];
  final List<TextEditingController> _unitPriceControllers = [];

  File? _selectedImage;
  String? _uploadedImagePath; // To store path from image upload

  bool get _isEditing => widget.product != null;

  // ProductService can be used for image upload if not handled by BLoC
  // Or better, make image upload also part of an event/BLoC logic.
  // For now, let's keep it simple and use it directly here or assume it's part of ProductService.
  late ProductService _productService;

  @override
  void initState() {
    super.initState();
    _productService =
        ProductService(); // Instantiate here or get from context if provided higher

    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descController.text = widget.product!.description;
      _categoryController.text = widget.product!.category;
      _uploadedImagePath =
          widget.product!.imagePath; // Store existing image path

      for (final unit in widget.product!.units) {
        _unitLabelControllers.add(TextEditingController(text: unit.label));
        _unitPriceControllers.add(
          TextEditingController(text: unit.sellingPrice.toString()),
        );
      }
      // Note: Handling _selectedImage if editing an image is more complex.
      // Typically, you'd show the existing image (_uploadedImagePath) and allow replacing it.
    } else {
      _addUnitField(); // Start with one unit field for new products
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    for (var controller in _unitLabelControllers) {
      controller.dispose();
    }
    for (var controller in _unitPriceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addUnitField() {
    setState(() {
      _unitLabelControllers.add(TextEditingController());
      _unitPriceControllers.add(TextEditingController());
    });
  }

  void _removeUnitField(int index) {
    setState(() {
      _unitLabelControllers[index].dispose();
      _unitPriceControllers[index].dispose();
      _unitLabelControllers.removeAt(index);
      _unitPriceControllers.removeAt(index);
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75, // Adjust quality as needed
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _uploadedImagePath =
            null; // Clear previous uploaded path if a new image is selected
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form is not valid
    }

    // --- Start: Image Upload Logic (can also be moved to BLoC/Service more cleanly) ---
    String finalImagePath =
        _uploadedImagePath ?? ''; // Use existing path if not re-uploading

    if (_selectedImage != null) {
      // Show loading for image upload
      // This part could also be an event to a BLoC that handles file uploads
      // and returns the path, to keep UI cleaner.
      // For now, direct call to service:
      try {
        // Assuming ProductService has an uploadImage method
        // You might need to show a loading indicator specifically for image upload
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Uploading image...')));
        finalImagePath = await _productService.uploadProductImage(
          _selectedImage!.path,
        );
        setState(() {
          _uploadedImagePath = finalImagePath; // Store the new path
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return; // Stop submission if image upload fails
      }
    }
    // --- End: Image Upload Logic ---

    final List<ProductUnit> units = [];
    for (int i = 0; i < _unitLabelControllers.length; i++) {
      final label = _unitLabelControllers[i].text.trim();
      final priceStr = _unitPriceControllers[i].text.trim();
      if (label.isEmpty || priceStr.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unit label and price cannot be empty.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      final price = double.tryParse(priceStr);
      if (price == null || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid price for unit $label.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      units.add(ProductUnit(label: label, sellingPrice: price));
    }

    if (units.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one product unit.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final product = Product(
      // For new product, ID is generated by backend.
      // For existing product, use widget.product!.id
      id: widget.product?.id ?? '', // Pass existing ID if editing
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      category: _categoryController.text.trim(),
      units: units,
      imagePath: finalImagePath,
    );

    if (_isEditing) {
      context.read<ProductBloc>().add(
        UpdateProductEvent(widget.product!.id!, product),
      );
    } else {
      context.read<ProductBloc>().add(AddProductEvent(product));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add New Product'),
      ),
      body: BlocListener<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(
              context,
            ).pop(true); // Pop and return true to indicate success
          } else if (state is ProductError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              // Changed to ListView for better scrolling with dynamic items
              children: <Widget>[
                // --- Image Picker ---
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                        image:
                            _selectedImage != null
                                ? DecorationImage(
                                  image: FileImage(_selectedImage!),
                                  fit: BoxFit.cover,
                                )
                                : (_uploadedImagePath != null &&
                                        _uploadedImagePath!.isNotEmpty
                                    ? DecorationImage(
                                      // Use ApiConstants.baseUrl if imagePath is relative
                                      // For now, assuming _uploadedImagePath is a full URL or relative path handled by NetworkImage/Image.asset
                                      image: NetworkImage(
                                        _uploadedImagePath!.startsWith('http')
                                            ? _uploadedImagePath!
                                            : '${context.read<ProductService>().getProductImageBaseUrl()}${_uploadedImagePath!}', // Assuming ProductService has a method to get base image URL
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                    : null),
                      ),
                      child:
                          (_selectedImage == null &&
                                  (_uploadedImagePath == null ||
                                      _uploadedImagePath!.isEmpty))
                              ? const Center(
                                child: Icon(
                                  Icons.image_search,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              )
                              : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FloatingActionButton.small(
                        onPressed: _pickImage,
                        tooltip: 'Select Image',
                        child: const Icon(Icons.edit),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name*',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category*',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Category is required';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // --- Units Section ---
                Text(
                  'Product Units:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_unitLabelControllers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Please add at least one unit.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ListView.builder(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(), // To use inside another ListView
                  itemCount: _unitLabelControllers.length,
                  itemBuilder: (context, i) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _unitLabelControllers[i],
                                decoration: const InputDecoration(
                                  labelText: 'Unit Label* (e.g., kg, pcs)',
                                ),
                                validator:
                                    (v) =>
                                        (v == null || v.isEmpty)
                                            ? 'Required'
                                            : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _unitPriceControllers[i],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Selling Price*',
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  if (double.tryParse(v) == null ||
                                      double.parse(v) <= 0)
                                    return 'Invalid price';
                                  return null;
                                },
                              ),
                            ),
                            if (_unitLabelControllers.length >
                                1) // Show remove if more than one unit
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeUnitField(i),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _addUnitField,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Unit'),
                  ),
                ),
                const SizedBox(height: 32),

                BlocBuilder<ProductBloc, ProductState>(
                  builder: (context, state) {
                    if (state is ProductLoading && state.isOperating) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ElevatedButton.icon(
                      icon: Icon(
                        _isEditing ? Icons.save_alt : Icons.add_circle_outline,
                      ),
                      onPressed: _submitForm,
                      label: Text(
                        _isEditing ? 'Save Product Changes' : 'Add Product',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
