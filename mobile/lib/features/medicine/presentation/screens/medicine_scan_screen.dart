import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:medileger/core/config/api_config.dart';
import 'package:medileger/core/services/auth_service.dart';
import 'package:medileger/features/medicine/data/models/medicine.dart';
import 'package:medileger/features/medicine/data/providers/medicine_providers.dart';
import 'package:permission_handler/permission_handler.dart';

class MedicineScanScreen extends ConsumerStatefulWidget {
  const MedicineScanScreen({super.key});

  @override
  ConsumerState<MedicineScanScreen> createState() => _MedicineScanScreenState();
}

class _MedicineScanScreenState extends ConsumerState<MedicineScanScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isUploading = false;
  bool _isScanning = false;
  bool _scanComplete = false;
  bool _isLoading = false;

  late AnimationController _animationController;
  final _authService = AuthService();
  String? _errorMessage;
  List<Medicine>? _detectedMedicines;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getImageFromSource(ImageSource source) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check for permissions first
      bool hasPermission =
          await _checkPermissions(source == ImageSource.camera);

      if (!hasPermission) {
        setState(() {
          _isLoading = false;
          // Error message is set in _checkPermissions if permanently denied
        });
        return;
      }

      // If we have permission, proceed with getting the image
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No image selected.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = source == ImageSource.camera
            ? 'Error accessing camera: ${e.toString()}'
            : 'Error accessing gallery: ${e.toString()}';
      });
    }
  }

  Future<bool> _checkPermissions(bool isCamera) async {
    Permission permission = isCamera ? Permission.camera : Permission.photos;

    PermissionStatus status = await permission.status;
    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      status = await permission.request();
      return status.isGranted;
    }

    if (status.isPermanentlyDenied) {
      setState(() {
        _errorMessage = isCamera
            ? 'Camera permission is permanently denied. Please enable it in app settings.'
            : 'Gallery permission is permanently denied. Please enable it in app settings.';
      });
      return false;
    }

    return false;
  }

  Future<void> _uploadImageForProcessing() async {
    setState(() {
      _isUploading = true;
      _isScanning = true;
      _errorMessage = null;
      _animationController.repeat();
    });

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/medicines/process-image');
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Authorization': 'Bearer $token',
        })
        ..files.add(
          await http.MultipartFile.fromPath(
            'medicineImage',
            _imageFile!.path,
          ),
        );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        final responseData = json.decode(responseBody);

        if (responseData['status'] == 'success') {
          setState(() {
            _isUploading = false;
            _isScanning = false;
            _scanComplete = true;
            _detectedMedicines =
                (responseData['data']['createdMedicines'] as List)
                    .map((medicine) => Medicine.fromJson(medicine))
                    .toList();
          });

          // Store the analysis result
          final analysisData = responseData['data']['analysis'];
          if (analysisData is List) {
            ref.read(scanResultProvider.notifier).state = analysisData
                .map((item) => item is Map<String, dynamic>
                    ? item
                    : Map<String, dynamic>.from(item as Map))
                .toList();
          } else if (analysisData is Map) {
            // Handle single item (old format or fallback)
            ref.read(scanResultProvider.notifier).state = [
              Map<String, dynamic>.from(analysisData)
            ];
          } else {
            // Default empty state
            ref.read(scanResultProvider.notifier).state = [];
          }

          // Show success animation
          _animationController.stop();
        } else {
          throw Exception(
              'Failed to process image: ${responseData['message']}');
        }
      } else {
        // Handle specific error codes
        if (response.statusCode == 401) {
          throw Exception('Authentication failed. Please login again.');
        } else if (response.statusCode == 413) {
          throw Exception(
              'Image file is too large. Please select a smaller image.');
        } else {
          final errorData = json.decode(responseBody);
          throw Exception(
              'Failed to process image: ${errorData['message'] ?? 'Unknown error'}');
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _isScanning = false;
      });
      _animationController.stop();

      // Format error message more clearly
      String errorMsg;
      if (e.toString().contains('type \'List<dynamic>\'')) {
        errorMsg =
            'Error processing server response: Data format issue. Please try again.';
      } else if (e.toString().contains('401')) {
        errorMsg = 'Authentication failed. Please log out and log in again.';
      } else if (e.toString().contains('Connection')) {
        errorMsg = 'Connection error. Please check your internet connection.';
      } else {
        errorMsg =
            'Error processing image: ${e.toString().split(':').last.trim()}';
      }

      setState(() {
        _errorMessage = errorMsg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Scanner'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              // Show help dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('How to Scan Medicines'),
                  content: const SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '1. Take a clear photo of the medicine strip, bottle, or tablet.'),
                        SizedBox(height: 8),
                        Text(
                            '2. Make sure the medicine name and details are clearly visible.'),
                        SizedBox(height: 8),
                        Text(
                            '3. Press the scan button to analyze and add to inventory.'),
                        SizedBox(height: 8),
                        Text(
                            '4. Review the detected medicine details before confirming.'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image preview card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.image_search,
                            color: colorScheme.onPrimaryContainer,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Medicine Image',
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Image preview or placeholder
                    Container(
                      height: isTablet ? 400 : 280,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withOpacity(0.3),
                      ),
                      child: _imageFile != null
                          ? ClipRRect(
                              child: Image.file(
                                _imageFile!,
                                fit: BoxFit.contain,
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 64,
                                    color: colorScheme.primary.withOpacity(0.6),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No image selected',
                                    style: textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Take a photo or select from gallery',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant
                                          .withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),

                    // Button bar
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            icon: Icons.photo_camera,
                            label: 'Camera',
                            onPressed: () =>
                                _getImageFromSource(ImageSource.camera),
                            color: colorScheme.primary,
                          ),
                          _buildActionButton(
                            icon: Icons.photo_library,
                            label: 'Gallery',
                            onPressed: () =>
                                _getImageFromSource(ImageSource.gallery),
                            color: colorScheme.secondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Scan button
              if (_imageFile != null && !_scanComplete)
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadImageForProcessing,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.document_scanner),
                  label: Text(_isUploading ? 'Scanning...' : 'Scan Medicine'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

              // Progress indicator during scanning
              if (_isScanning)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 150,
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _animationController.value * 2 * 3.14159,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.document_scanner,
                                    size: 40,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Analyzing medicine image...',
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Our AI is identifying the medication details',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              // Error message
              _buildErrorWidget(),

              // Results section
              if (_scanComplete && _detectedMedicines != null)
                _buildResultsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: _isUploading ? null : onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withOpacity(0.1),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: color.withOpacity(0.2)),
        ),
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final analysisList = ref.watch(scanResultProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success animation
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.green.shade700,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan Complete!',
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Medicine${analysisList.length > 1 ? 's' : ''} successfully added to your inventory',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Title text for multiple medicines
        if (analysisList.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              '${analysisList.length} Medicines Detected',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        // Medicine details cards - one for each detected medicine
        ...List.generate(analysisList.length, (index) {
          final analysis = analysisList[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.medication_outlined,
                          color: colorScheme.onSecondaryContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          analysisList.length > 1
                              ? 'Medicine ${index + 1}'
                              : 'Detected Medicine',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Medicine details
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          'Brand Name:',
                          analysis['brandName'] ?? 'Unknown',
                          colorScheme,
                          textTheme,
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'Generic Name:',
                          analysis['genericName'] ?? 'Unknown',
                          colorScheme,
                          textTheme,
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'Quantity:',
                          '${analysis['quantity'] ?? 0} units',
                          colorScheme,
                          textTheme,
                        ),
                        if (analysis['note'] != null) ...[
                          const Divider(),
                          _buildInfoRow(
                            'Note:',
                            analysis['note'],
                            colorScheme,
                            textTheme,
                            isNote: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 20),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _imageFile = null;
                    _scanComplete = false;
                    _errorMessage = null;
                    _detectedMedicines = null;
                  });
                  ref.read(scanResultProvider.notifier).state = [];
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Scan Another'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(_detectedMedicines);
                },
                icon: const Icon(Icons.check),
                label: const Text('Confirm & Save'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    bool isNote = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: isNote ? Colors.amber.shade900 : colorScheme.onSurface,
                fontWeight: isNote ? FontWeight.normal : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (_errorMessage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _errorMessage!,
            style: TextStyle(color: Colors.red.shade900),
          ),
          if (_errorMessage!.contains('permission')) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Open App Settings'),
            ),
          ],
        ],
      ),
    );
  }
}
