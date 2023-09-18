import 'package:flutter/material.dart';

class WizardStepBodyDelegate extends StatelessWidget {
  const WizardStepBodyDelegate(
      {super.key,
      this.icon,
      this.title,
      this.subtext,
      this.hasBackButton = true,
      this.onBackPressed,
      this.child});

  final Widget? icon;
  final String? title;
  final String? subtext;
  final bool hasBackButton;
  final VoidCallback? onBackPressed;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverSafeArea(
            sliver: SliverFillRemaining(
                hasScrollBody: true,
                child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.1),
                          offset: Offset(4, 4),
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 27,
                          left: 12,
                          child: BackButton(
                            onPressed: onBackPressed,
                          ),
                        ),
                        Align(
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (icon != null)
                                  Padding(
                                      padding: const EdgeInsets.only(
                                          top: 40, bottom: 20),
                                      child: Theme(
                                          data: Theme.of(context).copyWith(
                                              iconTheme: IconThemeData(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary)),
                                          child: _buildTransition(
                                              context: context, child: icon!))),
                                if (title != null)
                                  _buildAnimatedText(
                                      context: context,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(fontSize: 22),
                                      text: title!),
                                if (subtext != null)
                                  Padding(
                                      padding: const EdgeInsets.only(
                                          top: 20,
                                          bottom: 20,
                                          left: 40,
                                          right: 40),
                                      child: _buildAnimatedText(
                                          context: context, text: subtext!)),
                                if (child != null) child!,
                              ],
                            )),
                      ],
                    ))),
          ),
        ],
      ),
    ));
  }

  Widget _buildTransition({context, child}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 0),
      switchInCurve: Curves.easeIn,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: child,
    );
  }

  Widget _buildAnimatedText({context, style, text}) {
    return _buildTransition(
        context: context,
        child: Text(text,
            key: ValueKey<String>(text),
            style: style,
            textAlign: TextAlign.center));
  }
}

class WizardStep extends StatelessWidget {
  const WizardStep(
      {super.key,
      required this.stepNumber,
      required this.stepTitle,
      this.icon,
      this.title,
      this.child,
      this.subtext,
      this.footer,
      this.hasBackButton = true,
      this.fullscreen = false,
      this.onBackPressed});

  final String stepNumber;
  final String stepTitle;
  final Widget? icon;
  final String? title;
  final String? subtext;
  final Widget? child;
  final Widget? footer;
  final bool hasBackButton;
  final VoidCallback? onBackPressed;
  final bool? fullscreen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFBFD2DB),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "STEP $stepNumber / 3",
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    stepTitle,
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ],
              ),
            ),
            fullscreen!
                ? WizardStepBodyDelegate(
                    title: title,
                    icon: icon,
                    subtext: subtext,
                    hasBackButton: hasBackButton,
                    onBackPressed: onBackPressed,
                    child: child,
                  )
                : SizedBox(
                    height: 400,
                    child: WizardStepBodyDelegate(
                      title: title,
                      icon: icon,
                      subtext: subtext,
                      hasBackButton: hasBackButton,
                      onBackPressed: onBackPressed,
                      child: child,
                    )),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: Tween(
                    begin: const Offset(0.0, 1.0),
                    end: const Offset(0.0, 0.0),
                  ).animate(animation),
                  child: child,
                );
              },
              child: footer != null
                  ? Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(
                                0, -3), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: footer!,
                      ),
                    )
                  : Container(
                      key: UniqueKey(),
                    ),
            )
          ],
        ));
  }
}
