import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:simple/apis/rpc.dart';
import 'package:simple/apis/token.dart';
import 'package:simple/ui/elements/dropdown_token_search.dart';
import 'package:simple/ui/pages/portfolio_page.dart';
import 'package:simple/ui/pages/protocol_page.dart';
import 'package:simple/ui/pages/tokens_page.dart';
import 'package:solana_wallet_provider/solana_wallet_provider.dart';

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

      setState(() {
        userSolanaBalance = sol;
      });

      final double stakedSol =
          await fetchAccountTotalStakedSol(userPubkey.toString());

      setState(() {
        userTotalStakedSolanaBalance = stakedSol;
      });
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
        userSolanaBalance == null) {
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
                            provider: widget.provider,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.13),
                  ],
                ),
                Positioned(
                  bottom: screenHeight * 0.08,
                  left: screenWidth * 0.252,
                  child: GestureDetector(
                    onTap: () => _showInfoDialog(context),
                    child: const Icon(Icons.info_outline,
                        color: Colors.white, size: 20),
                  ),
                ),
                Positioned(
                  bottom: screenHeight * 0.018,
                  left: screenWidth * 0.233,
                  child: GestureDetector(
                    onTap: () => _showTokenSearchDialog(context),
                    child:
                        const Icon(Icons.search, color: Colors.white, size: 37),
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
                  bottom: screenHeight * 0.068,
                  left: screenWidth * 0.425,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _navIndex = 0;
                    }),
                    child: const Text("Tokens",
                        style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
                Positioned(
                  bottom: screenHeight * 0.028,
                  left: screenWidth * 0.447,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _navIndex = 1;
                    }),
                    child: const Text("Protocol",
                        style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
                Positioned(
                  bottom: screenHeight * 0.0053,
                  left: screenWidth * 0.440,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _navIndex = 2;
                    }),
                    child: const Text("Portfolio",
                        style: TextStyle(fontSize: 18, color: Colors.white)),
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
                      foregroundColor:
                          WidgetStateProperty.all<Color>(Colors.white),
                      side: WidgetStateProperty.all<BorderSide>(
                        const BorderSide(color: Colors.white, width: 1.0),
                      ),
                    ),
                    child: const Text(
                      'Disconnect',
                      style: TextStyle(fontSize: 16),
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
