import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../models/customer.dart';
import 'camera_capture_screen.dart';

class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({
    super.key,
    this.customerId,
    this.returnToCaller = false,
  });

  final int? customerId;
  final bool returnToCaller;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  DateTime? _birthdate;
  String _sex = 'Unknown';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadIfEditing();
  }

  Future<void> _loadIfEditing() async {
    if (widget.customerId == null) {
      return;
    }

    setState(() {
      _loading = true;
    });

    final Customer? customer = await AppDatabase.instance.getCustomer(widget.customerId!);

    if (!mounted) {
      return;
    }

    if (customer != null) {
      _nameController.text = customer.name;
      _addressController.text = customer.address;
      _emailController.text = customer.email;
      _birthdate = customer.birthdate;
      _sex = customer.sex;
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthdate() async {
    final DateTime now = DateTime.now();
    final DateTime initial = _birthdate ?? DateTime(now.year - 30, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _birthdate = picked;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    final DateTime now = DateTime.now();
    final Customer customer = Customer(
      id: widget.customerId,
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      email: _emailController.text.trim(),
      birthdate: _birthdate,
      sex: _sex,
      createdAt: now,
      updatedAt: now,
    );

    final int customerId = await AppDatabase.instance.upsertCustomer(customer);

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
    });

    if (widget.returnToCaller) {
      Navigator.of(context).pop(customerId);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => CameraCaptureScreen(customerId: customerId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customerId == null ? 'New Customer' : 'Edit Customer'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double width = constraints.maxWidth > 760 ? 760 : constraints.maxWidth;

                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: SizedBox(
                      width: width,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: <Widget>[
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Address',
                                border: OutlineInputBorder(),
                              ),
                              minLines: 2,
                              maxLines: 3,
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Address is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                border: OutlineInputBorder(),
                              ),
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                final bool valid = RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                    .hasMatch(value.trim());
                                if (!valid) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: _pickBirthdate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Birthdate',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(_birthdate == null
                                    ? 'Select date'
                                    : formatter.format(_birthdate!)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _sex,
                              decoration: const InputDecoration(
                                labelText: 'Sex',
                                border: OutlineInputBorder(),
                              ),
                              items: const <DropdownMenuItem<String>>[
                                DropdownMenuItem(value: 'Female', child: Text('Female')),
                                DropdownMenuItem(value: 'Male', child: Text('Male')),
                                DropdownMenuItem(value: 'Other', child: Text('Other')),
                                DropdownMenuItem(value: 'Unknown', child: Text('Unknown')),
                              ],
                              onChanged: (String? value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() {
                                  _sex = value;
                                });
                              },
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _loading ? null : _save,
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text('Save and Continue to Capture'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
