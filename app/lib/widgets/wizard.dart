import 'package:app/service/provisioning_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WizardStepBodyDelegate extends StatelessWidget {
  const WizardStepBodyDelegate(
      {super.key,
      required this.provisionningProgress,
      this.title,
      this.subtext,
      this.child});

  final ProvisionningProgress provisionningProgress;
  final String? title;
  final String? subtext;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  child: Align(
                      child: Column(
                    children: [
                      if (provisionningProgress.step != 3)
                        Padding(
                            padding: EdgeInsets.only(
                                top: 34, bottom: title != null ? 36 : 70),
                            child: _buildTransition(
                                context: context,
                                child: WizardProgressBar(
                                    provisionningProgress:
                                        provisionningProgress))),
                      if (title != null)
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: _buildAnimatedText(
                                context: context,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                                text: title!)),
                      if (subtext != null)
                        Padding(
                            padding: const EdgeInsets.only(
                                top: 8, bottom: 24, left: 24, right: 24),
                            child: _buildAnimatedText(
                                context: context, text: subtext!)),
                      if (child != null) child!,
                    ],
                  )),
                )),
          ),
        ],
      ),
    );
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

class WizardProgressBar extends StatelessWidget {
  const WizardProgressBar({super.key, required this.provisionningProgress});

  final ProvisionningProgress provisionningProgress;

  @override
  Widget build(BuildContext context) {
    int selectedStage = provisionningProgress.stage - 1;
    var iconList = provisionningProgress.getIconList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int i = 0; i < iconList.length; i++) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: selectedStage == i
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).secondaryHeaderColor,
              ),
              child: SvgPicture.asset(
                colorFilter: ColorFilter.mode(
                  selectedStage == i ? Colors.white : Colors.black,
                  BlendMode.srcIn,
                ),
                iconList[i],
                width: 24,
                height: 24,
              ),
            ),
            if (i < iconList.length - 1) ...[
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 2,
                    width: 36,
                    color: Theme.of(context).secondaryHeaderColor,
                  ),
                  if (selectedStage > i)
                    Container(
                      height: 20,
                      width: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        color: Theme.of(context).secondaryHeaderColor,
                      ),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: SvgPicture.asset(
                          'lib/assets/SVG/CheckCircle.svg',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class WizardStep extends StatelessWidget {
  const WizardStep(
      {super.key,
      required this.provisionningProgress,
      this.icon,
      this.title,
      this.child,
      this.subtext,
      this.footer,
      this.onNextPressed,
      this.onSkipPressed,
      this.height,
      this.canGoNext = false,
      this.onBackPressed});

  final ProvisionningProgress provisionningProgress;
  final Widget? icon;
  final String? title;
  final String? subtext;
  final Widget? child;
  final Widget? footer;
  final VoidCallback? onBackPressed;
  final VoidCallback? onNextPressed;
  final VoidCallback? onSkipPressed;
  final double? height;
  final bool canGoNext;

  static const navFooterHeight = 72.0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFBFD2DB),
      body: Stack(
        children: [
          Column(
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
                      "STEP ${provisionningProgress.step} / 3",
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      provisionningProgress.getTitle(),
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                  ],
                ),
              ),
              height != null
                  ? SizedBox(
                      height: height,
                      child: WizardStepBodyDelegate(
                        title: title,
                        provisionningProgress: provisionningProgress,
                        subtext: subtext,
                        child: child,
                      ))
                  : Expanded(
                      //height: MediaQuery.of(context).size.height * 0.73,
                      child: WizardStepBodyDelegate(
                      title: title,
                      provisionningProgress: provisionningProgress,
                      subtext: subtext,
                      child: child,
                    )),
              if (footer != null)
                Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 100,
                      ),
                      child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          switchInCurve: Curves.easeIn,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return SlideTransition(
                              position: Tween(
                                begin: const Offset(0.0, 1.0),
                                end: const Offset(0.0, 0.0),
                              ).animate(animation),
                              child: child,
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, -3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: footer!,
                            ),
                          )),
                    ))
            ],
          ),
          Positioned(
            // Position the bottomNavigationBar at the bottom
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Theme.of(context).secondaryHeaderColor,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onBackPressed,
                      child: SizedBox(
                        height: navFooterHeight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.arrow_back,
                              size: 24,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Text('Back',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ),
                  ),
                  provisionningProgress.step == 1
                      ? const Expanded(
                          child: SizedBox(),
                        )
                      : Expanded(
                          child: GestureDetector(
                            onTap: canGoNext ? onNextPressed : onSkipPressed,
                            child: Container(
                              height: navFooterHeight,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(32),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(canGoNext ? "Next" : 'Skip',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.white)),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
