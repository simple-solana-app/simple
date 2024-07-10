import 'package:intl/intl.dart';
import 'package:solana/solana.dart';

const String simpleWebsiteAddress = "simple-solana-app.github.io";
const String simpleLogoUri = "../logo.png";

const String mainnetBetaUri = 'https://api.mainnet-beta.solana.com';
RpcClient mainnetClient = RpcClient(mainnetBetaUri);

const String tokenProgramId = 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA';
const String token2022ProgramId = 'TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb';
const String stakeProgramId = 'Stake11111111111111111111111111111111111111';

const String jupAllTokensUri = 'https://token.jup.ag/all';
const String jupPricesBaseUri = 'https://price.jup.ag/v4/price?ids=';

final NumberFormat defaultNumberFormat = NumberFormat("#,##0.00");
final NumberFormat solanaNumberFormat = NumberFormat("#,##0.000000000");
