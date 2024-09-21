import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:simple/apis/price.dart';
import 'package:simple/apis/token.dart';
import 'package:simple/common.dart';
import 'package:simple/domain/vs_tokens.dart';
import 'package:simple/ui/elements/token_pair_with_graph.dart';

class TokensPage extends StatefulWidget {
  final List<TokenModel> allFungibleTokens;

  const TokensPage({
    super.key,
    required this.allFungibleTokens,
  });

  @override
  State<TokensPage> createState() => _TokensPageState();
}

class _TokensPageState extends State<TokensPage> {
  late Timer _timer;

  TokenModel vsToken = vsTokens.USDC.token;

  Map<String, double>? _tokenMintsWithPrices;

  @override
  void dispose() {
    super.dispose();

    _timer.cancel();
  }

  @override
  void initState() {
    super.initState();

    _getPrices(vsToken);

    _timer = Timer.periodic(
        const Duration(seconds: 1), (timer) => _getPrices(vsToken));
  }

  Future<void> _getPrices(TokenModel vsToken) async {
    final String ninetyNineTokenAddressConcatenated =
        widget.allFungibleTokens.map((token) => token.mint).take(99).join(',');

    await fetchPrices(
      ninetyNineTokenAddressConcatenated,
      vsToken.mint,
    ).then((tokenMintsWithPrices) {
      setState(() {
        _tokenMintsWithPrices = tokenMintsWithPrices;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_tokenMintsWithPrices == null) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: 99,
                  itemBuilder: (context, index) {
                    TokenModel token = widget.allFungibleTokens[index];
                    double? price = _tokenMintsWithPrices![token.mint];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TokenPairWithGraph(
                              token: token,
                              vsToken: vsToken,
                              allFungibleTokens: widget.allFungibleTokens,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          height: 50,
                          child: Row(
                            children: [
                              ClipOval(
                                child: token.logo.endsWith('.svg')
                                    ? SvgPicture.network(
                                        token.logo,
                                        placeholderBuilder: (context) =>
                                            Container(
                                          width: 35.0,
                                          height: 35.0,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.grey,
                                          ),
                                          child: Center(
                                            child: Text(
                                              token.name[0],
                                              style: const TextStyle(
                                                  color: Colors.white),
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
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.grey,
                                          ),
                                          child: Center(
                                            child: Text(
                                              token.name[0],
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                          width: 35.0,
                                          height: 35.0,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.grey,
                                          ),
                                          child: Center(
                                            child: Text(
                                              token.name[0],
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        height: 35.0,
                                        width: 35.0,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    token.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  //TODO make not overflow
                                  Text(
                                    price != null
                                        ? '${vsToken.unicodeSymbol}${solanaNumberFormat.format(price)}/${token.symbol}'
                                        : 'null',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14.0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: vsTokens.values.map((t) {
            return TextButton(
              onPressed: () {
                _getPrices(t.token).then((_) {
                  setState(() {
                    vsToken = t.token;
                  });
                });
              },
              child: Text(
                t.token.unicodeSymbol!,
                style: TextStyle(
                  fontSize: 18,
                  color: vsToken == t.token ? Colors.white : Colors.grey,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
