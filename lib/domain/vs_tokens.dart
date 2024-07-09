// ignore_for_file: camel_case_types, constant_identifier_names

import 'package:simple/apis/token.dart';

enum vsTokens {
  WSOL(
    TokenModel(
        mint: "So11111111111111111111111111111111111111112",
        name: "Wrapped SOL",
        symbol: "WSOL",
        logo:
            "https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/So11111111111111111111111111111111111111112/logo.png",
        unicodeSymbol: "◎"),
  ),
  USDC(
    TokenModel(
        mint: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
        name: "USD Coin",
        symbol: "USDC",
        logo:
            "https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v/logo.png",
        unicodeSymbol: "\$"),
  ),
  WBTC(
    TokenModel(
      mint: "3NZ9JMVBmGAqocybic2c7LQCJScmgsAZ6vQqTDzcqmJh",
      name: "Wrapped BTC (Portal)",
      symbol: "WBTC",
      logo:
          "https://raw.githubusercontent.com/wormhole-foundation/wormhole-token-list/main/assets/WBTC_wh.png",
      unicodeSymbol: "₿",
    ),
  ),
  WETH(
    TokenModel(
      mint: "7vfCXTUXx5WJV5JADk17DUJ4ksgau7utNKj4b963voxs",
      name: "Ether (Portal)",
      symbol: "ETH",
      logo:
          "https://raw.githubusercontent.com/wormhole-foundation/wormhole-token-list/main/assets/ETH_wh.png",
      unicodeSymbol: "Ξ",
    ),
  );

  final TokenModel token;
  const vsTokens(this.token);
}
