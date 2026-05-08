import 'package:app/provider/control_plane_providers.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class JoinDevicePage extends ConsumerStatefulWidget {
  const JoinDevicePage({super.key});

  static Route<JoinDevicePage> route(context) {
    return MaterialPageRoute(
        builder: (_) {
          return const JoinDevicePage();
        });
  }

  @override
  ConsumerState<JoinDevicePage> createState() => _JoinDevicePageState();
}

class _JoinDevicePageState extends ConsumerState<JoinDevicePage> {
  String? _userEmail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    try {
      final client = ref.read(controlPlaneClientProvider);
      final userDetails = await client.getUserDetails();
      if (mounted) {
        setState(() {
          _userEmail = userDetails.email;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFBFD2DB),
        body: Container(
          constraints: BoxConstraints.expand(
            height: MediaQuery.of(context).size.height,
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  SizedBox(height: 100.h),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Text(
                      AppLocalizations.of(context)!.joinExistingDevice,
                      textAlign: TextAlign.left,
                      softWrap: true,
                      overflow: TextOverflow.fade,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontSize: 32.h),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    child: Material(
                      elevation: 4,
                      shadowColor: const Color.fromRGBO(0, 0, 0, 0.1),
                      borderRadius: BorderRadius.all(Radius.circular(12.r)),
                      child: Container(
                        padding: EdgeInsets.all(20.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.all(Radius.circular(12.r)),
                        ),
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _informationSection(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          height: 72.h,
          color: Theme.of(context).secondaryHeaderColor,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 72.h,
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
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _informationSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.joinDeviceTitle,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 20),
          child: Text(
            AppLocalizations.of(context)!.joinDeviceSubtext,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
          ),
        ),
        if (_userEmail != null) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F6),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: const Color(0xFFBFD2DB)),
            ),
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context)!.yourEmail,
                  style: TextStyle(
                    fontSize: 14.h,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4.h),
                SelectableText(
                  _userEmail!,
                  style: TextStyle(
                    fontSize: 18.h,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF31454D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}