import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class BasicPage extends StatelessWidget {
  const BasicPage({super.key, required this.child, this.title});

  final Widget child;
  final Widget? title;

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
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
                    icon: const Icon(Icons.close)),
                if (title != null)
                  DefaultTextStyle.merge(
                      style: Theme.of(context).textTheme.labelLarge,
                      child: title!)
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: child,
          )
        ],
      ),
    ));
  }
}

class BasicForm extends StatefulWidget {
  const BasicForm(
      {super.key,
      this.buttonText,
      required this.children,
      this.future,
      this.onSubmit,
      this.hasButton = true});

  final bool hasButton;
  final String? buttonText;
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
      return Text(widget.buttonText ?? 'Continue');
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
    return Form(
      key: _formKey,
      child: FormSubmitCallback(
        callback: _onSubmit,
        child: Column(
          children: [
            const SizedBox(
              height: 15,
            ),
            ...widget.children,
            SizedBox(
                width: double.infinity,
                child: FutureBuilder(
                    future: widget.future,
                    builder: (context, snapshot) {
                      return OutlinedButton(
                          onPressed: _onPressed(snapshot),
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(12),
                              backgroundColor: Theme.of(context).primaryColor,
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
    );
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
        FormSubmitCallback.of(context).callback!();
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
          style: Theme.of(context).textTheme.labelLarge,
          textInputAction: textInputAction,
          decoration: InputDecoration(
              border: const OutlineInputBorder(), labelText: labelText),
          obscureText: obscureText,
        ),
        const SizedBox(
          height: 15,
        )
      ],
    );
  }
}
