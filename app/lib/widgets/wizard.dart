import 'package:app/service/provisioning_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WizardStepBodyDelegate extends StatelessWidget {
  const WizardStepBodyDelegate(
      {super.key,
      required this.provisionningProgress,
      this.title,
      this.icon,
      this.subtext,
      this.child});

  final ProvisionningProgress provisionningProgress;
  final String? title;
  final Widget? icon;
  final String? subtext;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverSafeArea(
            sliver: SliverFillRemaining(
                hasScrollBody: true,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(12.r)),
                    boxShadow: const [
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
                      provisionningProgress.step != 3
                          ? Padding(
                              padding: EdgeInsets.only(
                                      top: 34.h,
                                      bottom: title != null ? 36.h : 70.h)
                                  .h,
                              child: _buildTransition(
                                  context: context,
                                  child: WizardProgressBar(
                                      provisionningProgress:
                                          provisionningProgress)))
                          : SizedBox(
                              height: 40.h,
                            ),
                      if (title != null)
                        Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24).w,
                            child: _buildAnimatedText(
                                context: context,
                                style: Theme.of(context).textTheme.titleMedium,
                                text: title)),
                      if (icon != null)
                        Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24).w,
                            child: _buildTransition(
                                context: context, child: icon)),
                      if (subtext != null)
                        Padding(
                            padding: EdgeInsets.only(
                                top: 8.h,
                                bottom: 24.h,
                                left: 24.w,
                                right: 24.w),
                            child: SizedBox(
                              child: _buildAnimatedText(
                                  context: context, text: subtext!),
                            )),
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
      padding: EdgeInsets.symmetric(horizontal: 36.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int i = 0; i < iconList.length; i++) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 8.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8).r,
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
                width: 24.w,
                height: 24.h,
              ),
            ),
            if (i < iconList.length - 1) ...[
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 2.h,
                    width: 36.w,
                    color: Theme.of(context).secondaryHeaderColor,
                  ),
                  if (selectedStage > i)
                    Container(
                      height: 20.h,
                      width: 20.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32).r,
                        color: Theme.of(context).secondaryHeaderColor,
                      ),
                      child: SizedBox(
                        width: 50.w,
                        height: 50.h,
                        child: SvgPicture.asset(
                          'lib/assets/SVG/CheckCircle.svg',
                          width: 24.w,
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
                padding: EdgeInsets.only(left: 24.w, top: 100.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${AppLocalizations.of(context)!.step} ${provisionningProgress.step} / 3",
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    Text(
                      provisionningProgress.getTitle(context),
                      textAlign: TextAlign.left,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontSize: 32.h),
                    ),
                  ],
                ),
              ),
              height != null
                  ? SizedBox(
                      height: height,
                      child: WizardStepBodyDelegate(
                        title: title,
                        icon: icon,
                        provisionningProgress: provisionningProgress,
                        subtext: subtext,
                        child: child,
                      ))
                  : Expanded(
                      child: WizardStepBodyDelegate(
                      title: title,
                      icon: icon,
                      provisionningProgress: provisionningProgress,
                      subtext: subtext,
                      child: child,
                    )),
              if (footer != null)
                Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 8.h,
                        bottom: navFooterHeight,
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
                          child: SizedBox(
                            width: double.infinity,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20.w, vertical: 20.h),
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
                      child: Container(
                        color: Colors.transparent,
                        child: SizedBox(
                          height: navFooterHeight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_back,
                                size: 24.h,
                              ),
                              SizedBox(
                                width: 8.w,
                              ),
                              Text(AppLocalizations.of(context)!.back,
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
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
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(32).r,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                      canGoNext
                                          ? AppLocalizations.of(context)!.next
                                          : AppLocalizations.of(context)!.skip,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.white)),
                                  SizedBox(
                                    width: 8.w,
                                  ),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    size: 24.h,
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
