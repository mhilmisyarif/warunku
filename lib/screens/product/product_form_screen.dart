import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../blocs/product/product_bloc.dart';
import '../../config/api_constants.dart';
import '../../models/product.dart';
import '../../utils/formatter.dart';
import '../../utils/theme.dart';
import '../../widgets/error_view.dart';

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
  final List<_UnitFields> _units = [];

  File? _selectedImage;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descController.text = widget.product!.description;
      _categoryController.text = widget.product!.category;
      _units.addAll(widget.product!.units.map(_UnitFields.new));
    } else {
      _units.add(_UnitFields());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    for (final unit in _units) {
      unit.dispose();
    }
    super.dispose();
  }

  void _addUnitField() => setState(() => _units.add(_UnitFields()));

  void _removeUnitField(int index) {
    setState(() => _units.removeAt(index).dispose());
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final product = Product(
      id: widget.product?.id ?? '',
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      category: _categoryController.text.trim(),
      units: [for (final unit in _units) unit.toUnit()],
      imagePath: widget.product?.imagePath ?? '',
    );
    context.read<ProductBloc>().add(
      SaveProduct(product, imageFilePath: _selectedImage?.path),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existingImageUrl = ApiConstants.imageUrl(
      widget.product?.imagePath ?? '',
    );
    final ImageProvider? preview =
        _selectedImage != null
            ? FileImage(_selectedImage!)
            : existingImageUrl != null
            ? NetworkImage(existingImageUrl)
            : null;

    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Ubah Produk' : 'Produk Baru')),
      bottomNavigationBar: BottomActionBar(
        child: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            final saving = state is ProductSaving;
            return FilledButton.icon(
              onPressed: saving ? null : _submitForm,
              icon:
                  saving
                      ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.check),
              label: Text(_isEditing ? 'Simpan Perubahan' : 'Tambah Produk'),
            );
          },
        ),
      ),
      body: BlocListener<ProductBloc, ProductState>(
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state is ProductOperationSuccess) {
            showResultSnackBar(messenger, state.message);
            Navigator.of(context).pop(true);
          } else if (state is ProductOperationFailure) {
            showResultSnackBar(messenger, state.message, success: false);
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: <Widget>[
              // --- Image Picker ---
              Material(
                color: scheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _pickImage,
                  child: Ink(
                    height: 170,
                    decoration: BoxDecoration(
                      image:
                          preview != null
                              ? DecorationImage(
                                image: preview,
                                fit: BoxFit.cover,
                              )
                              : null,
                    ),
                    child:
                        preview == null
                            ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 36,
                                  color: scheme.primary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tambah foto produk',
                                  style: TextStyle(color: scheme.primary),
                                ),
                              ],
                            )
                            : const Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: EdgeInsets.all(10),
                                child: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: Icon(Icons.edit_outlined),
                                ),
                              ),
                            ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama produk*'),
                validator:
                    (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Nama wajib diisi'
                            : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _categoryController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Kategori*',
                  hintText: 'mis. Makanan, Minuman, Camilan',
                ),
                validator:
                    (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Kategori wajib diisi'
                            : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              // --- Units Section ---
              Row(
                children: [
                  Expanded(
                    child: Text('Satuan & harga', style: textTheme.titleLarge),
                  ),
                  TextButton.icon(
                    onPressed: _addUnitField,
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Satuan'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (_units.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Tambahkan minimal satu satuan.',
                    style: TextStyle(color: AppTheme.warning),
                  ),
                ),
              for (final (i, unit) in _units.indexed)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 4, 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: unit.label,
                                      decoration: const InputDecoration(
                                        labelText: 'Satuan*',
                                        hintText: 'kg, pcs',
                                      ),
                                      validator:
                                          (v) =>
                                              (v == null || v.trim().isEmpty)
                                                  ? 'Wajib'
                                                  : null,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: unit.sellingPrice,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Harga jual*',
                                        prefixText: 'Rp ',
                                      ),
                                      validator: (v) {
                                        final price = double.tryParse(
                                          v?.trim() ?? '',
                                        );
                                        return (price == null || price <= 0)
                                            ? 'Harga tidak valid'
                                            : null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: unit.stock,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: const InputDecoration(
                                        labelText: 'Stok',
                                        hintText: 'Kosong = tak dihitung',
                                      ),
                                      validator: _optionalNonNegative,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: unit.purchasePrice,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Harga modal',
                                        prefixText: 'Rp ',
                                      ),
                                      validator: _optionalNonNegative,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                        if (_units.length > 1)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppTheme.danger,
                            ),
                            tooltip: 'Hapus Satuan',
                            onPressed: () => _removeUnitField(i),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _optionalNonNegative(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final number = double.tryParse(text);
  return (number == null || number < 0) ? 'Tidak valid' : null;
}

/// Text fields for one unit of the product being edited.
class _UnitFields {
  _UnitFields([ProductUnit? unit])
    : label = TextEditingController(text: unit?.label),
      sellingPrice = TextEditingController(text: _text(unit?.sellingPrice)),
      purchasePrice = TextEditingController(text: _text(unit?.purchasePrice)),
      stock = TextEditingController(text: _text(unit?.stock));

  static String? _text(double? value) =>
      value == null ? null : formatQuantity(value);

  final TextEditingController label;
  final TextEditingController sellingPrice;
  final TextEditingController purchasePrice;
  final TextEditingController stock;

  /// Empty optional fields become null (cost unknown / stock not tracked).
  ProductUnit toUnit() => ProductUnit(
    label: label.text.trim(),
    sellingPrice: double.parse(sellingPrice.text.trim()),
    purchasePrice: double.tryParse(purchasePrice.text.trim()),
    stock: double.tryParse(stock.text.trim()),
  );

  void dispose() {
    label.dispose();
    sellingPrice.dispose();
    purchasePrice.dispose();
    stock.dispose();
  }
}
