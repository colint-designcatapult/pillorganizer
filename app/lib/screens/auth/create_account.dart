import 'package:app/api/api.dart';
import 'package:app/platform/dialog.dart';
import 'package:app/provider/authentication_provider.dart';
import 'package:app/provider/user_registration_provider.dart';
import 'package:app/service/authentication_service.dart';
import 'package:app/widgets/basic_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:validatorless/validatorless.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({Key? key}) : super(key: key);

  static Route<CreateAccountPage> route(context) {
    return platformPageRoute(
        context: context, builder: (_) => const CreateAccountPage());
  }

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  bool _obscureText = true;
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserRegistrationProvider>(
        create: (_) => UserRegistrationProvider(),
        child: BasicPage(
          title: Text(AppLocalizations.of(context)!.createAccount),
          child: Builder(builder: (context) {
            return BasicForm(
              buttonText: AppLocalizations.of(context)!.genericContinue,
              onSubmit: () => _submit(context),
              future: Provider.of<UserRegistrationProvider>(context).future,
              children: [
                BasicPageTextFormField(
                  labelText: AppLocalizations.of(context)!.email,
                  validator: Validatorless.multiple([
                    Validatorless.email(
                        AppLocalizations.of(context)!.emailNotValid),
                    Validatorless.required(
                        AppLocalizations.of(context)!.emailRequired)
                  ]),
                  autofocus: true,
                  onSaved: (val) {
                    context.read<UserRegistrationProvider>().updateEmail(val);
                  },
                ),
                BasicPageTextFormField(
                  labelText: AppLocalizations.of(context)!.password,
                  validator: Validatorless.multiple([
                    Validatorless.between(6, 48,
                        AppLocalizations.of(context)!.passwordLengthValidation)
                  ]),
                  onRevealText: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                  obscureText: _obscureText,
                  textInputAction: TextInputAction.done,
                  onSaved: (val) {
                    context
                        .read<UserRegistrationProvider>()
                        .updatePassword(val);
                  },
                  onFieldSubmitted: (val) {
                    context
                        .read<UserRegistrationProvider>()
                        .updatePassword(val);
                  },
                )
              ],
            );
          }),
        ));
  }

  void _submit(context) {
    var prov = Provider.of<UserRegistrationProvider>(context, listen: false);
    var authProv = Provider.of<AuthenticationProvider>(context, listen: false);
    _register(prov, authProv).catchError((err) {
      _handleError(context, err);
      return false;
    }).then((value) {
      if (value) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          Navigator.pop(context);
        });
      }
    });
  }

  Future<bool> _register(
      UserRegistrationProvider prov, AuthenticationProvider authProv) async {
    await prov.register();
    await authProv.logIn(
        username: prov.model.email, password: prov.model.password);
    return true;
  }

  void _handleError(context, err) {
    debugPrint(err.toString());
    if (err is ProblemJsonException) {
      showAlertDialog(
          context, AppLocalizations.of(context)!.genericProblem(err.problem));
    } else {
      showAlertDialog(
          context,
          AppLocalizations.of(context)!
              .genericProblem(authErrorMessage(context, err.toString())));
    }
  }
}
