import 'dart:convert';

import 'package:simple/domain/common.dart';
import 'package:http/http.dart' as http;

class PriceModel {
  final String tokenAddress;
  final String tokenSymbol;
  final String vsTokenAddress;
  final String vsTokenSymbol;
  final double price;

  PriceModel({
    required this.tokenAddress,
    required this.tokenSymbol,
    required this.vsTokenAddress,
    required this.vsTokenSymbol,
    required this.price,
  });

  factory PriceModel.fromJson(Map<String, dynamic> json) {
    return PriceModel(
      tokenAddress: json['id'],
      tokenSymbol: json['mintSymbol'],
      vsTokenAddress: json['vsToken'],
      vsTokenSymbol: json['vsTokenSymbol'],
      price: (json['price'] as num).toDouble(),
    );
  }
}

Future<Map<String, double>> fetchPrices(
    String concatenatedAddresses, String vsTokenAddress) async {
  Map<String, double> tokenPrices = {};

  var url = Uri.parse(
      '$jupPricesBaseUri$concatenatedAddresses&vsToken=$vsTokenAddress');
  try {
    final response = await http.get(url);
    final data = json.decode(response.body)['data'];
    Map<String, dynamic> pricesMap = Map<String, dynamic>.from(data);
    pricesMap.forEach((key, value) {
      tokenPrices[value['id']] = (value['price'] as num).toDouble();
    });
    return tokenPrices;
  } catch (e) {
    throw Exception('fetching Prices failed $e');
  }
}

Future<double> fetchPrice(String tokenAddress, String vsTokenAddress) async {
  var url = Uri.parse('$jupPricesBaseUri$tokenAddress&vsToken=$vsTokenAddress');

  try {
    final response = await http.get(url);
    final data = json.decode(response.body)['data'][tokenAddress];
    final tokenPrice = PriceModel.fromJson(data);
    return tokenPrice.price;
  } catch (e) {
    throw Exception('fetching Price failed $e');
  }
}
