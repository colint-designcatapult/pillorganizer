import 'dart:async';
import 'dart:convert';

import 'package:app/api/api.dart';
import 'package:app/api/provision.dart';
import 'package:app/provider/authentication_provider.dart';
import 'package:convert/convert.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_esp_ble_prov/flutter_esp_ble_prov.dart';
import 'package:provider/provider.dart';

class ProvisionProvider extends ChangeNotifier {
  late ProvisionState _state;
  ProvisionState get state => _state;

  final _flutterEspBleProvPlugin = FlutterEspBleProv();
  final String _prefix = "PROV_";
  final String _popKey = "abcd1234";
  final Duration completionTimeout = const Duration(minutes: 1);
  final Duration completionCheckPeriod = const Duration(seconds: 5);

  Timer? _timer;

  ProvisionProvider({ProvisionState? initialState}) {
    if (initialState != null) {
      _state = initialState;
    } else {
      _state = const ProvisionState();
    }
  }

  Future<ProvisionState> _scanWifi() async {
    String deviceName = _state.deviceName!;
    var res =
        await _flutterEspBleProvPlugin.scanWifiNetworks(deviceName, _popKey);
    var list = res.map((e) => WifiEntry.fromMap(e)).toList(growable: false);

    _state = _state.copyWith(
        deviceName: deviceName,
        wifiNetworks: list,
        stage: ProvisionStage.select_wifi);
    notifyListeners();
    return _state;
  }

