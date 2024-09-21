import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:simple/common.dart';
import 'package:solana_wallet_provider/solana_wallet_provider.dart';

final Pubkey programId =
    Pubkey.fromBase58('6yUtbQXotEAbzJBHLghordn9r3vZ8wRuCbFBxMaatVoF');
final Pubkey percentTrackerPda =
    Pubkey.fromBase58('ASkwiutgrohdg1DEs6RYbjk5gcCH3dCEbSTMyCTRFxjw');
final Pubkey wsolBalancePda =
    Pubkey.fromBase58('HqAvkCgG7dUtPAbSaQQWB1zwoKCUxiZPzThoKybR94hn');
final Pubkey transferAuthorityPda =
    Pubkey.fromBase58('AbjgWPYQi5Qg4gKu6aRDp3yZCkBTQS1Rst4x9bZ6eHuc');
final Pubkey programSimpleTokenAccount =
    Pubkey.fromBase58('G1WbUJDHZZXXYxXsdnJPsgM3noyXCbD9Dt57Lq79f5hH');
final Pubkey raydiumPoolWsolTokenAccount =
    Pubkey.fromBase58('364AQ7xZsUn3R9qkYSDVks1W6pfiXzZosJjZ6o7gv9by');
final Pubkey creatorSimpleTokenAccount =
    Pubkey.fromBase58('5LEXeqv44X21oCBybV74ZTQCVKLtX1iL5474gSUjWwrx');
final Pubkey raydiumLpMint =
    Pubkey.fromString('52Pbw9eUXkuMsw1KJKdYtkBEPt94D8RL8Ko29Hrqsb2X');

class ProtocolPage extends StatefulWidget {
  const ProtocolPage(
      {super.key, required this.provider, required this.userPubkey});

  final Pubkey userPubkey;
  final SolanaWalletProvider provider;

  @override
  State<ProtocolPage> createState() => _ProtocolPageState();
}

class _ProtocolPageState extends State<ProtocolPage> {
  bool _hasClaimTrackerAccount = false;
  bool _hasSimpleTokenAccount = false;

  Pubkey? _userClaimTrackerPubkey;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _checkClaimTracker();
  }

  void _checkClaimTracker() async {
    final ProgramAddress userClaimTrackerPdaInfo = Pubkey.findProgramAddress(
      [
        widget.userPubkey.toBytes(),
      ],
      programId,
    );

    setState(() {
      _userClaimTrackerPubkey = userClaimTrackerPdaInfo.pubkey;
    });
  }

  void _checkSimpleTokenAccount() async {}

  void _createAccount() async {
    try {
      final BlockhashWithExpiryBlockHeight recentBlockhashResponse =
          await widget.provider.connection.getLatestBlockhash();
      final String recentBlockhash = recentBlockhashResponse.blockhash;

      final List<AccountMeta> keys = [
        AccountMeta(widget.userPubkey, isSigner: true, isWritable: true),
        AccountMeta(PHmyUserClaimTracker, isSigner: false, isWritable: true),
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
        payer: widget.userPubkey,
        recentBlockhash: recentBlockhash,
        instructions: [ix],
      );

      final Transaction tx = Transaction(message: msg);

      if (mounted) {
        widget.provider.signAndSendTransactions(context, transactions: [tx]);
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _execute() async {
    try {
      final BlockhashWithExpiryBlockHeight recentBlockhashResponse =
          await widget.provider.connection.getLatestBlockhash();
      final String recentBlockhash = recentBlockhashResponse.blockhash;

      final List<AccountMeta> keys = [
        AccountMeta(widget.userPubkey, isSigner: true, isWritable: true),
        AccountMeta(percentTrackerPda, isSigner: false, isWritable: true),
        AccountMeta(wsolBalancePda, isSigner: false, isWritable: true),
        AccountMeta(transferAuthorityPda, isSigner: false, isWritable: false),
        AccountMeta(programSimpleTokenAccount,
            isSigner: false, isWritable: true),
        AccountMeta(PHmyUserClaimTracker, isSigner: false, isWritable: true),
        AccountMeta(PHmySimpleAccount, isSigner: false, isWritable: true),
        AccountMeta(PHmyRaydiumLPAta, isSigner: false, isWritable: false),
        AccountMeta(raydiumPoolWsolTokenAccount,
            isSigner: false, isWritable: false),
        AccountMeta(creatorSimpleTokenAccount,
            isSigner: false, isWritable: true),
        AccountMeta(Pubkey.fromString(simpleTokenMint),
            isSigner: false, isWritable: false),
        AccountMeta(raydiumLpMint, isSigner: false, isWritable: false),
        AccountMeta(TokenProgram.programId, isSigner: false, isWritable: false),
      ];

      final Uint8List disc =
          Uint8List.fromList([130, 221, 242, 154, 13, 193, 189, 29]);

      final TransactionInstruction ix = TransactionInstruction(
        programId: programId,
        keys: keys,
        data: disc,
      );

      final Message msg = Message.compile(
          version: 0,
          payer: widget.userPubkey,
          instructions: [ix],
          recentBlockhash: recentBlockhash);

      final Transaction tx = Transaction(message: msg);

      if (mounted) {
        widget.provider.signAndSendTransactions(context, transactions: [tx]);
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: _createAccount,
            child: Text('Create your Claim Tracker Account'),
          ),
          ElevatedButton(
            onPressed: _createAccount,
            child: Text('Create your Simple Token Account'),
          ),
          ElevatedButton(
            onPressed: _execute,
            child: Text("Execute"),
          )
        ],
      ),
    );
  }
}
