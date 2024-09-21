import 'dart:convert';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:simple/apis/rpc.dart';
import 'package:simple/apis/token.dart';
import 'package:simple/common.dart';
import 'package:simple/ui/elements/dropdown_token_search.dart';
import 'package:simple/ui/pages/portfolio_page.dart';
import 'package:simple/ui/pages/protocol_page.dart';
import 'package:simple/ui/pages/tokens_page.dart';
import 'package:solana_wallet_provider/solana_wallet_provider.dart';
import 'package:solana/src/rpc/dto/program_account.dart' as SolLib;

class NavScreen extends StatefulWidget {
  const NavScreen({super.key, required this.provider});

  final SolanaWalletProvider provider;

  @override
  State<NavScreen> createState() => _NavScreenState();
}

class _NavScreenState extends State<NavScreen> {
  int _navIndex = 0;

  List<TokenModel>? allFungibleTokens;

  Pubkey? userPubkey;
  String? userLabel;

  double? userSolanaBalance;
  double? userTotalStakedSolanaBalance;

  Map<String, String> userAllWalletTokenAccountsWithMints = {};

  Pubkey? userSimpleTokenAccount;
  Map<String, double> userAllWalletTokenAccountsWithBalances = {};

  @override
  void initState() {
    super.initState();

    _getAllFungibleTokens();

    userPubkey = Pubkey.fromBase64(widget.provider.connectedAccount!.address);
    userLabel = widget.provider.connectedAccount!.label!;
    _getUserWalletInfo();
  }

  void _getAllFungibleTokens() async {
    var tokens = await fetchAllFungibleTokens();

    setState(() {
      allFungibleTokens = tokens;
    });
  }

  void _getUserWalletInfo() async {
    if (userPubkey != null) {
      final double sol = await fetchAccountSolanaBalance(userPubkey.toString());

      userSolanaBalance = sol;

      final double stakedSol =
          await fetchAccountTotalStakedSol(userPubkey.toString());

      userTotalStakedSolanaBalance = stakedSol;

      List<SolLib.ProgramAccount> tokenAccounts =
          await fetchTokenAccounts(userPubkey.toString());
      Map<String, dynamic> walletTokenAccountsWithMints = {};

      if (tokenAccounts.isNotEmpty) {
        for (var tokenAccount in tokenAccounts) {
          var tokenAccountPubkey = tokenAccount.pubkey;
          var tokenAccountInfoRaw = tokenAccount.account.data?.toJson();

          for (var act in tokenAccountInfoRaw) {
            try {
              var decodedData = base64.decode(act);
              var tokenAccountInfo = parseTokenAccount(decodedData);

              walletTokenAccountsWithMints[tokenAccountPubkey] =
                  tokenAccountInfo.mint;
            } catch (_) {
              continue;
            }
          }
        }
      }

      List<SolLib.ProgramAccount> token2022Accounts =
          await fetchToken2022Accounts(userPubkey.toString());
      Map<String, dynamic> walletToken2022AccountsWithMints = {};

      if (token2022Accounts.isNotEmpty) {
        for (var token2022Account in token2022Accounts) {
          var token2022AccountPubkey = token2022Account.pubkey;
          var token2022AccountInfoRaw = token2022Account.account.data?.toJson();

          for (var act in token2022AccountInfoRaw) {
            try {
              var decodedData = base64.decode(act);
              var token2022AccountInfo = parseTokenAccount(decodedData);

              walletToken2022AccountsWithMints[token2022AccountPubkey] =
                  token2022AccountInfo.mint;
            } catch (_) {
              continue;
            }
          }
        }
      }

      userAllWalletTokenAccountsWithMints = {
        ...walletTokenAccountsWithMints,
        ...walletToken2022AccountsWithMints
      };

      for (var entry in userAllWalletTokenAccountsWithMints.entries) {
        if (entry.value == simpleTokenMint) {
          userSimpleTokenAccount = Pubkey.fromString(entry.key);
          break;
        }
      }

      for (var key in userAllWalletTokenAccountsWithMints.keys) {
        var tokenAccountBalance = await fetchTokenAccountBalance(key);
        userAllWalletTokenAccountsWithBalances[key] = tokenAccountBalance;
      }
    }
  }

