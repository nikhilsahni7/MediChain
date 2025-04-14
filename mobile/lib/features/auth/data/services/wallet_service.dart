import 'package:flutter/foundation.dart';

abstract class WalletService {
  String? get address;
  ValueNotifier<ConnectionStatus> get connectionStatus;

  Future<bool> connect();
  Future<void> disconnect();
  Future<BigInt> getBalance();

  // Helper method to format Wei to ETH (for display)
  String formatBalance(BigInt balance) {
    final eth = balance / BigInt.from(10).pow(18);
    return eth.toStringAsFixed(4);
  }
}

///
enum ConnectionStatus { disconnected, connecting, connected }
