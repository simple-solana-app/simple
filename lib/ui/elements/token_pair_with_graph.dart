import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:simple/apis/price.dart';
import 'package:simple/apis/token.dart';
import 'package:simple/domain/common.dart';
import 'package:simple/ui/elements/dropdown_token_search.dart';
import 'package:simple/ui/elements/token_info.dart';

class TokenPairWithGraph extends StatefulWidget {
  TokenModel token;
  TokenModel vsToken;
  final List<TokenModel> allFungibleTokens;

  TokenPairWithGraph({
    super.key,
    required this.token,
    required this.vsToken,
    required this.allFungibleTokens,
  });

  @override
  State<TokenPairWithGraph> createState() => _TokenPairWithGraphState();
}

class _TokenPairWithGraphState extends State<TokenPairWithGraph> {
  late Timer _timer;

  double? _penultimatePrice;
  double? _price;
  double? _priceChange;
  double? _percentChange;

  final List<FlSpot> _graphPoints = [];

  @override
  void dispose() {
    super.dispose();

    _timer.cancel();
  }

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _priceAndPercentChange();
    });
  }

  Future<void> _priceAndPercentChange() async {
    double? newPrice = await fetchPrice(widget.token.mint, widget.vsToken.mint);
    double currentTime =
        DateTime.now().millisecondsSinceEpoch.toDouble() / 1000;

    if (mounted) {
      setState(() {
        _penultimatePrice = _price;
        _price = newPrice;

        if (_penultimatePrice != null) {
          _priceChange = _price! - _penultimatePrice!;
          _percentChange = (_priceChange! / _penultimatePrice!) * 100;
        }

        if (_priceChange != null) {
          _graphPoints.add(FlSpot(currentTime, _priceChange!));
        }

        if (_graphPoints.length > 15) {
          final int removeCount = _graphPoints.length - 15;
          _graphPoints.removeRange(0, removeCount);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: _buildGraph(context),
            ),
            _buildPriceArea(context),
          ],
        ),
      ),
    );
  }

  Widget _buildGraph(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    double maxYAbsolute = _graphPoints.isNotEmpty
        ? _graphPoints
            .map((point) => point.y.abs())
            .reduce((a, b) => a > b ? a : b)
        : 0.0;
    double minY = -maxYAbsolute;
    double maxY = maxYAbsolute;
    double chartHeight = screenHeight * 0.4;

    List<FlSpot> graphPointsToDisplay =
        _graphPoints.isNotEmpty ? _graphPoints : [const FlSpot(0, 0)];

    return SizedBox(
      height: chartHeight,
      width: screenWidth * 0.9,
      child: Column(
        children: [
          Expanded(
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: graphPointsToDisplay,
                    isCurved: true,
                    color: Colors.yellow,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(
                  show: false,
                ),
                minX: graphPointsToDisplay.isNotEmpty
                    ? graphPointsToDisplay.first.x
                    : 0,
                maxX: graphPointsToDisplay.isNotEmpty
                    ? graphPointsToDisplay.last.x
                    : 0,
                minY: minY,
                maxY: maxY,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildGraphChangeInfo(),
        ],
      ),
    );
  }

  Widget _buildGraphChangeInfo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${_graphPoints.isNotEmpty ? solanaNumberFormat.format(_graphPoints.last.y) : '0.0'} ${widget.vsToken.symbol}',
          style: TextStyle(
            color: _getPriceTextColor(),
            fontSize: 16,
          ),
        ),
        Text(
          '${_percentChange != null ? defaultNumberFormat.format(_percentChange) : '0.0'}%',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }

  Color _getPriceTextColor() {
    if (_graphPoints.isEmpty || _graphPoints.last.y == 0) {
      return Colors.white;
    }
    return _graphPoints.last.y < 0 ? Colors.redAccent : Colors.greenAccent;
  }

  Widget _buildPriceArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_price != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    solanaNumberFormat.format(_price),
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                )
              else
                const CircularProgressIndicator(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 35,
                    height: 35,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: widget.vsToken.logo,
                        placeholder: (context, url) =>
                            _buildCircularImagePlaceholder(widget.vsToken),
                        errorWidget: (context, url, error) =>
                            _buildCircularImagePlaceholder(widget.vsToken),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  //TODO make these not overflow
                  ElevatedButton(
                    onPressed: () =>
                        _showSearchDialog(context, isVsToken: true),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.grey[900],
                      side: const BorderSide(color: Colors.white, width: 1.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6.0, vertical: 4.0),
                    ),
                    child: Text(
                      widget.vsToken.symbol,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(' / ',
                      style: TextStyle(color: Colors.white, fontSize: 40)),
                  const SizedBox(width: 5),
                  ElevatedButton(
                    onPressed: () =>
                        _showSearchDialog(context, isVsToken: false),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.grey[900],
                      side: const BorderSide(color: Colors.white, width: 1.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6.0, vertical: 4.0),
                    ),
                    child: Text(
                      widget.token.symbol,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 35,
                    height: 35,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: widget.token.logo,
                        placeholder: (context, url) =>
                            _buildCircularImagePlaceholder(widget.token),
                        errorWidget: (context, url, error) =>
                            _buildCircularImagePlaceholder(widget.token),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            child: IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TokenInfo(
                              token: widget.token,
                              allFungibleTokens: widget.allFungibleTokens,
                            )));
              },
              icon: const Icon(Icons.info_outline, color: Colors.white),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              onPressed: _switchTokens,
              icon: const Icon(Icons.swap_horiz, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context, {bool isVsToken = true}) {
    showDialog<TokenModel>(
      context: context,
      builder: (context) => DropDownTokenSearch(
        allFungibleTokens: widget.allFungibleTokens,
        onTokenSelected: (TokenModel token) {
          setState(() {
            _price = null;
            _penultimatePrice = null;
            _priceChange = null;
            _graphPoints.clear();

            if (isVsToken) {
              widget.vsToken = token;
            } else {
              widget.token = token;
            }

            Navigator.of(context).pop();
          });
        },
      ),
    );
  }

  Widget _buildCircularImagePlaceholder(TokenModel token) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey,
      ),
      child: Center(
        child: Text(
          token.name[0],
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _switchTokens() {
    setState(() {
      _price = null;
      _penultimatePrice = null;
      _priceChange = null;
      _graphPoints.clear();

      final temp = widget.token;
      widget.token = widget.vsToken;
      widget.vsToken = temp;
    });
  }
}
