import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/provider/provision_provider.dart';
import 'provision.dart';
import 'wifi_select_screen.dart';
import 'connecting_screen.dart';

class ProvisionFlowPage extends ConsumerStatefulWidget {
  const ProvisionFlowPage({super.key});

  static Route<ProvisionFlowPage> route() =>
      MaterialPageRoute(builder: (_) => const ProvisionFlowPage());

  @override
  ConsumerState<ProvisionFlowPage> createState() => _ProvisionFlowPageState();
}

class _ProvisionFlowPageState extends ConsumerState<ProvisionFlowPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(provisionProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(provisionProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(provisionProvider.notifier).cancelProvisioning();
        Navigator.of(context).pop();
      },
      child: switch (state) {
        ProvisionStateScanningBle() || 
        ProvisionStateSelectBle() || 
        ProvisionStateMissingPermissions() => const ProvisionPage(),
        
        ProvisionStateTimeout(wifiNetworks: var wifi) when wifi.isNotEmpty => const ProvisionSelectWifiPage(),
        ProvisionStateFailed(wifiNetworks: var wifi) when wifi.isNotEmpty => const ProvisionSelectWifiPage(),

        ProvisionStateTimeout() ||
        ProvisionStateFailed() => const ProvisionPage(),
        
        ProvisionStateScanningWifi() || 
        ProvisionStateSelectWifi() || 
        ProvisionStateFetchingSerial() => const ProvisionSelectWifiPage(),
        
        ProvisionStateProvisioningWifi() || 
        ProvisionStateComplete() => const ProvisionConnectingPage(),
      },
    );
  }
}
