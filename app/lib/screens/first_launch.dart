
import 'dart:async';

import 'package:app/api/auth.dart';
import 'package:app/screens/auth/login.dart';
import 'package:app/screens/index.dart';
import 'package:app/screens/provision.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

import 'auth/invite_code.dart';

class FirstLaunchPage extends StatefulWidget {
  const FirstLaunchPage({super.key});

  @override
  State<StatefulWidget> createState() => _FirstLaunchPageState();



}

class _FirstLaunchPageState extends State<FirstLaunchPage> {

  Future<bool>? _checkAuthFuture;

  @override
  Widget build(BuildContext context) {
    final edgePadding = MediaQuery.of(context).size.width / 8;

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: edgePadding
        ),
        child:  Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(),
              Text(
                'CabiNET',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: edgePadding),
                child: FutureBuilder<bool>(
                    future: _checkAuthFuture,
                    builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                      if(snapshot.hasData || snapshot.hasError || snapshot.connectionState == ConnectionState.done) {
                        return Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                    onPressed: () {
                                      _startOOBE();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                    ),
                                    child: Text('Set up a new device')
                                ),
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                    onPressed: (){
                                      _login();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(width: 2.0, color: Colors.white),
                                    ),
                                    child: Text('Sign in')
                                ),
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                    onPressed: () {
                                      _useInvite();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(width: 2.0, color: Colors.white),
                                    ),
                                    child: Text('Activate invite code')
                                ),
                              ),
                            ],
                          );
                      } else {
                        return const CircularProgressIndicator(
                          color: Colors.white,
                        );
                      }
                    },
                  )
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _handleAuthSuccess(bool status) async {
    if(status) {
      Navigator.of(context).pushReplacement(IndexPage.route(context));
    }
    return status;
  }

  bool _handleAuthFailure(Exception err) {
    setState(() {
      _checkAuthFuture = Future.error(err);
    });
    return false;
  }

  void _checkAuthStatus() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      try {

        var future =
            Provider.of<AuthenticationProvider>(context, listen: false)
                .checkAuthStatus()
                .then((value) => _handleAuthSuccess(value))
                .catchError((err) => _handleAuthFailure(err));

        setState(() {
          _checkAuthFuture = future;
        });

      } on Exception catch(e) {
        _handleAuthFailure(e);

      }

    });
  }


  void _startOOBE() {
    startProvisioning(context);
  }

  void _login() {
    showMaterialModalBottomSheet<bool>(
      context: context,
      builder: (context) => LoginPage()
    ).then((bool? result) {
      if(result != null) {
        _handleAuthSuccess(result);
      }
    });
  }

  void _useInvite() {
    showMaterialModalBottomSheet<bool>(
        context: context,
        builder: (context) => UseInviteCodePage()
    );
  }

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }
}