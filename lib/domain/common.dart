import 'package:intl/intl.dart';
import 'package:solana/solana.dart';
import 'package:solana_web3/solana_web3.dart' as web3;

const String simpleWebsiteAddress = "simple-solana-app.github.io";
const String simpleLogoUri = "assets/512x512_logo.png";

const String mainnetBetaUri = 'https://api.mainnet-beta.solana.com';
RpcClient mainnetClient = RpcClient(mainnetBetaUri);

const String tokenProgramId = 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA';
const String token2022ProgramId = 'TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb';
const String stakeProgramId = 'Stake11111111111111111111111111111111111111';

const String jupAllTokensUri = 'https://token.jup.ag/all';
const String jupPricesBaseUri = 'https://price.jup.ag/v4/price?ids=';

final NumberFormat defaultNumberFormat = NumberFormat("#,##0.00");
final NumberFormat solanaNumberFormat = NumberFormat("#,##0.000000000");

final connection = web3.Connection(web3.Cluster.devnet);
final programId =
    web3.Pubkey.fromBase58('24x6XDgxxZgSzuAefWmx7WAppzBfgCSHtxAkDtpALbq1');
