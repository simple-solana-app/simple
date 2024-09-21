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

//TODO placeholders
final Pubkey PHmySimpleAccount =
    Pubkey.fromBase58('5LEXeqv44X21oCBybV74ZTQCVKLtX1iL5474gSUjWwrx');
final Pubkey PHmyRaydiumLPAta =
    Pubkey.fromBase58('E6JtEhz3DDEZvv91YLanMxwQnMe3ov8Hu4892ba3wdAm');
final Pubkey PHmyUserClaimTracker =
    Pubkey.fromBase58('2gn5Pdh3jiL3S7XTphHv7mra2uGWYCavaACFqPK4AAvv');

const String mainnetBetaUri = 'https://api.mainnet-beta.solana.com';
RpcClient mainnetClient = RpcClient(mainnetBetaUri);

const String jupAllTokensUri = 'https://token.jup.ag/all';
const String jupPricesBaseUri = 'https://price.jup.ag/v4/price?ids=';

final NumberFormat defaultNumberFormat = NumberFormat("#,##0.00");
final NumberFormat solanaNumberFormat = NumberFormat("#,##0.000000000");
