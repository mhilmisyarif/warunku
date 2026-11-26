import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/customer/customer_bloc.dart';
import '../../models/customer.dart';
import '../../widgets/error_view.dart';

class CustomerFormScreen extends StatefulWidget {
  /// Null to add a new customer, otherwise the customer being edited.
  final Customer? customer;

  const CustomerFormScreen({super.key, this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(
      text: widget.customer?.phoneNumber ?? '',
    );
    _addressController = TextEditingController(
      text: widget.customer?.address ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    context.read<CustomerBloc>().add(
      SaveCustomer(
        Customer(
          id: widget.customer?.id,
          name: _nameController.text.trim(),
          phoneNumber: phone.isEmpty ? null : phone,
          address: address.isEmpty ? null : address,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Ubah Pelanggan' : 'Pelanggan Baru'),
      ),
      bottomNavigationBar: BottomActionBar(
        child: BlocBuilder<CustomerBloc, CustomerState>(
          builder: (context, state) {
            final saving = state is CustomerSaving;
            return FilledButton.icon(
              onPressed: saving ? null : _submitForm,
              icon:
                  saving
                      ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.check),
              label: Text(_isEditing ? 'Simpan Perubahan' : 'Tambah Pelanggan'),
            );
          },
        ),
      ),
      body: BlocListener<CustomerBloc, CustomerState>(
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state is CustomerOperationSuccess) {
            showResultSnackBar(messenger, state.message);
            Navigator.of(context).pop(true);
          } else if (state is CustomerOperationFailure) {
            showResultSnackBar(messenger, state.message, success: false);
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama pelanggan*',
                    hintText: 'Masukkan nama lengkap',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama pelanggan wajib diisi';
                    }
                    if (value.trim().length < 2) {
                      return 'Nama minimal 2 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor HP',
                    hintText: 'Masukkan nomor HP (opsional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      // Basic validation, can be enhanced
                      if (!RegExp(
                        r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$',
                      ).hasMatch(value)) {
                        return 'Nomor HP tidak valid';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Alamat',
                    hintText: 'Masukkan alamat (opsional)',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
                  minLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
