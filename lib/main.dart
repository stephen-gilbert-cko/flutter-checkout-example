import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:checkout_example/input_formatters.dart';
import 'package:checkout_example/payment_card.dart';
import 'package:checkout_example/my_strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import 'token_model.dart';

import 'package:universal_platform/universal_platform.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: Strings.appName,
      theme: new ThemeData(
        primarySwatch: Colors.indigo,
      ),
      debugShowCheckedModeBanner: false,
      home: new MyHomePage(title: Strings.appName),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

Future<TokenModel> createToken(String cardNumber, String cardExpiryMonth,
    String cardExpiryYear, String cardCvv) async {
  final String apiUrl = "https://api.sandbox.checkout.com/tokens";
  final String publicKey = "pk_test_7d8d24fc-ffdb-4efc-b945-a19847ce319a";

  var body = {
    "type": "card",
    "number": cardNumber,
    "expiry_month": cardExpiryMonth,
    "expiry_year": cardExpiryYear,
    "cvv": cardCvv
  };
  var jsonBody = jsonEncode(body);

  final response = await http.post(apiUrl,
      headers: {
        HttpHeaders.authorizationHeader: publicKey,
        HttpHeaders.contentTypeHeader: "application/json"
      },
      body: jsonBody);

  if (response.statusCode == 201) {
    final String responseString = response.body;

    print('Success response code: ${response.statusCode}');
    print('Token: ${tokenModelFromJson(responseString).token}');

    return tokenModelFromJson(responseString);
  } else {
    print('Error response code ${response.statusCode}');
    return null;
  }
}

class _MyHomePageState extends State<MyHomePage> {
  TokenModel _token;

  var _scaffoldKey = new GlobalKey<ScaffoldState>();
  var _formKey = new GlobalKey<FormState>();
  var numberController = new TextEditingController();
  var _paymentCard = PaymentCard();
  var _autoValidate = false;

  var _card = new PaymentCard();

  @override
  void initState() {
    super.initState();
    _paymentCard.type = CardType.Others;
    numberController.addListener(_getCardTypeFrmNumber);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title: new Text(widget.title),
        ),
        body: new Container(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: new Form(
              key: _formKey,
              autovalidate: _autoValidate,
              child: new ListView(
                children: <Widget>[
                  new SizedBox(
                    height: 20.0,
                  ),
                  new TextFormField(
                    decoration: const InputDecoration(
                      border: const UnderlineInputBorder(),
                      filled: true,
                      icon: const Icon(
                        Icons.person,
                        size: 40.0,
                      ),
                      labelText: 'Cardholder Name',
                    ),
                    onSaved: (String value) {
                      _card.name = value;
                    },
                    keyboardType: TextInputType.text,
                    validator: (String value) =>
                        value.isEmpty ? Strings.fieldReq : null,
                  ),
                  new SizedBox(
                    height: 30.0,
                  ),
                  new TextFormField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      WhitelistingTextInputFormatter.digitsOnly,
                      new LengthLimitingTextInputFormatter(19),
                      new CardNumberInputFormatter()
                    ],
                    controller: numberController,
                    decoration: new InputDecoration(
                      border: const UnderlineInputBorder(),
                      filled: true,
                      icon: CardUtils.getCardIcon(_paymentCard.type),
                      hintText: '•••• •••• •••• ••••',
                      labelText: 'Number',
                    ),
                    onSaved: (String value) {
                      print('onSaved = $value');
                      print('Num controller has = ${numberController.text}');
                      _paymentCard.number = CardUtils.getCleanedNumber(value);
                    },
                    validator: CardUtils.validateCardNum,
                  ),
                  new SizedBox(
                    height: 30.0,
                  ),
                  new TextFormField(
                    inputFormatters: [
                      WhitelistingTextInputFormatter.digitsOnly,
                      new LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: new InputDecoration(
                      border: const UnderlineInputBorder(),
                      filled: true,
                      icon: new Image.asset(
                        'images/card_cvv.png',
                        width: 40.0,
                        color: Colors.grey[600],
                      ),
                      hintText: '•••',
                      labelText: 'CVV',
                    ),
                    validator: CardUtils.validateCVV,
                    keyboardType: TextInputType.number,
                    onSaved: (value) {
                      _paymentCard.cvv = int.parse(value);
                    },
                  ),
                  new SizedBox(
                    height: 30.0,
                  ),
                  new TextFormField(
                    inputFormatters: [
                      WhitelistingTextInputFormatter.digitsOnly,
                      new LengthLimitingTextInputFormatter(4),
                      new CardMonthInputFormatter()
                    ],
                    decoration: new InputDecoration(
                      border: const UnderlineInputBorder(),
                      filled: true,
                      icon: new Image.asset(
                        'images/calendar.png',
                        width: 40.0,
                        color: Colors.grey[600],
                      ),
                      hintText: 'MM/YY',
                      labelText: 'Expiry Date',
                    ),
                    validator: CardUtils.validateDate,
                    keyboardType: TextInputType.number,
                    onSaved: (value) {
                      List<int> expiryDate = CardUtils.getExpiryDate(value);
                      _paymentCard.month = expiryDate[0];
                      _paymentCard.year = expiryDate[1];
                    },
                  ),
                  new SizedBox(
                    height: 50.0,
                  ),
                  new Container(
                    alignment: Alignment.center,
                    child: _getPayButton(),
                  ),
                  SizedBox(
                    height: 32,
                  ),
                  _token == null ? Container() : Text("Token: ${_token.token}"),
                ],
              )),
        ));
  }

  @override
  void dispose() {
    // Clean up the controller when the Widget is removed from the Widget tree
    numberController.removeListener(_getCardTypeFrmNumber);
    numberController.dispose();
    super.dispose();
  }

  void _getCardTypeFrmNumber() {
    String input = CardUtils.getCleanedNumber(numberController.text);
    CardType cardType = CardUtils.getCardTypeFrmNumber(input);
    setState(() {
      this._paymentCard.type = cardType;
    });
  }

  void _validateInputs() async {
    final FormState form = _formKey.currentState;
    if (!form.validate()) {
      setState(() {
        _autoValidate = true; // Start validating on every change.
      });
      _showInSnackBar('Please fix the errors in red before submitting.');
    } else {
      form.save();
      _showInSnackBar('Token created successfully!');

      // Exchange card details for Checkout.com token
      final String cardNumber = _paymentCard.number.toString();
      final String cardExpiryMonth = _paymentCard.month.toString();
      final String cardExpiryYear = _paymentCard.year.toString();
      final String cardCvv = _paymentCard.cvv.toString();

      final TokenModel token = await createToken(
          cardNumber, cardExpiryMonth, cardExpiryYear, cardCvv);

      setState(() {
        _token = token;
      });

      // Reset payment form
      _formKey.currentState.reset();
      numberController.text = "";
    }
  }

  Widget _getPayButton() {
    if (UniversalPlatform.isIOS) {
      return new CupertinoButton(
        onPressed: _validateInputs,
        color: CupertinoColors.activeBlue,
        child: const Text(
          Strings.pay,
          style: const TextStyle(fontSize: 17.0),
        ),
      );
    } else {
      return new RaisedButton(
        onPressed: _validateInputs,
        color: Colors.blueAccent,
        splashColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(const Radius.circular(100.0)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 80.0),
        textColor: Colors.white,
        child: new Text(
          Strings.pay.toUpperCase(),
          style: const TextStyle(fontSize: 17.0),
        ),
      );
    }
  }

  void _showInSnackBar(String value) {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text(value),
      duration: new Duration(seconds: 3),
    ));
  }
}
