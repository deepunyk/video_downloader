import 'package:get_it/get_it.dart';
import 'package:sentry/sentry.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

var getIt = GetIt.instance;

class FeatureRecommend extends StatelessWidget {
  FeatureRecommend({Key key}) : super(key: key);
  static const route = 'featurerecommend_route';
  final TextEditingController myController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text("Recommend A Feature"),
      ),
      body: Form(
          key: _formKey,
          child: Container(
            child: Center(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  "Do you want us to add more apps to AnyDownloader? Leave your suggestions below!",
                  textAlign: TextAlign.center,
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  child: TextFormField(
                    controller: myController,
                    validator: (value) {
                      return value.length > 0 ? null : "Field cannot be empty!";
                    },
                    decoration: const InputDecoration(
                      hintText: 'Type app or website name here',
                      labelText: "",
                    ),
                    onFieldSubmitted: (value) {
                      _handleSubmit(value);
                    },
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                FlatButton(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  onPressed: () {
                    _handleSubmit(myController.text.trim());
                  },
                  color: Colors.orange,
                  disabledColor: Colors.orange.withAlpha(150),
                  child: Text(
                    "Submit",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            )),
          )),
    );
  }

  _handleSubmit(String value) {
    if (_formKey.currentState.validate()) {
      final Uri _emailLaunchUri = Uri(
          scheme: 'mailto',
          path: 'App03creator@gmail.com',
          queryParameters: {'subject': 'FeatureRecommendation', 'body': value});

      launch(_emailLaunchUri.toString());
      try {
        getIt<SentryClient>().captureException(
            exception: FeatureRecommendation(""), stackTrace: value);
      } catch (err) {
        print(err);
      }
    }
  }
}

class FeatureRecommendation implements Exception {
  String cause;
  FeatureRecommendation(this.cause);
}
