import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:simple/common.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';
import 'package:solana_wallet_provider/solana_wallet_provider.dart';

class ProtocolPage extends StatefulWidget {
  const ProtocolPage({super.key, required this.provider});

  final SolanaWalletProvider provider;

  @override
  State<ProtocolPage> createState() => _ProtocolPageState();
}

class _ProtocolPageState extends State<ProtocolPage> {
  bool _hasClaimTrackerAccount = false;
  bool _hasSimpleTokenAccount = false;

  @override
  void initState() {
    super.initState();

    _checkClaimTracker();
  }

  void _checkClaimTracker() async {
    final ProgramAddress userClaimTrackerPdaInfo = Pubkey.findProgramAddress(
      [
        sha256.convert(utf8.encode(widget.provider.connectedAccount!.address)).bytes,
      ],
      programId,
    );

    print('user claim tracker: ${userClaimTrackerPdaInfo.pubkey.toBase58()}');

    AccountInfo? userClaimTrackerAccount = await widget.provider.connection.getAccountInfo(
      userClaimTrackerPdaInfo.pubkey,
    );

    print(userClaimTrackerAccount);

    if (userClaimTrackerAccount != null) {
      setState(() {
        _hasClaimTrackerAccount = true;
      });
    }
  }

  void _checkSimpleTokenAccount() {}

  void _createAccount() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Protocol Page'),
      ),
      body: Center(
        child: _hasClaimTrackerAccount == false
            ? ElevatedButton(
                onPressed: _createAccount,
                child: Text('Create your Claim Tracker Account'),
              )
            : Text('Claim Tracker Account already exists.'),
      ),
    );
  }
}
