// import 'package:app/api/api.dart';
import 'package:app/provider/device_state_provider.dart';
import 'package:app/screens/ScreenUtilWrapper.dart';
import 'package:app/widgets/device_info_header.dart';
import 'package:app/widgets/homeBodies/home_body_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Note: The original had StatefulWrapper for onInit. 
    // We can use a simple useEffect-like pattern or just do it in build if safe,
    // but better to keep it clean. For permissions, build is fine if we guard.
    _askPermissions(context);

    final deviceStateAsync = ref.watch(deviceStateProvider);

    return ScreenUtilWrapper(
      child: Scaffold(
        body: Stack(children: [
          Container(
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.3317],
                colors: [
                  Color(0xFF206B8B),
                  Color(0xFF002D40),
                ],
              ),
            ),
          ),
          NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  toolbarHeight: 160.h,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    expandedTitleScale: 1.0,
                    titlePadding: const EdgeInsets.symmetric(
                        horizontal: 0, vertical: 0),
                    title: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 24.w, vertical: 12.h),
                          child: const DeviceInfoHeader(),
                        ),
                      ],
                    ),
                  ),
                  pinned: false,
                ),
              ];
            },
            body: deviceStateAsync.when(
              data: (_) => const HomeBodySelector(),
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
              error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _askPermissions(BuildContext context) async {
    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
    }
  }
}
