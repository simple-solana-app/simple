import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple/apis/token.dart';
import 'package:simple/common.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:simple/ui/connect.dart';
import 'package:simple/ui/nav.dart';
import 'package:solana_wallet_provider/solana_wallet_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const AllFungibleTokensWrapper());
}

mixin AppLocale {
  static const String title = 'title';
  static const String thisIs = 'thisIs';

  // ignore: constant_identifier_names
  static const Map<String, dynamic> EN = {
    title: 'Localization',
    thisIs: 'This is %a package, version %a.',
  };
}

class AllFungibleTokensWrapper extends StatefulWidget {
  const AllFungibleTokensWrapper({super.key});

  @override
  State<AllFungibleTokensWrapper> createState() =>
      _AllFungibleTokensWrapperState();
}

class _AllFungibleTokensWrapperState extends State<AllFungibleTokensWrapper> {
  List<TokenModel>? allFungibleTokens;
  late String tx;

  @override
  void initState() {
    super.initState();

    _getAllFungibleTokens();
  }

  void _getAllFungibleTokens() async {
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
      return SimpleApp(allFungibleTokens: allFungibleTokens!);
    }
  }
}

class SimpleApp extends StatefulWidget {
  const SimpleApp({super.key, required this.allFungibleTokens});

  final List<TokenModel> allFungibleTokens;

  @override
  State<SimpleApp> createState() => _SimpleAppState();
}

class _SimpleAppState extends State<SimpleApp> {
  final FlutterLocalization _localization = FlutterLocalization.instance;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _localization.init(mapLocales: [
      const MapLocale(
        'en',
        AppLocale.EN,
        countryCode: 'US',
        fontFamily: 'Font EN',
      ),
    ], initLanguageCode: 'en');
  }

  @override
  Widget build(BuildContext context) {
    return SolanaWalletProvider.create(
      httpCluster: cluster,
      identity: simpleIdentity,
      child: MaterialApp(
        supportedLocales: _localization.supportedLocales,
        localizationsDelegates: _localization.localizationsDelegates,
        theme: ThemeData(
            scaffoldBackgroundColor: Colors
                .transparent // I don't wanna spend too much time on this, but this makes the background not that ugly blue in recent apps
            ),
        home: FutureBuilder(
          future: SolanaWalletProvider.initialize(),
          builder: ((context, snapshot) {
            final SolanaWalletProvider provider =
                SolanaWalletProvider.of(context);

            if (provider.adapter.isAuthorized) {
              return NavScreen(
                allFungibleTokens: widget.allFungibleTokens,
                provider: provider,
              );
            } else {
              return ConnectScreen(
                provider: provider,
              );
            }
          }),
        ),
      ),
    );
  }
}
