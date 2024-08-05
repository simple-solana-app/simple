import 'dart:typed_data';

import 'package:simple/domain/common.dart';
import 'package:solana_web3/solana_web3.dart' as web3;

//TODO check for user claim tracker account, create if doesn't exist,
//check for user simple associated token account, create if doesn't exists
Future<String> invokeProgram() async {
  final connection = web3.Connection(web3.Cluster.devnet);
  final recentBlockhashResponse = await connection.getLatestBlockhash();
  final recentBlockhash = recentBlockhashResponse.blockhash;

  final user = await web3.Keypair.generate();

  //
  final airdropSignature = await connection.requestAirdrop(
    user.pubkey,
    1000000000,
  );
  await connection.confirmTransaction(airdropSignature);
  //

  final instruction = web3.TransactionInstruction(
    programId: programId,
    keys: [],
    data: Uint8List(0),
  );

  final message = web3.Message.compile(
    version: 0,
    payer: user.pubkey,
    instructions: [instruction],
    recentBlockhash: recentBlockhash,
  );

  final transaction = web3.Transaction(message: message);

  transaction.sign([user]);

  var tx = await connection.sendAndConfirmTransaction(transaction);

  return tx;
}
