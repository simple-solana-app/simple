import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:simple/common.dart';
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

  late String _recentBlockhash;

  late Pubkey _userClaimTrackerPubkey;

  @override
  void initState() {
    super.initState();

    _checkClaimTracker();
    _getRecentBlockHash();

    _findProgAccts();
  }

  void _findProgAccts() {
    final ProgramAddress percentTrackerPdaInfo = Pubkey.findProgramAddress(
      [
         utf8.encode("percent_tracker"),
      ],
      programId,
    );

    print(percentTrackerPdaInfo.pubkey);
  }

  void _checkClaimTracker() async {
    final account = widget.provider.connectedAccount!;
    final payerPubkey = Pubkey.fromBase64(account.address);

    // Find the Program Address (PDA) using the seed
    final ProgramAddress userClaimTrackerPdaInfo = Pubkey.findProgramAddress(
      [
        payerPubkey.toBytes(),
      ],
      programId,
    );

    AccountInfo? userClaimTrackerAccount =
        await widget.provider.connection.getAccountInfo(
      userClaimTrackerPdaInfo.pubkey,
    );

    setState(() {
      _userClaimTrackerPubkey = userClaimTrackerPdaInfo.pubkey;
    });

    print(userClaimTrackerAccount);

    if (userClaimTrackerAccount != null) {
      setState(() {
        _hasClaimTrackerAccount = true;
      });
    }
  }

  void _getRecentBlockHash() async {
    final BlockhashWithExpiryBlockHeight recentBlockhashResponse =
        await widget.provider.connection.getLatestBlockhash();
    final String recentBlockhash = recentBlockhashResponse.blockhash;

    setState(() {
      _recentBlockhash = recentBlockhash;
    });
  }

  void _checkSimpleTokenAccount() async {}

  void _createAccount() async {
    try {
      final account = widget.provider.connectedAccount!;
      final payerPubkey = Pubkey.fromBase64(account.address);
      print('Payer Pubkey: ${payerPubkey}');

      final List<AccountMeta> keys = [
        AccountMeta(payerPubkey, isSigner: true, isWritable: true),
        AccountMeta(_userClaimTrackerPubkey, isSigner: false, isWritable: true),
        AccountMeta(SystemProgram.programId,
            isSigner: false, isWritable: false),
      ];

      final Uint8List disc =
          Uint8List.fromList([68, 52, 156, 251, 174, 166, 95, 4]);

      final TransactionInstruction ix = TransactionInstruction(
        programId: programId,
        keys: keys,
        data: disc,
      );

      final Message msg = Message.compile(
        version: 0,
        payer: payerPubkey,
        recentBlockhash: _recentBlockhash,
        instructions: [ix],
      );

      final Transaction tx = Transaction(message: msg);

      // Sign and send the transaction and capture the signature
      final signature = await widget.provider
          .signAndSendTransactions(context, transactions: [tx]);
      print('Transaction signature: ${signature.signatures}');
    } catch (e) {
      print('Failed to create account: $e');
    }
  }

  void _execute() async {
    final account = widget.provider.connectedAccount!;
    final payerPubkey = Pubkey.fromBase64(account.address);

    final List<AccountMeta> keys = [
      AccountMeta(payerPubkey, isSigner: true, isWritable: true),
      AccountMeta(percentTrackerPda, isSigner: false, isWritable: true),
    ];

    final Uint8List disc = Uint8List.fromList([130, 221, 242, 154, 13, 193, 189, 29]);

    final TransactionInstruction ix = TransactionInstruction(
        programId: programId,
        keys: keys,
        data: disc,
    );

    final Message msg = Message.compile(version: 0, payer: payerPubkey, instructions: [ix], recentBlockhash: _recentBlockhash);

    final Transaction tx = Transaction(message: msg);

    final signature = await widget.provider.signAndSendTransactions(context, transactions: [tx]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Protocol Page'),
      ),
      body: Column(
        children: [
          _hasClaimTrackerAccount == false
              ? ElevatedButton(
                  onPressed: _createAccount,
                  child: Text('Create your Claim Tracker Account'),
                )
              : Text('Claim Tracker Account already exists.'),
          ElevatedButton(onPressed: _execute, child: Text("Execute"),)
        ],
      ),
    );
  }
}
