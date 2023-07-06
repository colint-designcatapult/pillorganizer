package jct.pillorganizer.app;


import android.bluetooth.BluetoothDevice;
import android.bluetooth.le.ScanResult;
import android.os.Bundle;
import android.util.Log;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import com.espressif.provisioning.ESPProvisionManager;
import com.espressif.provisioning.listeners.BleScanListener;
import com.microsoft.appcenter.AppCenter;
import com.microsoft.appcenter.analytics.Analytics;
import com.microsoft.appcenter.crashes.Crashes;

public class MainActivity extends FlutterActivity {

    private static final String TAG = MainActivity.class.getSimpleName();

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        /*AppCenter.start(getApplication(), "661eb334-20a8-46df-9f3a-5d800591650d",
                Analytics.class, Crashes.class);*/
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        MethodChannel methodChannel = new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(), BleProvisioningChannel.CHANNEL);
        methodChannel.setMethodCallHandler((call, result) -> {
            PermissionsUtil.checkOrRequestPermissions(this, getContext(), result);
            switch(call.method) {
                case "startProvisioning":
                    BleProvisioningChannel.startInstance(result);
                    break;
                case "stopProvisioning":
                    BleProvisioningChannel.stopInstance(result);
                    break;
                case "search":
                    BleProvisioningChannel.getInstance().startScanning(getContext(), "", result);
                    break;
                case "connectDevice":
                    BleProvisioningChannel.getInstance().connectDevice(
                            getContext(),
                            result,
                            call.argument("deviceAddress"),
                            call.argument("service")
                    );
                    break;
                case "scanWifiNetworks":
                    BleProvisioningChannel.getInstance().scanWifiNetworks(result);
                    break;
                case "setPopKey":
                    BleProvisioningChannel.getInstance().setPopKey(result, call.argument("key"));
                    break;
                case "getSerialNo":
                    BleProvisioningChannel.getInstance().getSerialNumber(result);
                    break;
                case "setProvisionKey":
                    Log.d(TAG, call.arguments().toString());
                    BleProvisioningChannel.getInstance().setProvisionKey(result, call.argument("key"));
                    break;
                case "connectToWifi":
                    BleProvisioningChannel.getInstance().connectToWifi(result, call.argument("ssid"), call.argument("password"));
                    break;
            }
        });
    }
}
