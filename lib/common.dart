import 'package:intl/intl.dart';
import 'package:solana/solana.dart';
import 'package:solana_wallet_provider/solana_wallet_provider.dart';

final Cluster cluster = Cluster.mainnet;
final Connection connection = Connection(cluster);

const String simpleWebsiteAddress = "simple-solana-app.github.io";
const String simpleLogoUri = "assets/512x512_logo.png";
final AppIdentity simpleIdentity = AppIdentity(
    uri: Uri.https(simpleWebsiteAddress),
    icon: Uri.parse(simpleLogoUri),
    name: 'simple');

const String simpleTokenMint = "4QUwG4eADsjfaZ5nTEd6eGF5he8vR8FCFLPgwmpiJRD5";

const String mainnetBetaUri = 'https://api.mainnet-beta.solana.com';
RpcClient mainnetClient = RpcClient(mainnetBetaUri);

const String jupAllTokensUri = 'https://token.jup.ag/all';
const String jupPricesBaseUri = 'https://price.jup.ag/v4/price?ids=';

final NumberFormat defaultNumberFormat = NumberFormat("#,##0.00");
final NumberFormat solanaNumberFormat = NumberFormat("#,##0.000000000");
