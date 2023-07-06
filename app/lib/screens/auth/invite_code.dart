import 'package:flutter/material.dart';
import 'package:validatorless/validatorless.dart';

class UseInviteCodePage extends StatefulWidget {
  const UseInviteCodePage({Key? key}) : super(key: key);

  @override
  State<UseInviteCodePage> createState() => _UseInviteCodePageState();
}

class _UseInviteCodePageState extends State<UseInviteCodePage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(onPressed: (){
                      Navigator.of(context).pop();
                    }, icon: Icon(Icons.close)),
                    Text(
                      'Activate invite code',
                      style: Theme.of(context).textTheme.titleMedium,
                    )
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 15,
                      ),
                      TextFormField(
                        autofocus: true,
                        validator: Validatorless.required('Enter a code'),
                        style: Theme.of(context).textTheme.labelLarge,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Invite code',
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                            onPressed: null,
                            style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.all(12),
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                disabledForegroundColor: Colors.white,
                                disabledBackgroundColor: Theme.of(context).primaryColor.withAlpha(127)
                            ),
                            child: Text('Continue')
                        )
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        )
    );
  }



}
