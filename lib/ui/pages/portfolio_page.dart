import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:simple/apis/price.dart';
import 'package:simple/apis/token.dart';
import 'package:simple/common.dart';
import 'package:simple/domain/vs_tokens.dart';
import 'package:simple/ui/elements/token_info.dart';
import 'package:solana_wallet_provider/solana_wallet_provider.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({
    super.key,
    required this.allFungibleTokens,
    required this.userPubkey,
    required this.userLabel,
    required this.userSolanaBalance,
    required this.userTotalStakedSolanaBalance,
    required this.userAllWalletTokenAccountsWithBalances,
    required this.userAllWalletTokenAccountsWithMints,
    required this.provider,
  });

  final List<TokenModel> allFungibleTokens;
  final SolanaWalletProvider provider;
  final Pubkey userPubkey;
  final String userLabel;
  final double userSolanaBalance;
  final double userTotalStakedSolanaBalance;
  final Map<String, String> userAllWalletTokenAccountsWithMints;
  final Map<String, double> userAllWalletTokenAccountsWithBalances;

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  late Timer _timer;

  List<TokenModel> _allFungibleTokensInWallet = [];
  List<String> _allNftsInWallet = [];

  String? _concatenatedTokenAddresses;
  Map<String, double> _allFungibleTokenMintsWithBalancesInWallet = {};

  TokenModel _vsToken = vsTokens.USDC.token;

  double? _solanaPrice;
  double? _walletSolanaValue;
  double? _walletTotalStakedSolanaValue;

  double? _penultimateWalletTotalValue;
  double? _walletTotalValue;
  double? _valueDifference;

  Map<String, double> _tokenPrices = {};

  Color _differenceColor = Colors.white;

  @override
  void dispose() {
    super.dispose();

    _timer.cancel();
  }

  @override
  void initState() {
    super.initState();

    _initializePortfolio();

    if (_valueDifference != null) {
      _differenceColor = _valueDifference! > 0
          ? Colors.greenAccent
          : (_valueDifference! < 0 ? Colors.redAccent : Colors.white);
    }
  }

  void _initializePortfolio() {
    _getAllFungibleAndNonFungibleTokensInWallet();

    setState(() {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _getPricesAndUpdateValueInfo(_vsToken);
      });
    });
  }

  void _getAllFungibleAndNonFungibleTokensInWallet() async {
    List<TokenModel> allFungibleTokensInWallet = [];

    allFungibleTokensInWallet = widget.allFungibleTokens.where((token) {
      return widget.userAllWalletTokenAccountsWithMints.values
          .contains(token.mint);
    }).toList();

    List<String> allNftsInWallet = [];

    Set<String> allFungibleTokenMints =
        widget.allFungibleTokens.map((token) => token.mint).toSet();

    widget.userAllWalletTokenAccountsWithBalances
        .forEach((tokenAccount, balance) {
      if (balance == 1.0) {
        var mint = widget.userAllWalletTokenAccountsWithMints[tokenAccount];

        if (!allFungibleTokenMints.contains(mint)) {
          allNftsInWallet.add(mint!);
        }
      }
    });

    Map<String, double> allFungibleTokenMintsWithBalancesInWallet = {};

    for (var token in allFungibleTokensInWallet) {
      var tokenAccount =
          widget.userAllWalletTokenAccountsWithMints.entries.firstWhere(
        (entry) => entry.value == token.mint,
      );
      var balance =
          widget.userAllWalletTokenAccountsWithBalances[tokenAccount.key];
      allFungibleTokenMintsWithBalancesInWallet[token.mint] = balance!;
    }

    setState(() {
      if (allFungibleTokensInWallet.isNotEmpty) {
        _allFungibleTokensInWallet = allFungibleTokensInWallet;
      }

      if (allNftsInWallet.isNotEmpty) {
        _allNftsInWallet = allNftsInWallet;
      }

      if (allFungibleTokenMintsWithBalancesInWallet.isNotEmpty) {
        _concatenatedTokenAddresses =
            allFungibleTokenMintsWithBalancesInWallet.keys.join(',');

        _allFungibleTokenMintsWithBalancesInWallet =
            allFungibleTokenMintsWithBalancesInWallet;
      }
    });
  }

  void _getPricesAndUpdateValueInfo(TokenModel vsToken) async {
    final solanaPrice =
        await fetchPrice(vsTokens.WSOL.token.mint, vsToken.mint);

    Map<String, double> tokenPrices = {};

    if (_concatenatedTokenAddresses != null) {
      tokenPrices =
          await fetchPrices(_concatenatedTokenAddresses!, vsToken.mint);
    }

    setState(() {
      _solanaPrice = solanaPrice;

      if (tokenPrices.isNotEmpty) {
        _tokenPrices = tokenPrices;
      }

      _updateValueInfo();
    });
  }

  void _updateValueInfo() {
    double? otherTokensValue;

    if (_tokenPrices.isNotEmpty) {
      otherTokensValue = _allFungibleTokensInWallet.fold(0.0, (sum, token) {
        double tokenBalance =
            _allFungibleTokenMintsWithBalancesInWallet[token.mint]!;
        double tokenPrice = _tokenPrices[token.mint]!;
        double tokenValue = tokenBalance * tokenPrice;
        return sum! + tokenValue;
      });
    } else {
      otherTokensValue = 0.0;
    }

    setState(() {
      // don't do if _walletTotalValue is not null bc the value difference needs to not print the first one
      _penultimateWalletTotalValue = _walletTotalValue ?? 0;

      if (_solanaPrice != null) {
        _walletSolanaValue = widget.userSolanaBalance * _solanaPrice!;
      }

      if (_solanaPrice != null) {
        _walletTotalStakedSolanaValue =
            widget.userTotalStakedSolanaBalance * _solanaPrice!;
      }

      if (_walletSolanaValue != null && otherTokensValue != null) {
        _walletTotalValue = _walletSolanaValue! +
            _walletTotalStakedSolanaValue! +
            otherTokensValue;
      }

      if (_walletTotalValue != null && _penultimateWalletTotalValue != null) {
        _valueDifference = _walletTotalValue! - _penultimateWalletTotalValue!;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned(
            top: screenHeight * 0.035,
            left: 0,
            child: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text("Synch da boi"),
                    content: const Text(
                        "Please reconnect wallet if you left and made a trade and came back."),
                    actions: <Widget>[
                      TextButton(
                        child: const Text(
                          "Cool",
                          style: TextStyle(color: Colors.black),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Center(
            child: _walletTotalValue != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: screenHeight * 0.06),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userLabel,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            GestureDetector(
                              onLongPress: () {
                                Clipboard.setData(ClipboardData(
                                    text: widget.userPubkey.toString()));
                              },
                              child: Text(
                                widget.userPubkey.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              '${_vsToken.unicodeSymbol}${defaultNumberFormat.format(_walletTotalValue)}',
                              style: const TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.start,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${_vsToken.unicodeSymbol}${defaultNumberFormat.format(_valueDifference != _walletTotalValue ? _valueDifference : 0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _differenceColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Card(
                                  color: Colors.grey[900],
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TokenInfo(
                                            allFungibleTokens:
                                                widget.allFungibleTokens,
                                            token: vsTokens.WSOL.token,
                                          ),
                                        ),
                                      );
                                    },
                                    child: ListTile(
                                      leading: ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: vsTokens.WSOL.token.logo,
                                          height: 35.0,
                                          width: 35.0,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      title: const Text(
                                        'Solana',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${_vsToken.unicodeSymbol}${defaultNumberFormat.format(_solanaPrice)} - ${defaultNumberFormat.format(widget.userSolanaBalance)}',
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                      trailing: Text(
                                        '${_vsToken.unicodeSymbol}${defaultNumberFormat.format(_walletSolanaValue)}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )),
                              if (widget.userTotalStakedSolanaBalance != 0)
                                Card(
                                    color: Colors.grey[900],
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => TokenInfo(
                                              token: vsTokens.WSOL.token,
                                              allFungibleTokens:
                                                  widget.allFungibleTokens,
                                            ),
                                          ),
                                        );
                                      },
                                      child: ListTile(
                                        leading: ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: vsTokens.WSOL.token.logo,
                                            height: 35.0,
                                            width: 35.0,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        title: const Text(
                                          'Staked Solana',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        subtitle: Text(
                                          defaultNumberFormat.format(widget
                                              .userTotalStakedSolanaBalance),
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        trailing: Text(
                                          '${_vsToken.unicodeSymbol}${defaultNumberFormat.format(_walletTotalStakedSolanaValue)}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    )),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10.0, horizontal: 8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900],
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(10.0)),
                                  ),
                                  padding: const EdgeInsets.all(8.0),
                                  child: const Text(
                                    'Tokens',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              ..._allFungibleTokensInWallet.map((token) {
                                double tokenBalance =
                                    _allFungibleTokenMintsWithBalancesInWallet[
                                        token.mint]!;
                                double tokenPrice = _tokenPrices[token.mint]!;
                                return Card(
                                    color: Colors.grey[900],
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => TokenInfo(
                                              token: token,
                                              allFungibleTokens:
                                                  widget.allFungibleTokens,
                                            ),
                                          ),
                                        );
                                      },
                                      child: ListTile(
                                        leading: ClipOval(
                                          child: token.logo.endsWith('.svg')
                                              ? SvgPicture.network(
                                                  token.logo,
                                                  placeholderBuilder:
                                                      (context) => Container(
                                                    width: 35.0,
                                                    height: 35.0,
                                                    decoration:
                                                        const BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.grey,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        token.name[0],
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                                  height: 35.0,
                                                  width: 35.0,
                                                )
                                              : CachedNetworkImage(
                                                  imageUrl: token.logo,
                                                  placeholder: (context, url) =>
                                                      Container(
                                                    width: 35.0,
                                                    height: 35.0,
                                                    decoration:
                                                        const BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.grey,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        token.name[0],
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          Container(
                                                    width: 35.0,
                                                    height: 35.0,
                                                    decoration:
                                                        const BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.grey,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        token.name[0],
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                                  height: 35.0,
                                                  width: 35.0,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                        title: Text(
                                          token.symbol,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${_vsToken.unicodeSymbol}${defaultNumberFormat.format(tokenPrice)} - ${defaultNumberFormat.format(tokenBalance)}',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        trailing: Text(
                                          '${_vsToken.unicodeSymbol}${defaultNumberFormat.format(tokenBalance * tokenPrice)}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ));
                              }),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10.0, horizontal: 8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900], // Background color
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(
                                            10.0)), // Rounded border
                                  ),
                                  padding: const EdgeInsets.all(
                                      8.0), // Padding inside the container
                                  child: const Text(
                                    'NFTs',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              ..._allNftsInWallet.map((mint) {
                                return GestureDetector(
                                  onLongPress: () {
                                    Clipboard.setData(
                                        ClipboardData(text: mint));
                                  },
                                  child: Card(
                                    color: Colors.grey[900],
                                    child: ListTile(
                                      title: Text(
                                        mint,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: vsTokens.values.map((t) {
                          return TextButton(
                            onPressed: () {
                              if (t.token == _vsToken) {
                                return;
                              }

                              setState(() {
                                _walletTotalValue = null;
                                _vsToken = t.token;
                              });

                              _getPricesAndUpdateValueInfo(t.token);
                            },
                            child: Text(
                              t.token.unicodeSymbol!,
                              style: TextStyle(
                                fontSize: 18,
                                color: _vsToken == t.token
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
          ),
        ],
      ),
    );
  }
}
