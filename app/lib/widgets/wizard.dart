

import 'dart:math';

import 'package:flutter/material.dart';

class WizardStepHeaderDelegate extends SliverPersistentHeaderDelegate {
  WizardStepHeaderDelegate({
    this.icon, this.title, this.subtext, this.hasBackButton = true,
    this.onBackPressed
  });

  final double _maxExtent = 280;
  final double _minExtent = 100;

  final Widget? icon;
  final String? title;
  final String? subtext;
  final bool hasBackButton;
  final VoidCallback? onBackPressed;


  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(_shadowOpacity(shrinkOffset)),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 3), // changes position of shadow
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
              alignment: Alignment(_xOffset(shrinkOffset), 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if(icon != null && _percent(shrinkOffset) > 0.75) Padding(
                      padding: const EdgeInsets.only(top: 40, bottom: 20),
                      child: Theme(
                        data: Theme.of(context).copyWith(iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary)),
                        child: _buildTransition(context: context, child: icon!)
                      )
                  ),
                  if(title != null) _buildAnimatedText(
                    context: context,
                    style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontSize: 22 * _fontMultiplier(shrinkOffset)),
                    text: title!
                  ),
                  if(subtext != null && _percent(shrinkOffset) > 0.75) Padding(
                      padding: const EdgeInsets.only(
                          top: 20, bottom: 20, left: 40, right: 40),
                      child: _buildAnimatedText(
                        context: context,
                        text: subtext!
                      )
                  )
                ],
              )
          )
        ],
      )
    );
  }

  Widget _buildTransition({context, child}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 0),
      switchInCurve: Curves.easeIn,
      transitionBuilder:
          (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: child,
    );
  }

  Widget _buildAnimatedText({context, style, text}) {
    return _buildTransition(context: context, child: Text(
        text,
        key: ValueKey<String>(text),
        style: style,
        textAlign: TextAlign.center
    ));
  }

  double _percent(shrinkOffset) => 1.0 - (shrinkOffset / _maxExtent);

  double _backButtonOffset() => hasBackButton ? 140 : 40;

  double _xOffset(shrinkOffset) {
    return -(shrinkOffset > _maxExtent - _backButtonOffset()
        ? _maxExtent - _backButtonOffset()
        : shrinkOffset) /
        _maxExtent;
  }

  double _fontMultiplier(shrinkOffset) {
    return max(0.90, (1.0 - (shrinkOffset / _maxExtent) * (_minExtent / _maxExtent)));
  }

  double _shadowOpacity(shrinkOffset) {
    return (shrinkOffset / _maxExtent) * 0.2;
  }


  @override
  double get maxExtent => _maxExtent;

  @override
  double get minExtent => _minExtent;

  @override
  bool shouldRebuild(covariant WizardStepHeaderDelegate oldDelegate) {
    return oldDelegate != this;
  }
}

class WizardStep extends StatelessWidget {
  const WizardStep({
    super.key,
    this.icon,
    this.title,
    this.child,
    this.subtext,
    this.footer,
    this.hasBackButton = true,
    this.onBackPressed
  });

  final Widget? icon;
  final String? title;
  final String? subtext;
  final Widget? child;
  final Widget? footer;
  final bool hasBackButton;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverSafeArea(
                sliver: SliverPersistentHeader(
                  pinned: true,
                  delegate: WizardStepHeaderDelegate(
                    title: title,
                    icon: icon,
                    subtext: subtext,
                    hasBackButton: hasBackButton,
                    onBackPressed: onBackPressed
                  ),
                ),
              ),
              if(child != null) child!,
            ],
          ),
        ),
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
          child: footer != null ? Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -3), // changes position of shadow
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: footer!,
            ),
          ) :
          Container(
            key: UniqueKey(),
          ),
        )
      ],
    );
  }

}

class DecoratedWizardStep extends StatefulWidget {
  const DecoratedWizardStep({
    super.key, this.icon, this.title, this.subtext, this.child
  });

  final Widget? icon;
  final String? title;
  final String? subtext;
  final Widget? child;


  @override
  State<StatefulWidget> createState() => _DecoratedWizardStep();

}

class _DecoratedWizardStep extends State<DecoratedWizardStep> {

  final GlobalKey<FormState> formKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: WizardStep(
        icon: widget.icon,
        title: widget.title,
        subtext: widget.subtext,
        child: widget.child,
        footer: ElevatedButton(onPressed: null, child: Text('Continue')
        ),
      ),
    );
  }

}