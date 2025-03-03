import 'dart:convert';
import 'package:simple/common.dart';
import 'package:http/http.dart' as http;

class TokenModel {
  final String mint;
  final String name;
  final String symbol;
  final String logo;
  final String? unicodeSymbol;

  const TokenModel({
    required this.mint,
    required this.name,
    required this.symbol,
    required this.logo,
    this.unicodeSymbol,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
        mint: json['address'] ?? 'Unknown Address',
        name: json['name'] ?? 'Unknown Name',
        symbol: json['symbol'] ?? 'Unknown Symbol',
        logo: json['logoURI'] ??
            'https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/So11111111111111111111111111111111111111112/logo.png');
  }

  Future<double> fetchSupply() async {
    try {
      final tokenSupplyResult = await mainnetClient.getTokenSupply(mint);

      final double tokenSupply =
          double.parse(tokenSupplyResult.value.uiAmountString!);
      return tokenSupply;
    } catch (e) {
      throw ('Error fetching token supply: $e');
    }
  }
}

Future<List<TokenModel>> fetchAllFungibleTokens() async {
  final url = Uri.parse(jupAllTokensUri);

  try {
    final response = await http.get(url);
    final data = json.decode(response.body) as List<dynamic>;

    return data.map((token) => TokenModel.fromJson(token)).toList();
  } catch (e) {
    throw Exception('Failed fetching all fungible tokens: $e');
  }
}
