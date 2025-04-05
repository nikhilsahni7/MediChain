import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medileger/config/router/app_router.dart';
import 'package:medileger/core/providers/shared_preferences_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;
  String? _walletAddress;
  WalletConnect? _connector;
  String? _wcUri;
  Timer? _connectionTimer;

  @override
  void initState() {
    super.initState();
    // Initialize WalletConnect
    _initWalletConnect();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _killSession();
    _connectionTimer?.cancel();
    super.dispose();
  }

  void _initWalletConnect() {
    _connector = WalletConnect(
      bridge: 'https://bridge.walletconnect.org',
      clientMeta: const PeerMeta(
        name: 'MediChain',
        description: 'Connect your MetaMask wallet to MediChain',
        url: 'https://medichain.app',
        icons: ['https://walletconnect.org/walletconnect-logo.png'],
      ),
    );

    debugPrint("WalletConnect initialized");

    // Subscribe to events
    _connector!.on('connect', (session) {
      debugPrint("Connected: $session");
      if (session is SessionStatus && session.accounts.isNotEmpty) {
        debugPrint("Accounts: ${session.accounts}");
        setState(() {
          _walletAddress = session.accounts[0];
        });
        _handleSuccessfulConnection();
      } else {
        debugPrint("Invalid session or no accounts: $session");
      }
    });

    _connector!.on('session_update', (payload) {
      debugPrint("Session updated: $payload");
      if (payload is SessionStatus && payload.accounts.isNotEmpty) {
        debugPrint("Updated accounts: ${payload.accounts}");
        setState(() {
          _walletAddress = payload.accounts[0];
        });
      } else {
        debugPrint("Invalid payload or no accounts: $payload");
      }
    });

    _connector!.on('disconnect', (session) {
      debugPrint("Disconnected: $session");
      setState(() {
        _walletAddress = null;
      });
    });

    _connector!.on('error', (error) {
      debugPrint("WalletConnect Error: $error");
    });
  }

  Future<void> _killSession() async {
    if (_connector != null && _connector!.connected) {
      try {
        debugPrint("Killing session");
        await _connector!.killSession();
        debugPrint("Session killed successfully");
      } catch (e) {
        debugPrint("Error killing session: $e");
      }
    } else {
      debugPrint("No active session to kill");
    }
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // --- Placeholder Login ---
      await Future.delayed(const Duration(milliseconds: 1500));

      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool('isLoggedIn', true);

      if (mounted) {
        context.go(AppRoutes.home);
      }
      // --- End Placeholder ---
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login Failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _connectMetamask() async {
    if (_connector == null) {
      _initWalletConnect();
    }

    setState(() => _isLoading = true);

    try {
      // If already connected, just read the address
      if (_connector!.connected && _connector!.session.accounts.isNotEmpty) {
        setState(() {
          _walletAddress = _connector!.session.accounts[0];
        });
        _handleSuccessfulConnection();
        return;
      }

      // Show a pending connection snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preparing MetaMask connection...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Create a new session
      await _connector!.createSession(
        chainId: 1, // Ethereum Mainnet
        onDisplayUri: (uri) async {
          debugPrint("WalletConnect URI: $uri");

          // Save URI for QR code display or manual connection
          setState(() {
            _wcUri = uri;
          });

          // First, show the connection options dialog
          _showConnectionOptions(uri);

          // Try direct deep link to MetaMask app
          try {
            final metamaskDeepLink =
                'metamask://wc?uri=${Uri.encodeComponent(uri)}';
            final metamaskUri = Uri.parse(metamaskDeepLink);

            // Check if MetaMask is installed
            if (await canLaunchUrl(Uri.parse('metamask://'))) {
              // Launch MetaMask with the WalletConnect URI
              final launched = await launchUrl(
                metamaskUri,
                mode: LaunchMode.externalApplication,
              );
              debugPrint("Launched MetaMask app: $launched");
            } else {
              debugPrint("MetaMask app not installed");

              // Try regular URI as fallback
              final wcUri = Uri.parse(uri);
              final launched = await launchUrl(
                wcUri,
                mode: LaunchMode.externalApplication,
              );
              debugPrint("Launched with regular URI: $launched");
            }
          } catch (e) {
            debugPrint("Error launching MetaMask: $e");

            // Show a message if we're still mounted
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Error launching MetaMask. Use the QR code or copy the URI instead.'),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }

          // Start polling for connection
          _startConnectionTimer();
        },
      );

      // We'll handle the connection in the 'connect' event
    } catch (e) {
      debugPrint("Error connecting to MetaMask: $e");

      // Show a dialog with the error and offer direct connection option
      if (mounted) {
        _showConnectionErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showConnectionErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('MetaMask Connection Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('There was an error connecting to MetaMask:'),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.red,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            const Text(
              'This could be due to network issues or MetaMask app not being properly configured.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          // Direct connection option
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _simulateMetaMaskConnection();
            },
            child: const Text('Use Test Account'),
          ),
        ],
      ),
    );
  }

  void _showConnectionOptions(String uri) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => AlertDialog(
        title: const Text('Connect with MetaMask'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'MetaMask should open automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'If it doesn\'t open, you can copy this connection URI:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: uri));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URI copied to clipboard')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  uri,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Waiting for connection...',
              textAlign: TextAlign.center,
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _killSession();
            },
            child: const Text('Cancel'),
          ),
          // Option for testing
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _simulateMetaMaskConnection();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
            child: const Text('Use Test Account'),
          ),
        ],
      ),
    );
  }

  void _startConnectionTimer() {
    // Cancel any existing timer
    _connectionTimer?.cancel();

    debugPrint("Starting connection timer");

    int attemptCount = 0;

    // Set up a timer to check connection status
    _connectionTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      attemptCount++;
      debugPrint(
          "Connection timer check: attempt=$attemptCount, connected=${_connector?.connected}, accounts=${_connector?.session.accounts}");

      if (_connector != null && _connector!.connected) {
        // If connected, cancel the timer
        debugPrint("Connection detected, canceling timer");
        timer.cancel();

        // Check if we have the wallet address
        if (_connector!.session.accounts.isNotEmpty) {
          debugPrint(
              "Found wallet address: ${_connector!.session.accounts[0]}");
          setState(() {
            _walletAddress = _connector!.session.accounts[0];
          });
          _handleSuccessfulConnection();
        } else {
          debugPrint("Connected but no accounts found");
        }
      }

      // After 20 seconds (10 attempts), stop trying
      if (attemptCount >= 10) {
        timer.cancel();
        debugPrint("Connection timeout after $attemptCount attempts");
      }
    });
  }

  // Add this method to simulate a successful MetaMask connection for testing
  void _simulateMetaMaskConnection() {
    setState(() => _isLoading = true);

    // Use a hardcoded test Ethereum address
    const testAddress = "0x71C7656EC7ab88b098defB751B7401B5f6d8976F";

    // Simulate a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _walletAddress = testAddress;
          _isLoading = false;
        });
        _handleSuccessfulConnection();
      }
    });
  }

  void _handleSuccessfulConnection() {
    if (_walletAddress != null) {
      // Save login state and wallet address
      final prefs = ref.read(sharedPreferencesProvider);
      prefs.setBool('isLoggedIn', true);
      prefs.setString('walletAddress', _walletAddress!);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Connected: ${_walletAddress!.substring(0, 6)}...${_walletAddress!.substring(_walletAddress!.length - 4)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );

        // Navigate to home screen
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            // Dismiss any showing dialogs
            Navigator.of(context, rootNavigator: true)
                .popUntil((route) => route.isFirst);

            // Navigate to home
            context.go(AppRoutes.home);
          }
        });
      }
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  // Placeholder for Google Sign In
  Future<void> _googleSignIn() async {
    // TODO: Implement Google Sign-In logic using firebase_auth and google_sign_in packages
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google Sign-In not implemented yet.')),
    );
  }

  // Placeholder for Forgot Password
  void _forgotPassword() {
    // TODO: Implement Forgot Password flow (e.g., show dialog, navigate to reset screen)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Forgot Password not implemented yet.')),
    );
  }

  // Placeholder for Sign Up Navigation
  void _goToSignUp() {
    // TODO: Implement navigation to a Sign Up screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign Up navigation not implemented yet.')),
    );
    // Example: context.push(AppRoutes.signUp); // If you have a sign-up route
  }

  // Add this method to manually check if the MetaMask app can be opened
  Future<void> _checkMetaMaskInstalled() async {
    final metamaskUri = Uri.parse('metamask://');
    final canLaunch = await canLaunchUrl(metamaskUri);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(canLaunch
              ? 'MetaMask app is installed'
              : 'MetaMask app is not installed. Please install it from the Play Store or App Store.'),
          backgroundColor: canLaunch ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Add disconnect wallet functionality to allow users to try another wallet
  Future<void> _disconnectWallet() async {
    try {
      // Kill the WalletConnect session if it exists
      await _killSession();

      // Clear wallet address
      setState(() {
        _walletAddress = null;
      });

      // Clear saved wallet info
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.remove('walletAddress');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wallet disconnected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error disconnecting wallet: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final inputTheme = Theme.of(context).inputDecorationTheme;
    final screenSize = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Use theme's scaffold background color
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: screenSize.height * 0.05, // Responsive vertical padding
            ),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: 400), // Max width for content
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Logo Section
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medical_services_rounded,
                            size: 48, // Slightly smaller logo icon
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'MediChain',
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Welcome Text
                    Text(
                      'Welcome Back!',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Securely sign in to your account',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        // Use themed input decoration
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.alternate_email, size: 20),
                        hintText: 'you@example.com',
                        // Use colors from theme
                        // prefixIconColor: inputTheme.prefixIconColor,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email cannot be empty';
                        } else if (!RegExp(
                                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                            .hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        hintText: 'Enter your password',
                        suffixIcon: IconButton(
                          splashRadius: 20,
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: _togglePasswordVisibility,
                          // Use theme color for suffix icon
                          // color: inputTheme.suffixIconColor,
                        ),
                      ),
                      obscureText: _obscureText,
                      textInputAction: TextInputAction.done,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onFieldSubmitted: (_) => _login(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password cannot be empty';
                        }
                        // Basic length check, consider more robust validation
                        // if (value.length < 6) {
                        //   return 'Password must be at least 6 characters';
                        // }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _forgotPassword,
                        // Use theme's text button style
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Login Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      // Use theme's elevated button style
                      child: _isLoading
                          ? SizedBox(
                              height: 24, // Consistent height with text
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: colorScheme
                                    .onPrimary, // Spinner color on button
                              ),
                            )
                          : const Text('SIGN IN'),
                    ),
                    const SizedBox(height: 30),

                    // Divider OR
                    Row(
                      children: [
                        const Expanded(child: Divider()), // Uses theme divider
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'OR CONTINUE WITH',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Web3 Login Buttons Row
                    Row(
                      children: [
                        // MetaMask Button
                        Expanded(
                          child: _walletAddress != null
                              // If wallet is connected, show disconnect button
                              ? OutlinedButton.icon(
                                  icon: const Icon(Icons.link_off, size: 24),
                                  label: const Text('Disconnect'),
                                  onPressed:
                                      _isLoading ? null : _disconnectWallet,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    backgroundColor:
                                        Colors.orange.withOpacity(0.1),
                                    side: const BorderSide(
                                        color: Colors.orange, width: 1.5),
                                  ),
                                )
                              // Otherwise show connect button
                              : OutlinedButton.icon(
                                  icon: const Icon(Icons.account_balance_wallet,
                                      size: 24),
                                  label: const Text('MetaMask'),
                                  onPressed:
                                      _isLoading ? null : _connectMetamask,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        // Google Button
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.g_mobiledata, size: 24),
                            label: const Text('Google'),
                            onPressed: _isLoading ? null : _googleSignIn,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Show connected wallet address if available
                    if (_walletAddress != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Connected: ${_walletAddress!.substring(0, 6)}...${_walletAddress!.substring(_walletAddress!.length - 4)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Debug Button - Add a small link to check MetaMask installation
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: _checkMetaMaskInstalled,
                          child: Text(
                            'Check MetaMask Installation',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "New to MediChain?",
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        TextButton(
                          onPressed: _isLoading ? null : _goToSignUp,
                          child: Text(
                            'Create Account',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              // Color is handled by TextButton theme
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20), // Bottom padding
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
