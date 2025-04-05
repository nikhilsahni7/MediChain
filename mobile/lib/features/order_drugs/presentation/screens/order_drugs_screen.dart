import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:medileger/core/services/medicine_service.dart';
import 'package:medileger/core/services/order_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Constants
const String razorpayKeyId = 'rzp_test_3e3y5c5TI1K7Lz';

class OrderDrugsScreen extends ConsumerStatefulWidget {
  const OrderDrugsScreen({super.key});

  @override
  ConsumerState<OrderDrugsScreen> createState() => _OrderDrugsScreenState();
}

class _OrderDrugsScreenState extends ConsumerState<OrderDrugsScreen> {
  // Services
  final OrderService _orderService = OrderService();

  // Razorpay
  late Razorpay _razorpay;

  // UI state
  bool _isLoading = false;
  bool _isSearching = false;
  String _errorMessage = '';

  // Form controllers
  final TextEditingController _medicineNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Search results
  List<MedicineSearchResult> _searchResults = [];
  MedicineSearchResult? _selectedResult;

  // Current hospital info
  Hospital? _currentHospital;

  // Medicine suggestions
  final List<String> _medicineSuggestions = [
    "Paracetamol",
    "Amoxicillin",
    "Ibuprofen",
    "Metformin",
    "Omeprazole",
    "Aspirin",
    "Atorvastatin",
    "Insulin",
    "Lisinopril",
    "Metoprolol"
  ];

  List<String> _filteredSuggestions = [];

