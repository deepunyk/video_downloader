import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:sentry/sentry.dart';
import 'package:store_launcher/store_launcher.dart';

var getIt = GetIt.instance;

class UpdateScreen extends StatelessWidget {
  const UpdateScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.black, //change your color here
        ),
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Container(
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth:
                            min(300, MediaQuery.of(context).size.width * 0.75)),
                    child: Image.asset('assets/update.png')),
                Container(
                  height: 50.0,
                  margin: EdgeInsets.symmetric(vertical: 30),
                  child: RaisedButton(
                    onPressed: () {
                      StoreLauncher.openWithStore('adh.anydownloader.app')
                          .catchError((error, stackTrace) async {
                        getIt<SentryClient>().captureException(
                          exception: error,
                          stackTrace: stackTrace,
                        );
                      });
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0)),
                    padding: EdgeInsets.all(0.0),
                    child: Ink(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[400], Colors.blue[700]],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(3.0)),
                      child: Container(
                        constraints:
                            BoxConstraints(maxWidth: 300.0, minHeight: 50.0),
                        alignment: Alignment.center,
                        child: Text(
                          "Click Here To Update",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                Text("Updating to latest version is recommended!")
              ],
            ),
          ),
        ),
      ),
    );
  }
}
