// To parse this JSON data, do
//
//     final tokenModel = tokenModelFromJson(jsonString);

import 'dart:convert';

TokenModel tokenModelFromJson(String str) => TokenModel.fromJson(json.decode(str));

String tokenModelToJson(TokenModel data) => json.encode(data.toJson());

class TokenModel {
  TokenModel({
    this.type,
    this.token,
    this.expiresOn,
    this.expiryMonth,
    this.expiryYear,
    this.scheme,
    this.last4,
    this.bin,
    this.cardType,
    this.cardCategory,
    this.issuer,
    this.issuerCountry,
    this.productId,
    this.productType,
  });

  String type;
  String token;
  DateTime expiresOn;
  int expiryMonth;
  int expiryYear;
  String scheme;
  String last4;
  String bin;
  String cardType;
  String cardCategory;
  String issuer;
  String issuerCountry;
  String productId;
  String productType;

  factory TokenModel.fromJson(Map<String, dynamic> json) => TokenModel(
    type: json["type"],
    token: json["token"],
    expiresOn: DateTime.parse(json["expires_on"]),
    expiryMonth: json["expiry_month"],
    expiryYear: json["expiry_year"],
    scheme: json["scheme"],
    last4: json["last4"],
    bin: json["bin"],
    cardType: json["card_type"],
    cardCategory: json["card_category"],
    issuer: json["issuer"],
    issuerCountry: json["issuer_country"],
    productId: json["product_id"],
    productType: json["product_type"],
  );

  Map<String, dynamic> toJson() => {
    "type": type,
    "token": token,
    "expires_on": expiresOn.toIso8601String(),
    "expiry_month": expiryMonth,
    "expiry_year": expiryYear,
    "scheme": scheme,
    "last4": last4,
    "bin": bin,
    "card_type": cardType,
    "card_category": cardCategory,
    "issuer": issuer,
    "issuer_country": issuerCountry,
    "product_id": productId,
    "product_type": productType,
  };
}
