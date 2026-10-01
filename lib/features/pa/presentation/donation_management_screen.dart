import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/models/app_models.dart';
import '../../../core/services/api_service.dart';
import '../pa_providers.dart';

class DonationManagementScreen extends ConsumerStatefulWidget {
  const DonationManagementScreen({super.key});

  @override
  ConsumerState<DonationManagementScreen> createState() =>
      _DonationManagementScreenState();
}

class _DonationManagementScreenState
    extends ConsumerState<DonationManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedPurpose =
      'all'; // all, Welfare Scheme, Disaster Relief, Local Development, Other
  String _selectedPaymentMode = 'all'; // all, Cash, UPI, Cheque, Net Banking

  final List<String> _purposes = [
    'Medical',
    'Education',
    'Disaster Relief',
    'Welfare',
    'Senior Citizen',
    'Farmer Support',
    'Other',
  ];

  final List<String> _paymentModes = ['Cash', 'UPI', 'Cheque', 'Net Banking'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const saffron = Color.fromARGB(255, 219, 126, 32);
    final donationsAsync = ref.watch(donationsProvider);
    final summaryAsync = ref.watch(donationSummaryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: saffron,
        foregroundColor: Colors.white,
        title: Text(
          'Donation Management',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(donationsProvider);
              ref.invalidate(donationSummaryProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Total Sum Container
          summaryAsync.when(
            loading:
                () => Container(
                  height: 100,
                  margin: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const CircularProgressIndicator(color: saffron),
                ),
            error:
                (err, stack) => Container(
                  height: 100,
                  margin: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('Error loading summary: $err'),
                ),
            data: (sumData) {
              final double total = (sumData['totalAmount'] ?? 0.0).toDouble();
              final int count = sumData['donationCount'] ?? 0;
              final formatCurrency = NumberFormat.simpleCurrency(
                locale: 'en_IN',
                decimalDigits: 0,
              );

              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B3B5A), Color(0xFF2E3349)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B3B5A).withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL DONATIONS ',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formatCurrency.format(total),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 50,
                      width: 1,
                      color: Colors.white24,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Donation Count',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$count',
                          style: GoogleFonts.poppins(
                            color: saffron,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Search & Filter Panel
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search donor name, phone, reference...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                            : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: saffron),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Purpose Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedPurpose,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          labelText: 'Purpose',
                          labelStyle: const TextStyle(fontSize: 11),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('All Purposes'),
                          ),
                          ..._purposes.map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          ),
                        ],
                        onChanged:
                            (val) => setState(() => _selectedPurpose = val!),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Payment Mode Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedPaymentMode,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          labelText: 'Payment Mode',
                          labelStyle: const TextStyle(fontSize: 11),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('All Modes'),
                          ),
                          ..._paymentModes.map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          ),
                        ],
                        onChanged:
                            (val) =>
                                setState(() => _selectedPaymentMode = val!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // History list
          Expanded(
            child: donationsAsync.when(
              loading:
                  () => const Center(
                    child: CircularProgressIndicator(color: saffron),
                  ),
              error:
                  (err, stack) =>
                      Center(child: Text('Error loading donations: $err')),
              data: (donations) {
                final filtered =
                    donations.where((d) {
                      // Search filter
                      final matchesSearch =
                          d.donorName.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          d.phone.contains(_searchQuery) ||
                          d.transactionId.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          );
                      if (_searchQuery.isNotEmpty && !matchesSearch)
                        return false;

                      // Purpose filter
                      if (_selectedPurpose != 'all' &&
                          d.purpose != _selectedPurpose)
                        return false;

                      // Payment mode filter
                      if (_selectedPaymentMode != 'all' &&
                          d.paymentMode != _selectedPaymentMode)
                        return false;

                      return true;
                    }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.monetization_on_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No donations recorded.',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return _buildGroupedDonationHistory(
                  context,
                  filtered.toList(),
                  saffron,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRecordDonationDialog(context, saffron),
        backgroundColor: saffron,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Record Donation'),
      ),
    );
  }

  // ── Purpose colour map ────────────────────────────────────────────────────
  static const Map<String, Color> _purposeColors = {
    'Welfare Scheme': Color(0xFF6A1B9A),
    'Disaster Relief': Color(0xFFB71C1C),
    'Local Development': Color(0xFF1B5E20),
    'Party Fund': Color(0xFF0D47A1),
    'Education Aid': Color(0xFF00695C),
    'Other': Color(0xFF37474F),
  };

  static const Map<String, IconData> _purposeIcons = {
    'Welfare Scheme': Icons.people_alt,
    'Disaster Relief': Icons.warning_amber,
    'Local Development': Icons.location_city,
    'Party Fund': Icons.flag,
    'Education Aid': Icons.school,
    'Other': Icons.category,
  };

  Widget _buildGroupedDonationHistory(
    BuildContext context,
    List<Donation> donations,
    Color themeColor,
  ) {
    final formatCurrency = NumberFormat.simpleCurrency(
      locale: 'en_IN',
      decimalDigits: 0,
    );

    // Group by purpose, preserving insertion order
    final Map<String, List<Donation>> grouped = {};
    for (final d in donations) {
      grouped.putIfAbsent(d.purpose, () => []).add(d);
    }

    // Build list items: header + cards per group
    final List<Widget> items = [];

    for (final entry in grouped.entries) {
      final purpose = entry.key;
      final group = entry.value;
      final subtotal = group.fold<double>(0, (sum, d) => sum + d.amount);
      final color = _purposeColors[purpose] ?? themeColor;
      final icon = _purposeIcons[purpose] ?? Icons.attach_money;

      // ── Group Header ──────────────────────────────────────────────────────
      items.add(
        Container(
          margin: const EdgeInsets.only(bottom: 8, top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.92), color.withOpacity(0.75)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purpose,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${group.length} donation${group.length == 1 ? '' : 's'}',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency.format(subtotal),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'subtotal',
                    style: GoogleFonts.poppins(
                      color: Colors.white60,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      // ── Individual donation cards under this group ─────────────────────
      for (final donation in group) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _buildDonationCard(context, donation, color),
          ),
        );
      }

      items.add(const SizedBox(height: 4));
    }

    return ListView(padding: const EdgeInsets.all(16), children: items);
  }

  Widget _buildDonationCard(
    BuildContext context,
    Donation donation,
    Color themeColor,
  ) {
    final formatCurrency = NumberFormat.simpleCurrency(
      locale: 'en_IN',
      decimalDigits: 0,
    );
    final dateStr = DateFormat('dd MMM yyyy').format(donation.donationDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDonationDetailDialog(context, donation, themeColor),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      donation.donorName,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B3B5A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formatCurrency.format(donation.amount),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Phone: ${donation.phone}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      donation.purpose,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                  ),
                  Text(
                    'Mode: ${donation.paymentMode} • Ref: ${donation.transactionId.length > 12 ? donation.transactionId.substring(0, 12) + '...' : donation.transactionId}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDonationDetailDialog(
    BuildContext context,
    Donation donation,
    Color themeColor,
  ) {
    final formatCurrency = NumberFormat.simpleCurrency(
      locale: 'en_IN',
      decimalDigits: 0,
    );
    final dateStr = DateFormat('dd MMMM yyyy').format(donation.donationDate);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.monetization_on, color: themeColor),
              const SizedBox(width: 8),
              Text(
                'Donation Info',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Donor Name', donation.donorName),
                _detailRow('Contact Phone', donation.phone),
                _detailRow(
                  'Amount Received',
                  formatCurrency.format(donation.amount),
                  isBoldValue: true,
                  valueColor: Colors.green.shade700,
                ),
                _detailRow('Donation Date', dateStr),
                _detailRow('Purpose / Category', donation.purpose),
                _detailRow('Payment Mode', donation.paymentMode),
                _detailRow(
                  'Reference / Receipt ID',
                  donation.transactionId.isEmpty
                      ? 'N/A'
                      : donation.transactionId,
                ),
                _detailRow(
                  'Status',
                  donation.status,
                  valueColor: Colors.blue.shade700,
                  isBoldValue: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: TextStyle(
                  color: themeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    bool isBoldValue = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? const Color(0xFF1B3B5A),
            ),
          ),
          const Divider(height: 12, thickness: 0.5),
        ],
      ),
    );
  }

  void _showRecordDonationDialog(BuildContext context, Color themeColor) {
    final donorNameController = TextEditingController();
    final phoneController = TextEditingController();
    final amountController = TextEditingController();
    final refController = TextEditingController();
    DateTime donationDate = DateTime.now();
    String selectedPurpose = _purposes.first;
    String selectedPaymentMode = _paymentModes.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Record Manual Donation',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: donorNameController,
                      decoration: const InputDecoration(
                        labelText: 'Beneficiary Name',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedPurpose,
                      decoration: const InputDecoration(
                        labelText: 'Category / Purpose',
                      ),
                      items:
                          _purposes
                              .map(
                                (p) =>
                                    DropdownMenuItem(value: p, child: Text(p)),
                              )
                              .toList(),
                      onChanged:
                          (val) => setDialogState(() => selectedPurpose = val!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedPaymentMode,
                      decoration: const InputDecoration(
                        labelText: 'Payment Mode',
                      ),
                      items:
                          _paymentModes
                              .map(
                                (m) =>
                                    DropdownMenuItem(value: m, child: Text(m)),
                              )
                              .toList(),
                      onChanged:
                          (val) =>
                              setDialogState(() => selectedPaymentMode = val!),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: refController,
                      decoration: const InputDecoration(
                        labelText: 'Receipt / Ref Number (Optional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Flexible(
                          flex: 2,
                          child: Text(
                            'Donation Date:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Flexible(
                          flex: 3,
                          child: TextButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: donationDate,
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 365),
                                ),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setDialogState(() => donationDate = date);
                              }
                            },
                            icon: const Icon(Icons.calendar_month, size: 16),
                            label: Text(
                              DateFormat('dd MMM yyyy').format(donationDate),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (donorNameController.text.trim().isEmpty ||
                        phoneController.text.trim().isEmpty ||
                        amountController.text.trim().isEmpty) {
                      AppDialogs.showErrorDialog(context, userMessage: 'Please fill all required fields');
                      return;
                    }

                    final donation = Donation(
                      id: '',
                      donorName: donorNameController.text.trim(),
                      phone: phoneController.text.trim(),
                      amount:
                          double.tryParse(amountController.text.trim()) ?? 0.0,
                      donationDate: donationDate,
                      purpose: selectedPurpose,
                      paymentMode: selectedPaymentMode,
                      transactionId: refController.text.trim(),
                      status: 'Completed',
                      createdAt: DateTime.now(),
                    );

                    try {
                      await ref.read(apiServiceProvider).addDonation(donation);
                      ref.invalidate(donationsProvider);
                      ref.invalidate(donationSummaryProvider);
                      if (context.mounted) {
                        Navigator.pop(context);
                        AppDialogs.showSuccessDialog(context, message: 'Donation recorded successfully!');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppDialogs.showErrorDialog(context, userMessage: 'Failed to record donation:', technicalError: e);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Record'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
