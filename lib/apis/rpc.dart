import 'dart:typed_data';
import 'package:simple/common.dart';
import 'package:solana/base58.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

Future<double> fetchAccountSolanaBalance(String accountPubkey) async {
  try {
    final accountBalance = await mainnetClient.getBalance(accountPubkey);

    return (accountBalance.value / lamportsPerSol);
  } catch (e) {
    throw Exception('Error fetching SOL balance in wallet: $e');
  }
}

Future<double> fetchAccountTotalStakedSol(String accountPubkey) async {
  const encoding = Encoding.base64;

  final filters = [
    ProgramDataFilter.memcmp(offset: 44, bytes: base58decode(accountPubkey))
  ];

  try {
    final response = await mainnetClient.getProgramAccounts(stakeProgramId,
        encoding: encoding, filters: filters);

    if (response.isEmpty) {
      return 0.0;
    }

    double totalStakedSol = 0.0;

    for (var account in response) {
      totalStakedSol += account.account.lamports / lamportsPerSol;
    }

    return totalStakedSol;
  } catch (e) {
    throw Exception('Error fetching staked SOL balance in wallet: $e');
  }
}

Future<List<ProgramAccount>> fetchTokenAccounts(String accountPubkey) async {
  const filter = TokenAccountsFilter.byProgramId(tokenProgramId);

  const encoding = Encoding.base64;

  try {
    final tokenAccounts = await mainnetClient
        .getTokenAccountsByOwner(accountPubkey, filter, encoding: encoding);

    return tokenAccounts.value;
  } catch (e) {
    throw Exception('Token fetch error: $e');
  }
}

Future<List<ProgramAccount>> fetchToken2022Accounts(
    String accountPubkey) async {
  const filter = TokenAccountsFilter.byProgramId(token2022ProgramId);

  const encoding = Encoding.base64;

  try {
    final tokenAccounts = await mainnetClient
        .getTokenAccountsByOwner(accountPubkey, filter, encoding: encoding);

    return tokenAccounts.value;
  } catch (e) {
    throw Exception('Token 2022 fetch error: $e');
  }
}

Future<double> fetchTokenAccountBalance(String tokenAccountPubkey) async {
  try {
    final tokenAccountBalance =
        await mainnetClient.getTokenAccountBalance(tokenAccountPubkey);

    return double.parse(tokenAccountBalance.value.uiAmountString!);
  } catch (e) {
    throw Exception('Failed fetching token account balances: $e');
  }
}

Future<double> fetchSolSupply() async {
  try {
    final solanaSupply = await mainnetClient.getSupply();
    final int lamportsSupply = solanaSupply.value.total;
    return lamportsSupply / lamportsPerSol;
  } catch (e) {
    throw Exception('Error fetching Solana supply: $e');
  }
}

class TokenAccountInfo {
  final String mint;
  final String owner;
  final BigInt amount;

  TokenAccountInfo(
      {required this.mint, required this.owner, required this.amount});
}

TokenAccountInfo parseTokenAccount(Uint8List data) {
  if (data.length < 165) {
    throw Exception('Invalid token account data');
  }

  String mint = base58encode(data.sublist(0, 32));
  String owner = base58encode(data.sublist(32, 64));
  BigInt amount =
      BigInt.from(data.buffer.asByteData().getUint64(64, Endian.little));

  return TokenAccountInfo(mint: mint, owner: owner, amount: amount);
}
