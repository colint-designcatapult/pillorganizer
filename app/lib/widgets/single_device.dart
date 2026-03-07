import 'package:app/apiv2/models/device.dart';
import 'package:app/apiv2/mqtt.dart';
import 'package:app/widgets/device_rename_modal.dart';
import 'package:app/widgets/notifications_settings.dart';
import 'package:app/widgets/schedule_entry.dart';
import 'package:app/widgets/share_device.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void changeName(context, {DeviceMetadata? device}) {
  showDialog(
    context: context,
    builder: (_) => ChangeDeviceNameDialog(device: device),
  );
}

class MqttListenerScreen extends ConsumerWidget {
  const MqttListenerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the stream provider
    final mqttStream = ref.watch(mqttTopicStreamProvider);

    return Center(
        child: mqttStream.when(
          // Triggers when a new message arrives on the topic
          data: (message) => Text(
            'Latest Message:\n$message',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          // Triggers if the connection fails or throws an error
          error: (err, stack) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error: $err',
              style: const TextStyle(color: Colors.red),
            ),
          ),

          // Triggers while connecting to the broker
          loading: () => const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting to MQTT over WebSocket...'),
            ],
          ),
        )
    );
  }
}

class SingleDevice extends StatefulWidget {
  final DeviceMetadata? device;
  final bool showAddDeviceSection;
  final bool isModal;

  const SingleDevice({
    super.key,
    required this.device,
    required this.showAddDeviceSection,
    this.isModal = false,
  });

  @override
  State<SingleDevice> createState() => _SingleDeviceState();
}

class _SingleDeviceState extends State<SingleDevice> {
  int _selectedButtonIndex = 0;

  Widget _getSelectedSection(int index) {
    switch (index) {
      case 0:
        return ScheduleEntry(
            showAddDeviceSection: widget.showAddDeviceSection,
            device: widget.device);
      case 1:
        return NotificationsSettings(device: widget.device);
      case 2:
        return ShareDevice(device: widget.device);
      default:
        return ScheduleEntry(
            showAddDeviceSection: widget.showAddDeviceSection,
            device: widget.device);
    }
  }

  List<ButtonSegment> _getSegments() {
    return [
      ButtonSegment(
        value: 0,
        label: Text(
          AppLocalizations.of(context)!.settings,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 12.h,
                color: const Color(0xFF31454D),
              ),
        ),
      ),
      ButtonSegment(
        value: 1,
        label: Text(
          AppLocalizations.of(context)!.notifications,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 12.h,
                color: const Color(0xFF31454D),
              ),
        ),
      ),
      ButtonSegment(
        value: 2,
        label: Text(
          AppLocalizations.of(context)!.share,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 12.h,
                color: const Color(0xFF31454D),
              ),
        ),
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    bool isOwner = widget.device?.primaryUser ?? false;
    List<ButtonSegment> segments = _getSegments();

    return Container(
      margin: widget.isModal
          ? EdgeInsets.only(top: 60.h)
          : EdgeInsets.only(bottom: 60.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12.0).r,
          topRight: const Radius.circular(12.0).r,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.only(
              top: 24.h,
              bottom: 12.h,
              left: 20.w,
              right: 20.w,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.isModal)
                  IconButton(
                    icon: Icon(
                      PhosphorIconsRegular.x,
                      size: 24.h,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(
                    child: Text(
                      widget.device?.name ??
                          AppLocalizations.of(context)!.loadingState,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 30.h,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isOwner)
                    IconButton(
                      icon: SvgPicture.asset(
                        'lib/assets/SVG/pencilLight.svg',
                        width: 24.w,
                        height: 24.h,
                      ),
                      color: Theme.of(context).primaryColor,
                      onPressed: () {
                        changeName(context, device: widget.device);
                      },
                    ),
                ]),
              ],
            ),
          ),
          MqttListenerScreen(),
          if (isOwner)
            Container(
              padding: EdgeInsets.only(
                top: 12.h,
                bottom: 12.h,
                left: 20.w,
                right: 20.w,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton(
                      segments: segments,
                      selected: {_selectedButtonIndex},
                      showSelectedIcon: false,
                      onSelectionChanged: (Set newSelection) {
                        setState(() {
                          _selectedButtonIndex = newSelection.first;
                        });
                      },
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all<OutlinedBorder>(
                            RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadiusDirectional.circular(8.r))),
                        side: WidgetStateProperty.resolveWith<BorderSide>(
                            (Set<WidgetState> states) {
                          return BorderSide(
                              color: const Color(0xFFBFD2DB), width: 1.h);
                        }),
                        backgroundColor:
                            WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return const Color(0xFFF1F5F6);
                          }
                          return Colors.white;
                        }),
                        padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                          EdgeInsets.symmetric(vertical: 16.h, horizontal: 0.w),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                  child: _getSelectedSection(_selectedButtonIndex)),
            ),
          )
        ],
      ),
    );
  }
}