  Future<ProvisionState> scanWifi() {
    _state = _state.copyWith(progress: 0.0);
    notifyListeners();

    _timer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      var halfRemaining = (1.0 - (_state.progress ?? 0)) / 32;
      _state =
          _state.copyWith(progress: (_state.progress ?? 0.0) + halfRemaining);
      notifyListeners();
    });

    // Timeout timer
    return _scanWifi()
        .timeout(const Duration(seconds: 999999))
        .whenComplete(() {
      _timer?.cancel();
    });
  }

  Future<ProvisionState> rescanBluetooth() {
    _state = _state.copyWith(
        stage: ProvisionStage.scanning_ble,
        wifiNetworks: null,
        future: scanBluetooth().onError((err, st) {
          debugPrintStack(stackTrace: st, label: 'Rescan error: $err');
          _state = _state.copyWith(error: err);
          notifyListeners();
          return Future.error(err!);
        }),
        progress: null,
        error: null);
    notifyListeners();
    return _state.future!;
  }

  Future<ProvisionState> _scanBluetooth() async {
    for (int i = 0; i < 5; i++) {
      List<String> devices =
          await _flutterEspBleProvPlugin.scanBleDevices(_prefix);
      debugPrint("Found devices: ${devices.join(" ")}");
      if (devices.length == 1) {
        _state = _state.copyWith(
            stage: ProvisionStage.scanning_wifi,
            deviceName: devices.first,
            progress: null,
            error: null);
        notifyListeners();
        return scanWifi();
      } else if (devices.isNotEmpty) {
        _state = _state.copyWith(
            bluetoothList: devices,
            stage: ProvisionStage.select_ble,
            progress: null,
            error: null);
        notifyListeners();
        return _state;
      }
    }
    return Future.error(TimeoutException('No devices found after 5 attempts'));
  }

  Future<ProvisionState> scanBluetooth() async {
    _state = _state.copyWith(
        future: _scanBluetooth().onError((err, st) {
          debugPrintStack(stackTrace: st, label: 'Start error: $err');
          _state = _state.copyWith(error: err);
          notifyListeners();
          return Future.error(err!);
        }),
        progress: null,
        error: null);
    notifyListeners();
    return _state.future!;
  }

  Future<ProvisionState> _selectBluetooth(String device) async {
    _state = _state.copyWith(
        stage: ProvisionStage.scanning_wifi, deviceName: device);
    notifyListeners();
    return scanWifi();
  }

  Future<ProvisionState> selectBluetooth(String device) {
    _state = _state.copyWith(
        future: _selectBluetooth(device).onError((err, st) {
          debugPrintStack(stackTrace: st, label: 'Start error: $err');
          _state = _state.copyWith(error: err);
          notifyListeners();
          return Future.error(err!);
        }),
        progress: null,
        error: null);
    notifyListeners();
    return _state.future!;
  }

  Future<ProvisionState> rescanNetworks() {
    _state = _state.copyWith(
        stage: ProvisionStage.scanning_wifi,
        wifiNetworks: null,
        future: scanWifi().onError((err, st) {
          debugPrintStack(stackTrace: st, label: 'Rescan error: $err');
          _state = _state.copyWith(error: err);
          notifyListeners();
          return Future.error(err!);
        }));
    notifyListeners();
    return _state.future!;
  }

  Future<ProvisionState> _setWifiPassword(
      BuildContext context, String ssid, String pw) async {
    // Perform key exchange
    await _exchangeProvisionKey(context);

    var provRes = await _flutterEspBleProvPlugin.provisionWifi(
        _state.deviceName!, _popKey, ssid, pw);
    debugPrint('Provision result: $provRes');
    if (!(provRes ?? false)) {
      throw "Password incorrect.";
    }
    return _state;
  }

  Future<String?> _getSerialNo() async {
    var res = await _flutterEspBleProvPlugin.customEndpoint(_state.deviceName!,
        _popKey, "serial-no", Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF]));
    if (res != null) {
      return hex.encode(res);
    }
  }

  String extractHost(String apiUrl) {
    Uri uri = Uri.parse(apiUrl);
    return uri.host;
  }

  Future<void> _setServerUrl() async {
    var res = await _flutterEspBleProvPlugin.customEndpoint(
        _state.deviceName!,
        _popKey,
        "server-url",
        hex.decode(hex.encode(utf8.encode(extractHost(AppApi.base()))))
            as Uint8List);
    if (res == null) {
      return Future.error("Could not set server url");
    }
  }

  Future<void> _setOobKey(Uint8List key) async {
    var res = await _flutterEspBleProvPlugin.customEndpoint(
        _state.deviceName!, _popKey, "provision-key", key);
    if (res == null) {
      return Future.error("Could not set oob key");
    }
  }

  Future<void> _exchangeProvisionKey(BuildContext context) async {
    if (_state.provisionID != null && _state.serialNo != null) {
      // Perform key exchange
      return;
    }

    if (!(await credentialManager.isLoggedIn())) {
      if (context.mounted) {
        var prov = Provider.of<AuthenticationProvider>(context, listen: false);
        await prov.createAnonymous();
      } else {
        return Future.error("Context gone");
      }
    }

    var sn = await _getSerialNo();

    if (sn == null) {
      return Future.error("Could not get serial number");
    }
    var prov = await client.provisionStart(
        ProvisionStart(serialNo: sn, deviceClass: AppApi.deviceClass()));
    _state = _state.copyWith(provisionID: prov.id, serialNo: sn);
    notifyListeners();
    //await _setServerUrl();
    await _setOobKey(hex.decode(prov.oobKey) as Uint8List);
    return await Future.delayed(const Duration(seconds: 3));
  }

  Future<bool> _checkProvision() async {
    try {
      var p = await client.provisionStatus(_state.provisionID!,
          VerifyProvision(serialNo: _state.serialNo!, ssid: _state.ssid!));
      if (p.provisioned) {
        _state = _state.copyWith(deviceID: p.deviceID);
        return true;
      }
    } on ProblemJsonException catch (ex) {
      debugPrint('Suppressing problem json in provision check: $ex');
    }
    return false;
  }

  Future<ProvisionState> checkProvision() async {
    final int iterations =
        completionTimeout.inSeconds ~/ completionCheckPeriod.inSeconds;

    int errCt = 0;
    for (int i = 0; i < iterations; i++) {
      await Future.delayed(completionCheckPeriod);

      final double percentage = i / iterations;
      final int remainingSeconds = _state.completionETA!.inSeconds;
      final int elapsed = completionCheckPeriod.inSeconds;
      debugPrint("Time remaining: $remainingSeconds / ${elapsed}");

      _state = _state.copyWith(
          progress: percentage,
          completionETA: Duration(seconds: remainingSeconds - elapsed));
      notifyListeners();

      try {
        bool res = await _checkProvision();
        if (res) {
          _state = _state.copyWith(
              progress: 1,
              stage: ProvisionStage.complete,
              completionETA: const Duration(seconds: 0));
          notifyListeners();
          return _state;
        }
      } catch (ex) {
        errCt++;
        debugPrint(ex.toString());
      }
    }

    return Future.error(
        TimeoutException("Device didn't come online after 2 minutes"));
  }

  Future<ProvisionState> finalize(BuildContext context) {
    _state = _state.copyWith(
        stage: ProvisionStage.finalizing,
        error: null,
        completionETA: completionTimeout,
        progress: 0,
        future: checkProvision().then((val) {
          _state = _state.copyWith(error: null, stage: ProvisionStage.complete);
          notifyListeners();
          return val;
        }).onError((err, st) {
          debugPrintStack(stackTrace: st, label: 'Finalize error: $err');
          _state = _state.copyWith(error: err, stage: ProvisionStage.failed);
          notifyListeners();
          return Future.error(err!);
        }));
    notifyListeners();
    return _state.future!;
  }

  Future<ProvisionState> setWifiPassword(
      BuildContext context, String ssid, String pw) {
    _state = _state.copyWith(
        stage: ProvisionStage.provisioning_wifi,
        ssid: ssid,
        wifiPassword: pw,
        error: null,
        future: _setWifiPassword(context, ssid, pw)
            .timeout(const Duration(seconds: 45))
            .onError((err, st) {
          debugPrintStack(
              stackTrace: st, label: 'Set wifi password error: $err');
          _state =
              _state.copyWith(error: err, stage: ProvisionStage.select_wifi);
          notifyListeners();
          return Future.error(err!);
        }));
    notifyListeners();
    return _state.future!;
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    _state.future?.ignore();
  }
}
