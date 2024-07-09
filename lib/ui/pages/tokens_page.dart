import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:simple/apis/price.dart';
import 'package:simple/apis/token.dart';
import 'package:simple/domain/common.dart';
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

  late String _ninetyNineTokenAddressConcatenated;
  TokenModel vsToken = vsTokens.USDC.token;
  Map<String, double> _tokensWithPrices = {};

  @override
  void dispose() {
    super.dispose();

    _timer.cancel();
  }

  @override
  void initState() {
    super.initState();

    _ninetyNineTokenAddressConcatenated =
        widget.allFungibleTokens.map((token) => token.mint).take(99).join(',');

    _getPrices(vsToken);

    _timer = Timer.periodic(
        const Duration(seconds: 1), (timer) => _getPrices(vsToken));
  }

  Future<void> _getPrices(TokenModel vsToken) async {
    await fetchPrices(
      _ninetyNineTokenAddressConcatenated,
      vsToken.mint,
    ).then((prices) {
      if (mounted) {
        setState(() {
          _tokensWithPrices = prices;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _buildTokensWithPricesList(),
        ),
        Center(child: _buildVsTokenButtons()),
      ],
    );
  }

  Widget _buildTokensWithPricesList() {
    bool columnRendered = false;

    // filter out tokens with null prices or they'll never load into TokenPair
    List<TokenModel> tokensWithPrices = widget.allFungibleTokens.where((token) {
      return _tokensWithPrices[token.mint] != null;
    }).toList();

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: tokensWithPrices.length + 1,
            itemBuilder: (context, index) {
              if (index < tokensWithPrices.length) {
                TokenModel token = tokensWithPrices[index];
                double tokenPrice = _tokensWithPrices[token.mint]!;

                return _buildTokenWithPriceListItem(vsToken, token, tokenPrice);
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!columnRendered) {
                    setState(() {
                      columnRendered = true;
                    });
                  }
                });

                if (columnRendered) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "I can't get the price of every token at once, you can search for any token though.",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                } else {
                  // column renders p quick
                  return Container();
                }
              }
            },
          ),
        ),
      ],
    );
  }

  // tokenPrice won't ever be null bc all tokenPrices have been filtered out, still getting passed a nullable var tho
  Widget _buildTokenWithPriceListItem(
      TokenModel vsToken, TokenModel token, double tokenPrice) {
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
                child: SizedBox(
                  width: 35,
                  height: 35,
                  child: token.logo.endsWith('.svg')
                      ? SvgPicture.network(
                          token.logo,
                          placeholderBuilder: (context) => Container(
                            color: Colors.grey,
                            child: Center(
                              child: Text(
                                token.name[0],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: token.logo,
                          placeholder: (context, url) => Container(
                            color: Colors.grey,
                            child: Center(
                              child: Text(
                                token.name[0],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey,
                            child: Center(
                              child: Text(
                                token.name[0],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          fit: BoxFit.contain,
                        ),
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
                    Text(
                      '${vsToken.unicodeSymbol}${solanaNumberFormat.format(tokenPrice)}/${token.symbol}', //overflows if token.symbol is really long idc tho
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
  }

  Widget _buildVsTokenButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: vsTokens.values.map((token) {
        return TextButton(
          onPressed: () {
            if (mounted) {
              _getPrices(token.token).then((_) {
                setState(() {
                  vsToken = token.token;
                });
              });
            }
          },
          child: Text(
            token.token.unicodeSymbol!,
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
