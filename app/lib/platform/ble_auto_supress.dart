import 'package:flutter/cupertino.dart';
import '../main.dart';

class BLEAutoSuppress extends StatefulWidget {
  const BLEAutoSuppress({super.key, required this.child});

  final Widget child;

  @override
  State<BLEAutoSuppress> createState() => BLEAutoSuppressState();
}

// Implement RouteAware in a widget's state and subscribe it to the RouteObserver.
class BLEAutoSuppressState extends State<BLEAutoSuppress> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPushNext() {
    //Provider.of<DeviceBluetoothProvider>(context, listen: false).suppress();
  }

  @override
  void didPopNext() {
    // Covering route was popped off the navigator.
    //Provider.of<DeviceBluetoothProvider>(context, listen: false).unsuppress();
  }

  @override
  void initState() {
    super.initState();
    //Provider.of<DeviceBluetoothProvider>(context, listen: false).unsuppress();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