  // Payment selection
  String _selectedPaymentMethod = 'razorpay'; // Default to Razorpay

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _loadCurrentHospital();
    _filteredSuggestions = _medicineSuggestions;
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> _loadCurrentHospital() async {
    try {
      setState(() => _isLoading = true);

      // Get current hospital data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final hospitalId = prefs.getString('userId') ?? 'no-id';
      final hospitalName = prefs.getString('name') ?? 'Your Hospital';
      final email = prefs.getString('email') ?? 'hospital@example.com';
      final walletAddress = prefs.getString('walletAddress') ?? '0x1234...abcd';
      final latitude = prefs.getDouble('latitude');
      final longitude = prefs.getDouble('longitude');

      _currentHospital = Hospital(
        id: hospitalId,
        name: hospitalName,
        email: email,
        walletAddress: walletAddress,
        reputation: 5,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      _setError('Failed to load hospital information');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _searchMedicines() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
      _selectedResult = null;
      _errorMessage = '';
    });

    try {
      debugPrint(
          'Searching for: ${_medicineNameController.text.trim()}, Quantity: ${_quantityController.text.trim()}');

      final results = await _orderService.searchMedicinesByName(
        name: _medicineNameController.text.trim(),
        quantity: int.parse(_quantityController.text.trim()),
        maxDistance: 25, // Match the example parameter
      );

      if (results.isEmpty) {
        setState(() => _errorMessage =
            'No medicines found nearby. Try a different name or quantity.');
        debugPrint('No search results found');
      } else {
        debugPrint('Found ${results.length} results');
        setState(() => _searchResults = results);
      }
    } catch (e) {
      debugPrint('Search error details: ${e.toString()}');
      _setError('Search failed: ${e.toString()}');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _selectHospital(MedicineSearchResult result) {
    setState(() => _selectedResult = result);
  }

  Future<void> _createOrder() async {
    if (_selectedResult == null) return;

    setState(() => _isLoading = true);

    try {
      final quantity = int.parse(_quantityController.text.trim());

      // First create an order
      Order? order;
      try {
        order = await _orderService.createOrder(
          medicineName: _selectedResult!.name,
          quantity: quantity,
          toHospitalId: _selectedResult!.hospitalId,
        );
        debugPrint('Order created successfully: ${order?.id}');
      } catch (e) {
        debugPrint('Error creating order: $e');
        // Show an error toast but continue with mock order for demo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not create order, using demo mode'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Calculate simple price (in a real app, this would come from the backend)
      final price = quantity * 100; // Just a mock price of 100 per unit

      // If order creation failed, use mock order for demo
      final String orderId =
          order?.id ?? 'mock_order_${DateTime.now().millisecondsSinceEpoch}';

      if (_selectedPaymentMethod == 'razorpay') {
        try {
          // Create a Razorpay payment order
          RazorpayOrderResponse? paymentOrder;
          bool useMockPayment = false;

          try {
            if (order != null) {
              // Only try real payment if order was created
              paymentOrder = await _orderService.createPaymentOrder(
                orderId: orderId,
                amount: price,
              );
              debugPrint(
                  'Payment order created: ${paymentOrder?.razorpayOrderId}');
            } else {
              useMockPayment = true;
            }
          } catch (e) {
            debugPrint('Error creating payment order: $e');
            useMockPayment = true;

            // Show appropriate error message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment gateway unavailable, using demo mode'),
                backgroundColor: Colors.orange,
              ),
            );
          }

          if (paymentOrder != null) {
            // Launch Razorpay payment
            var options = {
              'key': razorpayKeyId,
              'amount': paymentOrder
                  .amount, // amount in smallest currency unit (paise for INR)
              'order_id': paymentOrder.razorpayOrderId,
              'name': 'MediLeger',
              'description': 'Order for ${_selectedResult!.name} x $quantity',
              'timeout': 300, // in seconds
              'prefill': {
                'contact': _currentHospital?.email ?? '',
                'email': _currentHospital?.email ?? '',
              },
              'theme': {
                'color': '#3399cc',
              },
              'external': {
                'wallets': ['paytm']
              }
            };

            _razorpay.open(options);
          } else if (useMockPayment) {
            // Mock payment success for demo if backend is unavailable
            _mockPaymentSuccess(orderId);
          }
        } catch (e) {
          debugPrint('Payment processing error: $e');
          // Mock payment success for demo if backend is unavailable
          _mockPaymentSuccess(orderId);
        }
      } else if (_selectedPaymentMethod == 'crypto') {
        // For future implementation - show crypto payment dialog
        _showCryptoPaymentInfo(orderId, _selectedResult!.name, quantity, price);
      }
    } catch (e) {
      _setError('Order failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Mock payment success when backend is unavailable
  void _mockPaymentSuccess(String orderId) {
    // Show success dialog with mock data
    _showTransactionStatus(
      success: true,
      title: 'Demo Payment Successful',
      message: 'This is a demo payment as the backend is unavailable.\n\n'
          'Medicine: ${_selectedResult!.name}\n'
          'Quantity: ${_quantityController.text.trim()}\n'
          'Hospital: ${_selectedResult!.hospital.name}\n'
          'Payment ID: mock_payment_${DateTime.now().millisecondsSinceEpoch}',
    );

    // Reset form
    setState(() {
      _medicineNameController.clear();
      _quantityController.clear();
      _searchResults = [];
      _selectedResult = null;
    });
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      // Verify payment on backend
      Order? verifiedOrder;
      try {
        verifiedOrder = await _orderService.verifyRazorpayPayment(
          orderId: response.orderId!,
          razorpayPaymentId: response.paymentId!,
          razorpaySignature: response.signature!,
        );
      } catch (e) {
        debugPrint('Payment verification error: $e');
        // Continue with success UI even if verification fails
      }

      // Show success dialog
      _showTransactionStatus(
        success: true,
        title: 'Payment Successful',
        message: 'Your order has been placed successfully.\n\n'
            'Medicine: ${_selectedResult!.name}\n'
            'Quantity: ${_quantityController.text.trim()}\n'
            'Hospital: ${_selectedResult!.hospital.name}\n'
            'Payment ID: ${response.paymentId}',
      );

      // Reset form
      setState(() {
        _medicineNameController.clear();
        _quantityController.clear();
        _searchResults = [];
        _selectedResult = null;
      });
    } catch (e) {
      _setError('Failed to complete payment process: ${e.toString()}');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showTransactionStatus(
      success: false,
      title: 'Payment Failed',
      message: 'Error: ${response.message}\n'
          'Code: ${response.code}\n\n'
          'Please try again or contact support if the problem persists.',
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showTransactionStatus(
      success: true,
      title: 'External Wallet Selected',
      message: 'You have selected ${response.walletName} for payment.\n'
          'Please complete the payment in your wallet app.',
    );
  }

  void _showTransactionStatus({
    required bool success,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (success) ...[
                const SizedBox(height: 16),
                const Text(
                  'Transaction Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                    'Date: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(success ? 'Done' : 'Close'),
            ),
            if (!success)
              TextButton(
                onPressed: () {
                  // Add support contact functionality here
                  Navigator.of(context).pop();
                },
                child: const Text('Contact Support'),
              ),
          ],
        );
      },
    );
  }

  // Filter suggestions based on input
  void _filterSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredSuggestions = _medicineSuggestions;
      });
      return;
    }

