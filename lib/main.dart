import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple/apis/token.dart';
import 'package:simple/domain/common.dart';
import 'package:simple/ui/elements/dropdown_token_search.dart';
import 'package:simple/ui/pages/portfolio_page.dart';
import 'package:simple/ui/pages/tokens_page.dart';
import 'package:solana_wallet_adapter/solana_wallet_adapter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const AllFungibleTokensWrapper());
}

class AllFungibleTokensWrapper extends StatefulWidget {
  const AllFungibleTokensWrapper({super.key});

  @override
  State<AllFungibleTokensWrapper> createState() =>
      _AllFungibleTokensWrapperState();
}

class _AllFungibleTokensWrapperState extends State<AllFungibleTokensWrapper> {
  List<TokenModel>? allFungibleTokens;

  @override
  void initState() {
    super.initState();

    _getAllFungibleTokens();
  }

  Future<void> _getAllFungibleTokens() async {
    var tokens = await fetchAllFungibleTokens();
    setState(() {
      allFungibleTokens = tokens;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (allFungibleTokens == null) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return MainApp(allFungibleTokens: allFungibleTokens!);
    }
  }
}

class MainApp extends StatefulWidget {
  final List<TokenModel> allFungibleTokens;
  const MainApp({super.key, required this.allFungibleTokens});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  Future<void>? _walletFuture;
  final SolanaWalletAdapter adapter = SolanaWalletAdapter(
    AppIdentity(
        uri: Uri.https(simpleWebsiteAddress),
        icon: Uri.parse(simpleLogoUri),
        name: 'simple'),
    cluster: Cluster.mainnet,
    hostAuthority: null,
  );

  String? walletLabel;
  String? walletAddress;

  int _navIndex = 0;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _initializeWallet();
  }

  void _initializeWallet() async {
    await SolanaWalletAdapter.initialize();

    setState(() {
      _walletFuture = Future.value();
    });

    if (adapter.isAuthorized) {
      _getWalletInfo();
    }
  }

  void _getWalletInfo() {
    setState(() {
      walletLabel = adapter.connectedAccount!.label!;
      walletAddress = adapter.connectedAccount!.toBase58();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          scaffoldBackgroundColor: Colors
              .transparent // I don't wanna spend too much time on this, but this makes the background not that ugly blue in recent apps
          ),
      home: FutureBuilder(
        future: _walletFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (adapter.isAuthorized) {
              return Scaffold(
                backgroundColor: Colors.black,
                body: _buildMainScreen(context),
              );
            } else {
              return Scaffold(
                backgroundColor: Colors.black,
                body: _buildConnectScreen(),
              );
            }
          } else {
            // will always come back from wallet app with connection state being done
            return Container();
          }
        },
      ),
    );
  }

  Widget _buildMainScreen(BuildContext context) {
    if (walletLabel != null && walletAddress != null) {
      return _buildMainMenu(context);
    } else {
      //those won't be null
      return Container();
    }
  }

  Widget _buildMainMenu(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Column(
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
                          allFungibleTokens: widget.allFungibleTokens,
                        ),
                        PortfolioPage(
                          allFungibleTokens: widget.allFungibleTokens,
                          walletLabel: walletLabel!,
                          walletAddress: walletAddress!,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.13),
                ],
              ),
              Positioned(
                  bottom: screenHeight * 0.08,
                  left: screenWidth * 0.255,
                  child: _buildInfoIcon(context)),
              Positioned(
                  bottom: screenHeight * 0.018,
                  left: screenWidth * 0.237,
                  child: _buildSearchButton(context)),
              Positioned(
                  bottom: screenHeight * 0.03,
                  left: screenWidth * 0.30,
                  child: _buildJupButton(context)),
              Positioned(
                  bottom: screenHeight * 0.068,
                  left: screenWidth * 0.423,
                  child: _buildTokensNavButton()),
              Positioned(
                  bottom: screenHeight * 0.0253,
                  left: screenWidth * 0.447,
                  child: _buildPortfolioNavButton()),
              Positioned(
                top: screenHeight * 0.05,
                right: screenWidth * 0.02,
                child: _buildDisconnectButton(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoIcon(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showInfoDialog(context);
      },
      child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
    );
  }

  void _showInfoDialog(BuildContext context) {
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

  Widget _buildSearchButton(BuildContext context) {
    return GestureDetector(
      child: const Icon(Icons.search, color: Colors.white, size: 37),
      onTap: () {
        _showTokenSearchDialog(context);
      },
    );
  }

  void _showTokenSearchDialog(BuildContext context) {
    showDialog<TokenModel>(
        context: context,
        builder: (context) =>
            DropDownTokenSearch(allFungibleTokens: widget.allFungibleTokens));
  }

  Widget _buildJupButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _launchJupAgUrl(context);
      },
      child: ClipOval(
        child: Image.asset(
          'assets/jup_icon.png',
          height: 60.0,
          width: 60.0,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  void _launchJupAgUrl(BuildContext context) async {
    const url = 'https://jup.ag/';

    AndroidIntent intent = const AndroidIntent(
      action: 'action_view',
      data: url,
      package: 'com.android.chrome',
    );

    await intent.launch();
  }

  Widget _buildTokensNavButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          _navIndex = 0;
        });
      },
      child: const Text("Tokens",
          style: TextStyle(fontSize: 18, color: Colors.white)),
    );
  }

  Widget _buildPortfolioNavButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          _navIndex = 1;
        });
      },
      child: const Text("Portfolio",
          style: TextStyle(fontSize: 18, color: Colors.white)),
    );
  }

  Widget _buildDisconnectButton() {
    return TextButton(
      onPressed: _disconnect,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(Colors.transparent),
        foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
        side: WidgetStateProperty.all<BorderSide>(
          const BorderSide(color: Colors.white, width: 1.0),
        ),
      ),
      child: const Text(
        'Disconnect',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Future<void> _disconnect() async {
    if (adapter.isAuthorized) {
      await adapter.deauthorize();
      // needed, tells app to rerender UI to the disconnected state
      setState(() {});
    }
  }

  Widget _buildConnectScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'simply',
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontStyle: FontStyle.italic),
          ),
          ElevatedButton(
            onPressed: () {
              _connect();
            },
            child: const Text('Connect',
                style: TextStyle(color: Colors.black, fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Future<void> _connect() async {
    if (!adapter.isAuthorized) {
      await adapter.authorize();
    }
    _getWalletInfo();
  }
}
