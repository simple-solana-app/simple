import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:simple/apis/price.dart';
import 'package:simple/apis/rpc.dart';
import 'package:simple/apis/token.dart';
import 'package:simple/domain/common.dart';
import 'package:simple/domain/vs_tokens.dart';
import 'package:simple/ui/elements/token_info.dart';
import 'package:solana/dto.dart';

class PortfolioPage extends StatefulWidget {
  final List<TokenModel> allFungibleTokens;

  final String walletLabel;
  final String walletAddress;

  const PortfolioPage({
    super.key,
    required this.allFungibleTokens,
    required this.walletLabel,
    required this.walletAddress,
  });

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  late Timer _timer;

  double? _walletSolanaBalance;
  double? _walletTotalStakedSolana;

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

  @override
  void dispose() {
    super.dispose();

    _timer.cancel();
  }

  @override
  void initState() {
    super.initState();

    _initalizePortfolio();
  }

  void _initalizePortfolio() async {
    _getWalletSolanaBalance();
    _getWalletTotalStakedSolana();

    _getAllFungibleAndNonFungibleTokensInWallet();

    if (mounted) {
      setState(() {
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
          await _getPricesAndUpdateValueInfo(_vsToken);
        });
      });
    }
  }

  void _getWalletSolanaBalance() async {
    double walletSolanaBalance =
        await fetchAccountSolanaBalance(widget.walletAddress);

    if (mounted) {
      setState(() {
        _walletSolanaBalance = walletSolanaBalance;
      });
    }
  }

  void _getWalletTotalStakedSolana() async {
    double walletTotalStakedSolana =
        await fetchAccountTotalStakedSol(widget.walletAddress);

    if (mounted) {
      setState(() {
        _walletTotalStakedSolana = walletTotalStakedSolana;
      });
    }
  }

  void _getAllFungibleAndNonFungibleTokensInWallet() async {
    List<ProgramAccount> tokenAccounts =
        await fetchTokenAccounts(widget.walletAddress);
    Map<String, dynamic> walletTokenAccountsWithMints = {};

    if (tokenAccounts.isNotEmpty) {
      for (var tokenAccount in tokenAccounts) {
        var tokenAccountAddress = tokenAccount.pubkey;
        var accountInfo = tokenAccount.account.data?.toJson();

        for (var act in accountInfo) {
          try {
            var decodedData = base64.decode(act);
            var tokenAccountInfo =
                parseTokenAccount(Uint8List.fromList(decodedData));

            walletTokenAccountsWithMints[tokenAccountAddress] =
                tokenAccountInfo.mint;
          } catch (_) {
            continue;
          }
        }
      }
    }

    List<ProgramAccount> token2022Accounts =
        await fetchToken2022Accounts(widget.walletAddress);
    Map<String, dynamic> walletToken2022AccountsWithMints = {};

    if (token2022Accounts.isNotEmpty) {
      for (var token2022Account in token2022Accounts) {
        var token2022AccountAddress = token2022Account.pubkey;
        var accountInfo = token2022Account.account.data?.toJson();
        for (var act in accountInfo) {
          try {
            var decodedData = base64.decode(act);
            var token2022AccountInfo =
                parseTokenAccount(Uint8List.fromList(decodedData));

            walletToken2022AccountsWithMints[token2022AccountAddress] =
                token2022AccountInfo.mint;
          } catch (_) {
            continue;
          }
        }
      }
    }

    Map<String, dynamic> allWalletTokenAccountsWithMints = {
      ...walletTokenAccountsWithMints,
      ...walletToken2022AccountsWithMints
    };

    List<TokenModel> allFungibleTokensInWallet = [];

    if (allWalletTokenAccountsWithMints.isNotEmpty) {
      allFungibleTokensInWallet = widget.allFungibleTokens.where((token) {
        return allWalletTokenAccountsWithMints.values.contains(token.mint);
      }).toList();
    }

    Map<String, double> allWalletTokenAccountsWithBalances = {};

    if (allWalletTokenAccountsWithMints.isNotEmpty) {
      for (var tokenAccount in allWalletTokenAccountsWithMints.keys) {
        var tokenAccountBalance = await fetchTokenAccountBalance(tokenAccount);

        allWalletTokenAccountsWithBalances[tokenAccount] = tokenAccountBalance;
      }
    }

    List<String> allNftsInWallet = [];

    Set<String> allFungibleTokenMints =
        widget.allFungibleTokens.map((token) => token.mint).toSet();

    allWalletTokenAccountsWithBalances.forEach((tokenAccount, balance) {
      if (balance == 1.0) {
        var mint = allWalletTokenAccountsWithMints[tokenAccount];

        if (!allFungibleTokenMints.contains(mint)) {
          allNftsInWallet.add(mint);
        }
      }
    });

    Map<String, double> allFungibleTokenMintsWithBalancesInWallet = {};

    for (var token in allFungibleTokensInWallet) {
      var tokenAccount = allWalletTokenAccountsWithMints.entries.firstWhere(
        (entry) => entry.value == token.mint,
      );
      var balance = allWalletTokenAccountsWithBalances[tokenAccount.key];
      allFungibleTokenMintsWithBalancesInWallet[token.mint] = balance!;
    }

    if (mounted) {
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
  }

  Future<void> _getPricesAndUpdateValueInfo(TokenModel vsToken) async {
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

      if (_walletSolanaBalance != null && _solanaPrice != null) {
        _walletSolanaValue = _walletSolanaBalance! * _solanaPrice!;
      }

      if (_walletTotalStakedSolana != null && _solanaPrice != null) {
        _walletTotalStakedSolanaValue =
            _walletTotalStakedSolana! * _solanaPrice!;
      }

      if (_walletSolanaValue != null &&
          _walletTotalStakedSolana != null &&
          otherTokensValue != null) {
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
      body: _walletTotalValue != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.06),
                _buildWalletLabel(),
                _buildTotalWalletValue(),
                _buildPortfolio(),
                _buildVsTokenButtons(),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  Widget _buildWalletLabel() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.walletLabel,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: widget.walletAddress));
            },
            child: Text(
              widget.walletAddress,
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
    );
  }

  Widget _buildTotalWalletValue() {
    Color differenceColor = _valueDifference! > 0
        ? Colors.greenAccent
        : (_valueDifference! < 0 ? Colors.redAccent : Colors.white);

    return Row(
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
            color: differenceColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPortfolio() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSolanaCard(),
            if (_walletTotalStakedSolana != 0) _buildStakedSolanaCard(),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: const BorderRadius.all(Radius.circular(10.0)),
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
                  _allFungibleTokenMintsWithBalancesInWallet[token.mint]!;
              double tokenPrice = _tokenPrices[token.mint]!;
              return _buildFungibleTokenCard(token, tokenBalance, tokenPrice);
            }),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900], // Background color
                  borderRadius: const BorderRadius.all(
                      Radius.circular(10.0)), // Rounded border
                ),
                padding:
                    const EdgeInsets.all(8.0), // Padding inside the container
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
              return _buildNftCard(context, mint);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSolanaCard() {
    return Card(
        color: Colors.grey[900],
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TokenInfo(
                  allFungibleTokens: widget.allFungibleTokens,
                  token: vsTokens.WSOL.token,
                ),
              ),
            );
          },
          child: ListTile(
            leading: ClipOval(
              child: vsTokens.WSOL.token.logo.endsWith('.svg')
                  ? SvgPicture.network(
                      vsTokens.WSOL.token.logo,
                      placeholderBuilder: (context) => Container(
                        width: 35.0,
                        height: 35.0,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      height: 35.0,
                      width: 35.0,
                    )
                  : CachedNetworkImage(
                      imageUrl: vsTokens.WSOL.token.logo,
                      placeholder: (context, url) => Container(
                        width: 35.0,
                        height: 35.0,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 35.0,
                        height: 35.0,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                        ),
                        child: const Center(
                          child: Icon(Icons.error, color: Colors.red),
                        ),
                      ),
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
              '${_vsToken.unicodeSymbol}${defaultNumberFormat.format(_solanaPrice)} - ${defaultNumberFormat.format(_walletSolanaBalance)}',
              style: const TextStyle(color: Colors.white),
            ),
            trailing: Text(
              '${_vsToken.unicodeSymbol}${defaultNumberFormat.format(_walletSolanaValue)}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ));
  }

  Widget _buildStakedSolanaCard() {
    return Card(
        color: Colors.grey[900],
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TokenInfo(
                  token: vsTokens.WSOL.token,
                  allFungibleTokens: widget.allFungibleTokens,
                ),
              ),
            );
          },
          child: ListTile(
            leading: ClipOval(
              child: vsTokens.WSOL.token.logo.endsWith('.svg')
                  ? SvgPicture.network(
                      vsTokens.WSOL.token.logo,
                      placeholderBuilder: (context) => Container(
                        width: 35.0,
                        height: 35.0,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      height: 35.0,
                      width: 35.0,
                    )
                  : CachedNetworkImage(
                      imageUrl: vsTokens.WSOL.token.logo,
                      placeholder: (context, url) => Container(
                        width: 35.0,
                        height: 35.0,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 35.0,
                        height: 35.0,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                        ),
                        child: const Center(
                          child: Icon(Icons.error, color: Colors.red),
                        ),
                      ),
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
              defaultNumberFormat.format(_walletTotalStakedSolana),
              style: const TextStyle(color: Colors.white),
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
        ));
  }

  Widget _buildFungibleTokenCard(
      TokenModel token, double tokenBalance, double tokenPrice) {
    return Card(
        color: Colors.grey[900],
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TokenInfo(
                  token: token,
                  allFungibleTokens: widget.allFungibleTokens,
                ),
              ),
            );
          },
          child: ListTile(
            leading: ClipOval(
              child: token.logo.endsWith('.svg')
                  ? SvgPicture.network(
                      token.logo,
                      placeholderBuilder: (context) => Container(
                        width: 35.0,
                        height: 35.0,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                        ),
                        child: Center(
                          child: Text(
                            token.name[0],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      height: 35.0,
                      width: 35.0,
                    )
                  : CachedNetworkImage(
                      imageUrl: token.logo,
                      placeholder: (context, url) => Container(
                        width: 35.0,
                        height: 35.0,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                        ),
                        child: Center(
                          child: Text(
                            token.name[0],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 35.0,
                        height: 35.0,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                        ),
                        child: const Center(
                          child: Icon(Icons.error, color: Colors.red),
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
              style: const TextStyle(color: Colors.white),
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
  }

  Widget _buildNftCard(BuildContext context, String mint) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: mint));
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
  }

  Widget _buildVsTokenButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: vsTokens.values.map((vsToken) {
        return TextButton(
          onPressed: () {
            if (vsToken.token == _vsToken) {
              return;
            }

            setState(() {
              _walletTotalValue = null;
              _vsToken = vsToken.token;
            });
          },
          child: Text(
            vsToken.token.unicodeSymbol!,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        );
      }).toList(),
    );
  }
}