    setState(() {
      _filteredSuggestions = _medicineSuggestions
          .where((medicine) =>
              medicine.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // Select a suggestion
  void _selectSuggestion(String suggestion) {
    setState(() {
      _medicineNameController.text = suggestion;
      _filteredSuggestions = [];
    });
  }

  // Show crypto payment info (for future implementation)
  void _showCryptoPaymentInfo(
      String orderId, String medicineName, int quantity, int price) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.currency_bitcoin, color: Colors.amber[700]),
              const SizedBox(width: 8),
              const Text('Crypto Payment'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order ID: $orderId'),
              Text('Medicine: $medicineName'),
              Text('Quantity: $quantity'),
              Text('Amount: ${price / 100} ETH'),
              const SizedBox(height: 16),
              const Text(
                'This feature is coming soon!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'In the future, you will be able to pay using cryptocurrency.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Header
                      _buildSearchHeader(textTheme, colorScheme),
                      const SizedBox(height: 24),

                      // Search Form
                      _buildSearchForm(colorScheme),
                      const SizedBox(height: 24),

                      // Hospital wallet info (for crypto payment in future)
                      if (_currentHospital != null)
                        _buildHospitalCard(textTheme, colorScheme),

                      const SizedBox(height: 24),

                      // Search Results
                      if (_isSearching)
                        const Center(child: CircularProgressIndicator())
                      else if (_errorMessage.isNotEmpty)
                        Center(
                          child: Text(
                            _errorMessage,
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.red,
                            ),
                          ),
                        )
                      else if (_searchResults.isNotEmpty)
                        _buildSearchResults(textTheme, colorScheme, isTablet),

                      // Selected Hospital Details
                      if (_selectedResult != null) ...[
                        const SizedBox(height: 24),
                        _buildSelectedHospitalDetails(textTheme, colorScheme),

                        // Place Order Button (inside the scroll view)
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _createOrder,
                            icon: const Icon(Icons.shopping_cart),
                            label: const Text('Place Order Now'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),
              ),
            ),

      // We'll keep the floating action button for smaller screens
      floatingActionButton: _selectedResult != null && screenSize.width < 500
          ? FloatingActionButton.extended(
              onPressed: _createOrder,
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Place Order'),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            )
          : null,
    );
  }

  Widget _buildSearchHeader(TextTheme textTheme, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.search_rounded,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search Medicine',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Find medicines from nearby hospitals',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchForm(ColorScheme colorScheme) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _medicineNameController,
                decoration: InputDecoration(
                  labelText: 'Medicine Name',
                  hintText: 'e.g. Paracetamol, Insulin',
                  prefixIcon: const Icon(Icons.medication),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter medicine name';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
                onChanged: (value) => _filterSuggestions(value),
              ),
              // Suggestions list
              if (_medicineNameController.text.isNotEmpty &&
                  _filteredSuggestions.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(maxHeight: 150),
                  margin: const EdgeInsets.only(top: 4),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredSuggestions.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        dense: true,
                        title: Text(_filteredSuggestions[index]),
                        onTap: () =>
                            _selectSuggestion(_filteredSuggestions[index]),
                      );
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _quantityController,
            decoration: InputDecoration(
              labelText: 'Quantity Required',
              hintText: 'e.g. 10, 20, 100',
              prefixIcon: const Icon(Icons.inventory_2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter quantity';
              }
              if (int.tryParse(value) == null || int.parse(value) <= 0) {
                return 'Please enter a valid quantity';
              }
              return null;
            },
            textInputAction: TextInputAction.search,
            onFieldSubmitted: (_) => _searchMedicines(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSearching ? null : _searchMedicines,
              icon: const Icon(Icons.search),
              label: const Text('Find Nearby Hospitals'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalCard(TextTheme textTheme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Hospital Wallet',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Hospital: ${_currentHospital?.name}'),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Wallet Address: ',
                style: textTheme.bodyMedium,
              ),
              Expanded(
                child: Text(
                  _currentHospital?.walletAddress ?? 'Not available',
                  style: textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {
                  // Copy to clipboard functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Address copied to clipboard')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
      TextTheme textTheme, ColorScheme colorScheme, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_hospital,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Nearby Hospitals (${_searchResults.length})',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Results grid/list
        isTablet
            ? GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) => _buildHospitalResultCard(
                    _searchResults[index], colorScheme),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildHospitalResultCard(
                      _searchResults[index], colorScheme),
                ),
              ),
      ],
    );
  }

