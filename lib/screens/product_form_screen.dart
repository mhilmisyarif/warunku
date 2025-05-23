import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({this.product, super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController();
  final List<TextEditingController> _unitLabelControllers = [];
  final List<TextEditingController> _unitPriceControllers = [];

  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descController.text = widget.product!.description;
      _categoryController.text = widget.product!.category;
      for (final unit in widget.product!.units) {
        _unitLabelControllers.add(TextEditingController(text: unit.label));
        _unitPriceControllers.add(
          TextEditingController(text: unit.sellingPrice.toString()),
        );
      }
      if (widget.product!.imagePath.isNotEmpty) {
        _selectedImage = File(
          widget.product!.imagePath,
        ); // optionally download file
      }
    } else {
      _addUnitField();
    }
  }

  void _addUnitField() {
    setState(() {
      _unitLabelControllers.add(TextEditingController());
      _unitPriceControllers.add(TextEditingController());
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    // Basic validation
    if (_nameController.text.trim().isEmpty ||
        _categoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all product details.')),
      );
      return;
    }

    for (int i = 0; i < _unitLabelControllers.length; i++) {
      final label = _unitLabelControllers[i].text.trim();
      final priceStr = _unitPriceControllers[i].text.trim();

      if (label.isEmpty || priceStr.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unit label and price cannot be empty.')),
        );
        return;
      }

      final price = double.tryParse(priceStr);
      if (price == null || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid price for unit $label')),
        );
        return;
      }
    }

    String imagePath = '';
    if (_selectedImage != null) {
      final uri = Uri.parse(
        'http://localhost:3000/upload',
      ); // replace with your IP when testing on device
      final request = http.MultipartRequest('POST', uri);

      final file = await http.MultipartFile.fromPath(
        'image',
        _selectedImage!.path,
        contentType: MediaType(
          'image',
          path.extension(_selectedImage!.path).replaceFirst('.', ''),
        ),
      );
      request.files.add(file);

      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = jsonDecode(respStr);
        imagePath = data['imagePath'];
      } else {
        print('Image upload failed');
      }
    }

    final units = List.generate(_unitLabelControllers.length, (i) {
      return ProductUnit(
        label: _unitLabelControllers[i].text,
        sellingPrice: double.parse(_unitPriceControllers[i].text),
      );
    });

    final product = Product(
      id: '',
      name: _nameController.text,
      description: _descController.text,
      category: _categoryController.text,
      units: units,
      imagePath: imagePath,
    );

    final response = await http.post(
      Uri.parse('http://localhost:3000/products'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context, true); // or show success feedback
    } else {
      print('Failed to save product');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null ? 'Edit Product' : 'Add Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: _descController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: _categoryController,
                decoration: InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 16),
              ...List.generate(_unitLabelControllers.length, (i) {
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _unitLabelControllers[i],
                        decoration: const InputDecoration(
                          labelText: 'Unit Label',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _unitPriceControllers[i],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Selling Price',
                        ),
                      ),
                    ),
                    if (i != 0) // only allow delete on additional units
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        tooltip: 'Remove',
                        onPressed: () {
                          setState(() {
                            _unitLabelControllers.removeAt(i);
                            _unitPriceControllers.removeAt(i);
                          });
                        },
                      ),
                  ],
                );
              }),
              TextButton.icon(
                onPressed: _addUnitField,
                icon: Icon(Icons.add),
                label: Text('Add Unit'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _selectedImage != null
                      ? Image.file(
                        _selectedImage!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      )
                      : Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: Icon(Icons.image, size: 40),
                      ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(Icons.upload),
                    label: Text('Select Image'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submitForm, child: Text('Submit')),
            ],
          ),
        ),
      ),
    );
  }
}