  void _showInfoDialog(final BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
              'Bomboclaat!'), // meant to be seen as funny not offensize even though it mean dirty undergarment
          content: const Text(
              'Please ensure that Chrome is set as your default browser on your device in order to be able to use your wallet with jup.ag.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cool',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showTokenSearchDialog(final BuildContext context) {
    showDialog(
        context: context,
        builder: (context) =>
            DropDownTokenSearch(allFungibleTokens: allFungibleTokens!));
  }

  void _launchJupAgUrl(final BuildContext context) async {
    const url = 'https://jup.ag/';

    AndroidIntent intent = const AndroidIntent(
      action: 'action_view',
      data: url,
      package: 'com.android.chrome',
    );

    await intent.launch();
  }

  Future<void> _disconnect(
      final BuildContext context, final SolanaWalletProvider provider) async {
    await provider.disconnect(context);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    if (allFungibleTokens == null ||
        userPubkey == null ||
        userLabel == null ||
        userSolanaBalance == null ||
        userTotalStakedSolanaBalance == null ||
        userAllWalletTokenAccountsWithMints.isEmpty ||
        userAllWalletTokenAccountsWithBalances.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: IndexedStack(
                        index: _navIndex,
                        children: [
                          TokensPage(
                            allFungibleTokens: allFungibleTokens!,
                          ),
                          ProtocolPage(
                            userPubkey: userPubkey!,
                            provider: widget.provider,
                          ),
                          PortfolioPage(
                            allFungibleTokens: allFungibleTokens!,
                            userPubkey: userPubkey!,
                            userLabel: userLabel!,
                            userSolanaBalance: userSolanaBalance!,
                            userTotalStakedSolanaBalance:
                                userTotalStakedSolanaBalance!,
                            userAllWalletTokenAccountsWithMints:
                                userAllWalletTokenAccountsWithMints,
                            userAllWalletTokenAccountsWithBalances:
                                userAllWalletTokenAccountsWithBalances,
                            provider: widget.provider,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.13),
                  ],
                ),
                Positioned(
                  bottom: screenHeight * 0.07,
                  left: screenWidth * 0.43,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _navIndex = 0;
                    }),
                    style: ButtonStyle(
                      foregroundColor: _navIndex == 0
                          ? WidgetStateProperty.all<Color>(Colors.white)
                          : WidgetStateProperty.all<Color>(Colors.grey),
                    ),
                    child: const Text(
                      "Tokens",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                Positioned(
                  bottom: screenHeight * 0.040,
                  left: screenWidth * 0.45,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _navIndex = 1;
                    }),
                    style: ButtonStyle(
                      foregroundColor: _navIndex == 1
                          ? WidgetStateProperty.all<Color>(Colors.white)
                          : WidgetStateProperty.all<Color>(Colors.grey),
                    ),
                    child: const Text(
                      "Protocol",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                Positioned(
                  bottom: screenHeight * 0.01,
                  left: screenWidth * 0.440,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _navIndex = 2;
                    }),
                    style: ButtonStyle(
                      foregroundColor: _navIndex == 2
                          ? WidgetStateProperty.all<Color>(Colors.white)
                          : WidgetStateProperty.all<Color>(Colors.grey),
                    ),
                    child: const Text(
                      "Portfolio",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                Positioned(
                  bottom: screenHeight * 0.03,
                  left: screenWidth * 0.30,
                  child: GestureDetector(
                    onTap: () => _launchJupAgUrl(context),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/jup_icon.png',
                        height: 60.0,
                        width: 60.0,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: screenHeight * 0.08,
                  left: screenWidth * 0.24,
                  child: GestureDetector(
                    onTap: () => _showInfoDialog(context),
                    child: const Icon(Icons.info_outline,
                        color: Colors.grey, size: 20),
                  ),
                ),
                Positioned(
                  bottom: screenHeight * 0.018,
                  left: screenWidth * 0.22,
                  child: GestureDetector(
                    onTap: () => _showTokenSearchDialog(context),
                    child:
                        const Icon(Icons.search, color: Colors.grey, size: 37),
                  ),
                ),
                Positioned(
                  top: screenHeight * 0.05,
                  right: screenWidth * 0.02,
                  child: TextButton(
                    onPressed: () => _disconnect(context, widget.provider),
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.all<Color>(Colors.transparent),
                      side: WidgetStateProperty.all<BorderSide>(
                        const BorderSide(color: Colors.white, width: 1.0),
                      ),
                    ),
                    child: const Text(
                      'Disconnect',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