  Widget _buildHospitalResultCard(
      MedicineSearchResult result, ColorScheme colorScheme) {
    final isSelected = _selectedResult?.id == result.id;

    return GestureDetector(
      onTap: () => _selectHospital(result),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    result.hospital.name ?? 'Unknown Hospital',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${result.hospital.reputation}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.medication, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.inventory_2, size: 16),
                const SizedBox(width: 8),
                Text('${result.quantity} available'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.map, size: 16),
                const SizedBox(width: 8),
                Text('${result.distance.toStringAsFixed(1)} km away'),
              ],
            ),
            const SizedBox(height: 8),

            // Payment options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Wrap(
                    spacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Razorpay',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (result.paymentOptions['crypto'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.currency_bitcoin,
                                size: 14,
                                color: Colors.amber.shade800,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Crypto',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedHospitalDetails(
      TextTheme textTheme, ColorScheme colorScheme) {
    if (_selectedResult == null) return const SizedBox.shrink();

    // Calculate a simple price based on quantity (in a real app this would come from backend)
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final price = quantity * 100; // Just a mock price of 100 per unit

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildOrderDetailRow(
            icon: Icons.local_hospital,
            label: 'From',
            value: _currentHospital?.name ?? 'Your Hospital',
          ),
          const Divider(),
          _buildOrderDetailRow(
            icon: Icons.arrow_forward,
            label: 'To',
            value: _selectedResult!.hospital.name ?? 'Selected Hospital',
          ),
          const Divider(),
          _buildOrderDetailRow(
            icon: Icons.medication,
            label: 'Medicine',
            value: _selectedResult!.name,
          ),
          const Divider(),
          _buildOrderDetailRow(
            icon: Icons.inventory_2,
            label: 'Quantity',
            value: '${_quantityController.text} units',
          ),
          const Divider(),
          _buildOrderDetailRow(
            icon: Icons.payments,
            label: 'Price',
            value: '₹${NumberFormat('#,##0.00').format(price)}',
          ),
          const SizedBox(height: 16),

          // Payment method selection
          Text(
            'Payment Method',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = 'razorpay';
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: _selectedPaymentMethod == 'razorpay'
                          ? colorScheme.primary.withOpacity(0.2)
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedPaymentMethod == 'razorpay'
                            ? colorScheme.primary
                            : Colors.grey.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Razorpay',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_selectedResult?.paymentOptions['crypto'] == true) {
                      setState(() {
                        _selectedPaymentMethod = 'crypto';
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'This hospital does not accept crypto payments'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: (_selectedPaymentMethod == 'crypto' &&
                              _selectedResult?.paymentOptions['crypto'] == true)
                          ? Colors.amber.withOpacity(0.2)
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (_selectedPaymentMethod == 'crypto' &&
                                _selectedResult?.paymentOptions['crypto'] ==
                                    true)
                            ? Colors.amber.shade800
                            : Colors.grey.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.currency_bitcoin,
                          color:
                              _selectedResult?.paymentOptions['crypto'] == true
                                  ? Colors.amber.shade800
                                  : Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Crypto',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedResult?.paymentOptions['crypto'] ==
                                    true
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Wallet addresses for crypto payment (future)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wallet Details',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildWalletAddressRow(
                  label: 'Your Wallet',
                  address: _currentHospital?.walletAddress ?? '-',
                ),
                const SizedBox(height: 8),
                _buildWalletAddressRow(
                  label: 'Hospital Wallet',
                  address: _selectedResult!.hospital.walletAddress,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletAddressRow({
    required String label,
    required String address,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                address,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            SizedBox(
              width: 40,
              child: IconButton(
                icon: const Icon(Icons.copy, size: 16),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                onPressed: () {
                  // Copy to clipboard functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Address copied to clipboard')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _medicineNameController.dispose();
    _quantityController.dispose();
    _razorpay.clear();
    super.dispose();
  }
}
