import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
                          ?.copyWith(fontSize: 18.sp),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
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
        widget.buttonText ?? AppLocalizations.of(context)!.genericContinue,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Colors.white)
            .copyWith(fontWeight: FontWeight.w600),
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
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          Form(
            key: _formKey,
            child: FormSubmitCallback(
              callback: _onSubmit,
              child: Column(
                children: [
                  SizedBox(
                    height: 15.h,
                  ),
                  ...widget.children,
                  SizedBox(
                    height: 15.h,
                  ),
                  SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: FutureBuilder(
                          future: widget.future,
                          builder: (context, snapshot) {
                            return OutlinedButton(
                                onPressed: _onPressed(snapshot),
                                style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 12),
                                    backgroundColor: const Color(0xff206B8B),
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

class SixDigitCodeInput extends StatefulWidget {
  final Function(String) onSubmitted;
  final bool reset;
  final bool inError;

  const SixDigitCodeInput(
      {Key? key,
      required this.onSubmitted,
      this.reset = false,
      this.inError = false})
      : super(key: key);

  @override
  State<SixDigitCodeInput> createState() => _SixDigitCodeInputState();
}

class _SixDigitCodeInputState extends State<SixDigitCodeInput> {
  bool _shouldReset = false;
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  // Track filled state for each digit
  final List<bool> _isFilled = List.generate(6, (_) => false);

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _resetNumber() {
    for (var controller in _controllers) {
      controller.clear();
    }

    FocusScope.of(context).requestFocus(FocusNode());
  }

  @override
  void didUpdateWidget(covariant SixDigitCodeInput oldWidget) {
    if (widget.reset && !_shouldReset) {
      _shouldReset = true;
      _resetNumber();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(
        6,
        (index) => SizedBox(
          width: 46.w,
          child: TextField(
            controller: _controllers[index],
            onChanged: (value) {
              // Update filled state
              setState(() {
                _isFilled[index] = value.isNotEmpty;
              });

              if (value.length == 1 && index < 5) {
                FocusScope.of(context).nextFocus();
              }
              if (index == 5 && value.isNotEmpty) {
                String code = '';
                _controllers.forEach((controller) => code += controller.text);
                widget.onSubmitted(code);
              }
            },
            maxLength: 1,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                  fontSize: 36.sp,
                ),
            decoration: InputDecoration(
              filled: true,
              fillColor: widget.inError
                  ? const Color(0xffFEF3F2) // Light red for error
                  : _isFilled[index]
                      ? const Color(0xFFF1F5F6)
                      : Colors.transparent,
              // Transparent when empty and no error
              contentPadding: EdgeInsets.symmetric(
                horizontal: 9.w,
                vertical: 16.h,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: widget.inError
                    ? const BorderSide(color: Color(0xffFAD2CF), width: 2)
                    : const BorderSide(color: Color(0xffBED4D8), width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: widget.inError
                    ? const BorderSide(color: Color(0xffFAD2CF), width: 2)
                    : const BorderSide(color: Color(0xff206B8B), width: 2),
              ),
              counterText: '',
            ),
          ),
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
  final ValueChanged<String>? onChanged;
  final VoidCallback? onRevealText;
  final bool obscureText;
  final double? paddingBottom;

  const BasicPageTextFormField(
      {super.key,
      this.validator,
      this.textInputAction = TextInputAction.next,
      required this.labelText,
      this.onSaved,
      this.autofocus = false,
      this.onFieldSubmitted,
      this.onChanged,
      this.onRevealText,
      this.obscureText = false,
      this.paddingBottom});

  ValueChanged<String>? _onFieldSubmitted(context) {
    if (onFieldSubmitted == null) {
      return null;
    } else {
      return (val) {
        onFieldSubmitted!(val);
        if (FormSubmitCallback.maybeOf(context) != null) {
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
          onChanged: onChanged,
          onFieldSubmitted: _onFieldSubmitted(context),
          style:
              Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 18.h),
          textInputAction: textInputAction,
          decoration: InputDecoration(
              suffixIcon: onRevealText != null
                  ? IconButton(
                      icon: Icon(
                          obscureText ? Icons.visibility_off : Icons.visibility,
                          size: 24.h),
                      onPressed: onRevealText!,
                    )
                  : null,
              border: const OutlineInputBorder(),
              labelText: labelText),
          obscureText: obscureText,
        ),
        SizedBox(
          height: paddingBottom != null ? paddingBottom!.h : 36.h,
        )
      ],
    );
  }
}
