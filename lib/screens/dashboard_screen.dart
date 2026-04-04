import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../models/customer_summary.dart';
import 'camera_capture_screen.dart';
import 'customer_form_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<CustomerSummary>> _customersFuture;

  @override
  void initState() {
    super.initState();
    _customersFuture = AppDatabase.instance.listCustomerSummaries();
  }

  Future<void> _refresh() async {
    setState(() {
      _customersFuture = AppDatabase.instance.listCustomerSummaries();
    });
  }

  Future<void> _openCreateCustomer() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CustomerFormScreen(),
      ),
    );
    await _refresh();
  }

  Future<void> _openCamera(int customerId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CameraCaptureScreen(customerId: customerId),
      ),
    );
    await _refresh();
  }

  Future<void> _openEditCustomer(int customerId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomerFormScreen(customerId: customerId),
      ),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Dashboard'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Add customer',
            onPressed: _openCreateCustomer,
            icon: const Icon(Icons.person_add_alt_1),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateCustomer,
        icon: const Icon(Icons.add),
        label: const Text('New Customer'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<CustomerSummary>>(
          future: _customersFuture,
          builder: (BuildContext context, AsyncSnapshot<List<CustomerSummary>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Failed to load customers: ${snapshot.error}'),
                  ),
                ],
              );
            }

            final List<CustomerSummary> customers = snapshot.data ?? <CustomerSummary>[];

            if (customers.isEmpty) {
              return ListView(
                children: const <Widget>[
                  SizedBox(height: 120),
                  Icon(Icons.group_outlined, size: 62),
                  SizedBox(height: 14),
                  Center(
                    child: Text('No customers yet. Add your first customer.'),
                  ),
                ],
              );
            }

            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool wide = constraints.maxWidth >= 980;
                final double maxWidth = wide ? 1100 : 760;

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: customers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (BuildContext context, int index) {
                        final CustomerSummary customer = customers[index];
                        final String birthdateText = customer.birthdate == null
                            ? 'Not set'
                            : dateFormat.format(customer.birthdate!);

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        customer.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    Chip(
                                      avatar: const Icon(Icons.collections, size: 18),
                                      label: Text('${customer.imageCount} images'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Wrap(
                                    spacing: 14,
                                    runSpacing: 8,
                                    children: <Widget>[
                                      Text('Email: ${customer.email}'),
                                      Text('Sex: ${customer.sex}'),
                                      Text('Birthdate: $birthdateText'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: <Widget>[
                                    OutlinedButton.icon(
                                      onPressed: () => _openEditCustomer(customer.id),
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit'),
                                    ),
                                    const SizedBox(width: 10),
                                    FilledButton.icon(
                                      onPressed: () => _openCamera(customer.id),
                                      icon: const Icon(Icons.camera_alt_outlined),
                                      label: const Text('Open Capture'),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
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
    );
  }
}
