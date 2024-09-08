import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:simple/apis/price.dart';
import 'package:simple/apis/rpc.dart';
import 'package:simple/apis/token.dart';
import 'package:simple/common.dart';
import 'package:simple/domain/vs_tokens.dart';
import 'package:simple/ui/elements/dropdown_token_search.dart';

class TokenInfo extends StatefulWidget {
  TokenModel token;

  final List<TokenModel> allFungibleTokens;

  TokenInfo({
    super.key,
    required this.token,
    required this.allFungibleTokens,
  });

  @override
  State<TokenInfo> createState() => _TokenInfoState();
}

class _TokenInfoState extends State<TokenInfo> {
  late Timer _timer;

  double? _tokenSupply;

  TokenModel _vsToken = vsTokens.USDC.token;

  double? _tokenPrice;

  double? _tokenMktCap;

  @override
  void dispose() {
    super.dispose();

    _timer.cancel();
  }

  @override
  void initState() {
    super.initState();

    _initializeData();
  }

  void _initializeData() async {
    await _getTokenSupply();

    if (_tokenSupply != null) {
      await _getTokenPriceAndMktCap(widget.token);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        await _getTokenPriceAndMktCap(widget.token);
      });
    }
  }

  Future<void> _getTokenSupply() async {
    double tokenSupply = widget.token.mint != vsTokens.WSOL.token.mint
        ? await widget.token.fetchSupply()
        : await fetchSolSupply();

    setState(() {
      _tokenSupply = tokenSupply;
    });
  }

  Future<void> _getTokenPriceAndMktCap(TokenModel token) async {
    await fetchPrice(token.mint, _vsToken.mint).then((price) {
      if (mounted) {
        setState(() {
          _tokenPrice = price;

          _tokenMktCap = price * _tokenSupply!;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        _buildInfo(context),
        const SizedBox(height: 8.0),
        _buildLogo(),
        const SizedBox(height: 8.0),
        _buildVsTokenButtons(),
        const SizedBox(height: 8.0),
        _buildTokenButtonAndMint(),
      ]),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tokenPrice != null
            ? Text(
                'Price: ${_vsToken.unicodeSymbol}${solanaNumberFormat.format(_tokenPrice)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                ),
              )
            : const CircularProgressIndicator(),
        _tokenSupply != null
            ? Text(
                'Supply: ${solanaNumberFormat.format(_tokenSupply)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                ),
              )
            : const CircularProgressIndicator(),
        _tokenMktCap != null
            ? Text(
                'Mkt cap: ${_vsToken.unicodeSymbol}${defaultNumberFormat.format(_tokenMktCap)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                ),
              )
            : const CircularProgressIndicator(),
      ],
    );
  }

  Widget _buildLogo() {
    return ClipOval(
      child: widget.token.logo.endsWith('.svg')
          ? SvgPicture.network(
              widget.token.logo,
              placeholderBuilder: (context) => Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                ),
                child: Center(
                  child: Text(
                    widget.token.name[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 60,
                    ),
                  ),
                ),
              ),
              height: 150,
              width: 150,
            )
          : CachedNetworkImage(
              imageUrl: widget.token.logo,
              placeholder: (context, url) => Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                ),
                child: Center(
                  child: Text(
                    widget.token.name[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 60, // Assuming the original font size is 14
                    ),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                ),
                child: Center(
                  child: Text(
                    widget.token.name[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 60, // Assuming the original font size is 14
                    ),
                  ),
                ),
              ),
              height: 150,
              width: 150,
              fit: BoxFit.cover,
            ),
    );
  }

  Widget _buildVsTokenButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: vsTokens.values.map((vsToken) {
        return TextButton(
          onPressed: () {
            setState(() {
              _tokenPrice = null;
              _tokenMktCap = null;
              _vsToken = vsToken.token;
            });

            _initializeData();
          },
          child: Text(
            vsToken.token.unicodeSymbol!,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTokenButtonAndMint() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: widget.token.mint));
        },
        child: Text(
          widget.token.mint,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const SizedBox(
        height: 8,
      ),
      Text(
        widget.token.name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      ElevatedButton(
        onPressed: () => _showTokenSearchDialog(context),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.grey[900],
          side: const BorderSide(color: Colors.white, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
        ),
        child: Text(
          widget.token.symbol,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    ]);
  }

  void _showTokenSearchDialog(BuildContext context) {
    showDialog<TokenModel>(
      context: context,
      builder: (context) => DropDownTokenSearch(
        allFungibleTokens: widget.allFungibleTokens,
        onTokenSelected: (TokenModel token) {
          setState(() {
            widget.token = token;

            _tokenSupply = null;
            _tokenPrice = null;
            _tokenMktCap = null;
          });

          _initializeData();

          Navigator.of(context).pop();
        },
      ),
    );
  }
}
