import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app/apiv2/models/device.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BinContainer extends StatefulWidget {
  final bool isToday;
  final String icon;
  final BinStatus status;
  final bool isDeviceActive;
  final bool isOpen;

  const BinContainer({
    super.key,
    required this.isToday,
    required this.icon,
    required this.status,
    required this.isDeviceActive,
    this.isOpen = false,
  });

  @override
  State<BinContainer> createState() => _BinContainerState();
}

class _BinContainerState extends State<BinContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
    
    // Start blinking only if status is TAKE_NOW
    if (widget.status == BinStatus.take_now) {
      _blinkController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BinContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update animation based on status change
    if (widget.status == BinStatus.take_now && oldWidget.status != BinStatus.take_now) {
      _blinkController.repeat(reverse: true);
    } else if (widget.status != BinStatus.take_now && oldWidget.status == BinStatus.take_now) {
      _blinkController.stop();
      _blinkController.reset();
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Background color: yellow if door is open, otherwise blue variants
    Color backgroundColor;
    if (widget.isOpen) {
      backgroundColor = const Color(0xFFFFD700); // Yellow for open door
    } else if (widget.isDeviceActive) {
      backgroundColor =
          widget.isToday ? const Color(0xFF206B8B) : const Color(0xFFBFD2DB);
    } else {
      backgroundColor = Colors.white;
    }

    String iconName = widget.isDeviceActive
        ? (widget.isToday ? '${widget.icon}White' : widget.icon)
        : widget.icon;

    String binStatusIconPath =
        _getBinStatusIcon(widget.status, widget.isDeviceActive);

    return Container(
      // 108 is the padding on each side of the pillbox and the padding between the column
      width: ((MediaQuery.of(context).size.width - 108.w) / 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0).r,
        border: widget.isDeviceActive
            ? null
            : Border.all(
                color: const Color(0xFF206B8B),
                width: 1.5.w,
              ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 14.h),
            child: SvgPicture.asset(
              'lib/assets/SVG/$iconName.svg',
              height: 20.h,
            ),
          ),
          const Spacer(), // This will push the bottom icon to the bottom
          Padding(
            padding: EdgeInsets.only(bottom: 5.h),
            child: widget.status == BinStatus.take_now
                ? AnimatedBuilder(
                    animation: _blinkAnimation,
                    builder: (context, child) {
                      final iconPath = _blinkAnimation.value > 0.5
                          ? 'lib/assets/SVG/greenlight.svg'
                          : 'lib/assets/SVG/offlight.svg';
                      return SvgPicture.asset(
                        iconPath,
                        height: 30.h,
                      );
                    },
                  )
                : SvgPicture.asset(
                    binStatusIconPath,
                    height: 30.h,
                  ),
          ),
        ],
      ),
    );
  }

  String _getBinStatusIcon(BinStatus status, bool isActive) {
    if (isActive) {
      switch (status) {
        case BinStatus.missed:
          return 'lib/assets/SVG/redlight.svg';
        case BinStatus.taken:
        case BinStatus.take_now:
          return 'lib/assets/SVG/greenlight.svg'; // Blinks green
        case BinStatus.disabled:
        case BinStatus.pending:
        case BinStatus.noRecord:
          return 'lib/assets/SVG/offlight.svg';
      }
    } else {
      return 'lib/assets/SVG/cancelIcon.svg';
    }
  }
}
