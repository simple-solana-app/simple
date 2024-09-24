import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:simple/apis/token.dart';
import 'package:simple/domain/vs_tokens.dart';
import 'package:simple/ui/elements/token_pair_with_graph.dart';

class DropDownTokenSearch extends StatefulWidget {
  final List<TokenModel> allFungibleTokens;
  final Function(TokenModel)? onTokenSelected;

  const DropDownTokenSearch(
      {super.key, required this.allFungibleTokens, this.onTokenSelected});

  @override
  State<DropDownTokenSearch> createState() => _DropDownTokenSearchState();
}

class _DropDownTokenSearchState extends State<DropDownTokenSearch> {
  final TextEditingController _searchController = TextEditingController();
  late List<TokenModel> _filteredTokens;

  @override
  void dispose() {
    super.dispose();

    _searchController.dispose();
  }

  @override
  void initState() {
    super.initState();

    _filteredTokens = widget.allFungibleTokens;

    _searchController.addListener(_filterTokens);
  }

  void _filterTokens() {
    final query = _searchController.text.toLowerCase();
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _filteredTokens.length,
              itemBuilder: (context, index) => ListTile(
                leading: ClipOval(
                  child: _filteredTokens[index].logo.endsWith('.svg')
                      ? SvgPicture.network(
                          _filteredTokens[index].logo,
                          placeholderBuilder: (context) => Container(
                            width: 35.0,
                            height: 35.0,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey,
                            ),
                            child: Center(
                              child: Text(
                                _filteredTokens[index].name[0],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          height: 35.0,
                          width: 35.0,
                        )
                      : CachedNetworkImage(
                          imageUrl: _filteredTokens[index].logo,
                          placeholder: (context, url) => Container(
                            width: 35.0,
                            height: 35.0,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey,
                            ),
                            child: Center(
                              child: Text(
                                _filteredTokens[index].name[0],
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
                                _filteredTokens[index].name[0],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          height: 35.0,
                          width: 35.0,
                          fit: BoxFit.cover,
                        ),
                ),
                title: Text(_filteredTokens[index].name,
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                    '${_filteredTokens[index].symbol} - ${_filteredTokens[index].mint}',
                    style: const TextStyle(color: Colors.grey)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TokenPairWithGraph(
                        token: _filteredTokens[index],
                        vsToken: vsTokens.USDC.token,
                        allFungibleTokens: widget.allFungibleTokens,
                      ),
                    ),
                  );

                  widget.onTokenSelected?.call(_filteredTokens[index]);
                },
                onLongPress: () {
                  Clipboard.setData(
                      ClipboardData(text: _filteredTokens[index].mint));
                },
              ),
            ),
          ),
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
}
