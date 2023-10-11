import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class BasicPage extends StatelessWidget {
  const BasicPage({super.key, required this.child, this.title, this.bgColor});

  final Widget child;
  final Widget? title;
  final Color? bgColor;

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close),
                  ),
                  if (title != null)
                    DefaultTextStyle.merge(
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 18),
                      child: title!,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class BasicFormContainer extends StatelessWidget {
  const BasicFormContainer(
      {super.key,
      this.buttonText,
      this.titleText,
      this.subtitleText,
      required this.children,
      this.future,
      this.onSubmit,
      this.hasButton = true});

  final bool hasButton;
  final String? buttonText;
  final String? titleText;
  final String? subtitleText;
  final Future? future;
  final VoidCallback? onSubmit;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: double.infinity,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.10),
                      offset: Offset(4.0, 4.0),
                      blurRadius: 10.0,
                      spreadRadius: 0.0,
                    ),
                  ],
                ),
                child: BasicForm(
                  hasButton: hasButton,
                  buttonText: buttonText,
                  titleText: titleText,
                  subtitleText: subtitleText,
                  future: future,
                  onSubmit: onSubmit,
                  children: children,
                ))));
  }
}

class BasicForm extends StatefulWidget {
  const BasicForm(
      {super.key,
      this.buttonText,
      this.titleText,
      this.subtitleText,
      required this.children,
      this.future,
      this.onSubmit,
      this.hasButton = true});

  final bool hasButton;
  final String? buttonText;
  final String? titleText;
  final String? subtitleText;
  final List<Widget> children;
  final Future? future;
  final VoidCallback? onSubmit;

  @override
  State<StatefulWidget> createState() => _BasicFormState();
}

class FormSubmitCallback extends InheritedWidget {
  const FormSubmitCallback({
    super.key,
    this.callback,
    required super.child,
  });

  final VoidCallback? callback;

  static FormSubmitCallback? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FormSubmitCallback>();
  }

  static FormSubmitCallback of(BuildContext context) {
    final FormSubmitCallback? result = maybeOf(context);
    assert(result != null, 'No FormSubmitCallback found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(FormSubmitCallback oldWidget) =>
      callback != oldWidget.callback;
}

class _BasicFormState extends State<BasicForm> {
  final _formKey = GlobalKey<FormState>();

  Widget _buildButtonContents(AsyncSnapshot snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SizedBox(
          height: 21,
          width: 21,
          child: CircularProgressIndicator(color: Colors.white));
    } else {
      return Text(
        widget.buttonText ?? 'Continue',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Colors.white),
      );
    }
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      if (widget.onSubmit != null) {
        widget.onSubmit!();
      }
    }
    ;
  }

  VoidCallback? _onPressed(AsyncSnapshot snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return null;
    } else {
      return () => _onSubmit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          if (widget.titleText != null)
            Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.titleText!,
                  style: Theme.of(context).textTheme.labelLarge,
                  textAlign: TextAlign.left,
                )),
          if (widget.subtitleText != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 22, right: 0),
                child: Text(
                  widget.subtitleText!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          Form(
            key: _formKey,
            child: FormSubmitCallback(
              callback: _onSubmit,
              child: Column(
                children: [
                  const SizedBox(
                    height: 15,
                  ),
                  ...widget.children,
                  const SizedBox(
                    height: 15,
                  ),
                  SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FutureBuilder(
                          future: widget.future,
                          builder: (context, snapshot) {
                            return OutlinedButton(
                                onPressed: _onPressed(snapshot),
                                style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    backgroundColor: const Color(0xff043C4D),
                                    foregroundColor: Colors.white,
                                    disabledForegroundColor: Colors.white,
                                    disabledBackgroundColor: Theme.of(context)
                                        .primaryColor
                                        .withAlpha(127)),
                                child: _buildButtonContents(snapshot));
                          })),
                ],
              ),
            ),
          )
        ]);
  }
}

class BasicPageTextFormField extends StatelessWidget {
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;
  final String labelText;
  final FormFieldSetter<String>? onSaved;
  final bool autofocus;
  final ValueChanged<String>? onFieldSubmitted;
  final bool obscureText;

  const BasicPageTextFormField(
      {super.key,
      this.validator,
      this.textInputAction = TextInputAction.next,
      required this.labelText,
      this.onSaved,
      this.autofocus = false,
      this.onFieldSubmitted,
      this.obscureText = false});

  ValueChanged<String>? _onFieldSubmitted(context) {
    if (onFieldSubmitted == null) {
      return null;
    } else {
      return (val) {
        onFieldSubmitted!(val);
        if (FormSubmitCallback.of(context).callback != null) {
          FormSubmitCallback.of(context).callback!();
        }
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          autofocus: autofocus,
          validator: validator,
          onSaved: onSaved,
          onFieldSubmitted: _onFieldSubmitted(context),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 18),
          textInputAction: textInputAction,
          decoration: InputDecoration(
              border: const OutlineInputBorder(), labelText: labelText),
          obscureText: obscureText,
        ),
        const SizedBox(
          height: 36,
        )
      ],
    );
  }
}
