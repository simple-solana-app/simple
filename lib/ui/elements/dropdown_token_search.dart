import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:simple/apis/token.dart';
import 'package:simple/domain/vs_tokens.dart';
import 'package:simple/ui/elements/token_info.dart';
import 'package:simple/ui/elements/token_pair_with_graph.dart';

class DropDownTokenSearch extends StatefulWidget {
  final List<TokenModel> allFungibleTokens;
  Function(TokenModel)? onTokenSelected;

  DropDownTokenSearch(
      {super.key, required this.allFungibleTokens, this.onTokenSelected});

  @override
  State<DropDownTokenSearch> createState() => _DropDownTokenSearchState();
}

class _DropDownTokenSearchState extends State<DropDownTokenSearch> {
  late TextEditingController _searchController;
  late List<TokenModel> _filteredTokens;

  bool _toTokenInfo = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController();
    _filteredTokens = widget.allFungibleTokens;

    _searchController.addListener(_filterTokens);
  }

  void _filterTokens() {
    final query = _searchController.text.toLowerCase();
    if (mounted) {
      setState(() {
        if (query.isEmpty) {
          _filteredTokens = widget.allFungibleTokens;
        } else {
          _filteredTokens = widget.allFungibleTokens.where((token) {
            return token.mint.toLowerCase() == query ||
                token.name.toLowerCase().contains(query) ||
                token.symbol.toLowerCase().contains(query);
          }).toList();
        }
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.black,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _filteredTokens.length,
              itemBuilder: (context, index) =>
                  _buildTokenListItem(_filteredTokens[index]),
            ),
          ),
          if (widget.onTokenSelected == null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: screenWidth * 0.2,
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        vsTokens.USDC.token.unicodeSymbol!,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _toTokenInfo = !_toTokenInfo;
                            });
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                height: 13,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              AnimatedAlign(
                                duration: const Duration(milliseconds: 160),
                                alignment: _toTokenInfo
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: AssetImage('assets/logo.png'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Icon(Icons.info_outline,
                          color: Colors.grey, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              cursorColor: Colors.black,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.black,
                  size: 27,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenListItem(TokenModel token) {
    return ListTile(
      leading: ClipOval(
        child: token.logo.endsWith('.svg')
            ? SvgPicture.network(
                token.logo,
                placeholderBuilder: (context) => Container(
                  width: 35.0,
                  height: 35.0,
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
                ),
                height: 35.0,
                width: 35.0,
              )
            : CachedNetworkImage(
                imageUrl: token.logo,
                placeholder: (context, url) => Container(
                  width: 35.0,
                  height: 35.0,
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
                ),
                errorWidget: (context, url, error) => Container(
                  width: 35.0,
                  height: 35.0,
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
                ),
                height: 35.0,
                width: 35.0,
                fit: BoxFit.cover,
              ),
      ),
      title: Text(token.name, style: const TextStyle(color: Colors.white)),
      subtitle: Text('${token.symbol} - ${token.mint}',
          style: const TextStyle(color: Colors.grey)),
      onTap: () {
        if (_toTokenInfo) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TokenInfo(
                allFungibleTokens: widget.allFungibleTokens,
                token: token,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TokenPairWithGraph(
                token: token,
                vsToken: vsTokens.USDC.token,
                allFungibleTokens: widget.allFungibleTokens,
              ),
            ),
          );
        }
        widget.onTokenSelected?.call(token);
      },
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: token.mint));
      },
    );
  }
}
