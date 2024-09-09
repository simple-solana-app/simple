import 'package:flutter/material.dart';
import 'package:solana_wallet_provider/solana_wallet_provider.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key, required this.provider});

  final SolanaWalletProvider provider;

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  Future<void> _connect(
      final BuildContext context, final SolanaWalletProvider provider) async {
    await provider.connect(context);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'simply',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontStyle: FontStyle.italic),
            ),
            ElevatedButton(
              onPressed: () => _connect(
                context,
                widget.provider,
              ),
              child: const Text(
                'Connect',
                style: TextStyle(color: Colors.black, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
