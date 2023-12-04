package jct.pillorganizer.pills;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.le.ScanResult;
import android.content.Context;
import android.os.ParcelUuid;
import android.util.Log;

import com.espressif.provisioning.DeviceConnectionEvent;
import com.espressif.provisioning.ESPConstants;
import com.espressif.provisioning.ESPDevice;
import com.espressif.provisioning.ESPProvisionManager;
import com.espressif.provisioning.WiFiAccessPoint;
import com.espressif.provisioning.device_scanner.BleScanner;
import com.espressif.provisioning.listeners.BleScanListener;
import com.espressif.provisioning.listeners.ProvisionListener;
import com.espressif.provisioning.listeners.ResponseListener;
import com.espressif.provisioning.listeners.WiFiScanListener;
import com.espressif.provisioning.utils.HexEncoder;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionException;

import io.flutter.plugin.common.MethodChannel;

public class BleProvisioningChannel {
    public static final String CHANNEL = "jct.pillorganizer.app/bleprovision";
    private static final String TAG = BleProvisioningChannel.class.getSimpleName();


    private static BleProvisioningChannel instance;

    public static BleProvisioningChannel getInstance() {
        return instance;
    }

    public static void startInstance(MethodChannel.Result result) {
        assert instance == null;
        instance = new BleProvisioningChannel();
        instance.start();
        result.success(true);
    }

    public static void stopInstance(MethodChannel.Result result) {
        if(instance != null) {
            instance.stop();
            instance = null;
        }
        result.success(true);
    }

    private BleScanner bleScanner;
    private ESPDevice espDevice;
    private Map<String, BluetoothDevice> scannedDevices = new HashMap<>();
    private CompletableFuture<ESPDevice> connectFuture = null;
    private CompletableFuture<Void> disconnectFuture = null;

    public void start() {
        EventBus.getDefault().register(this);
    }

    public void stop() {
        if(bleScanner != null) {
            if(bleScanner.isScanning())
                bleScanner.stopScan();
            bleScanner = null;
        }

        if(espDevice != null) {
            espDevice.disconnectDevice();;
            espDevice = null;
        }
        scannedDevices.clear();
        EventBus.getDefault().unregister(this);
    }

    public void startScanning(Context context, String prefix, MethodChannel.Result result) {
            scannedDevices.clear();
            bleScanner = new BleScanner(context, new BleScanListener() {
                final Map<String, Map<String, String>> resultMap = new HashMap<>();

                @Override
                public void scanStartFailed() {
                    result.error("code", "failed", "Failed");
                }

                @Override
                public void onPeripheralFound(BluetoothDevice device, ScanResult scanResult) {
                    Map<String, String> values = new HashMap<>();
                    values.put("address", device.getAddress());
                    values.put("name", scanResult.getScanRecord().getDeviceName());
                    values.put("rssi", String.valueOf(scanResult.getRssi()));
                    List<ParcelUuid> uuids = scanResult.getScanRecord().getServiceUuids();
                    if (uuids == null)
                        uuids = new ArrayList<>(0);
                    values.put("serviceUUIDs",
                            Arrays.toString(uuids.toArray()));

                    resultMap.put(device.getAddress(), values);
                    scannedDevices.put(device.getAddress(), device);
                }

                @Override
                public void scanCompleted() {
                    result.success(new ArrayList<>(resultMap.values()));
                }

                @Override
                public void onFailure(Exception e) {
                    result.error(e.getMessage(), e.getMessage(), e.getMessage());
                }
            });
            bleScanner.startScan();
    }

    private CompletableFuture<ESPDevice> connectDeviceInternal(Context context,
                                                               String deviceAddress,
                                                              String service) {
        // Create the connect future
        this.connectFuture = new CompletableFuture<>();

        this.espDevice = ESPProvisionManager
                .getInstance(context)
                .createESPDevice(
                        ESPConstants.TransportType.TRANSPORT_BLE,
                        ESPConstants.SecurityType.SECURITY_1
                );

        BluetoothDevice device = scannedDevices.get(deviceAddress);
        espDevice.connectBLEDevice(device, service);
        return this.connectFuture;
    }

    public void connectDevice(Context context, MethodChannel.Result result, String deviceAddress,
                              String service) {
        connectDeviceInternal(context, deviceAddress, service)
                .thenAccept(d -> {
                    ArrayList<String> caps = d.getDeviceCapabilities();
                    if(caps != null) {
                        if(!caps.contains("no_pop")) {
                            result.success(true);
                        } else if(caps.contains("wifi_scan")) {
                            result.success(false);
                        } else {
                            result.error("no wifi_scan", "no wifi_scan", "no wifi_scan");
                        }
                    } else {
                        result.error("e", "e", "e");
                    }
                })
                .exceptionally(ex -> {
                    result.error(ex.getMessage(), ex.getMessage(), ex.getMessage());
                    return null;
                });
    }

    public void getSerialNumber(MethodChannel.Result result) {
        espDevice.sendDataToCustomEndPoint("serial-no", new byte[4], new ResponseListener() {
            @Override
            public void onSuccess(byte[] returnData) {
                Log.d(TAG, "Serial number: " + HexEncoder.byteArrayToHexString(returnData));
                result.success(returnData);
            }

            @Override
            public void onFailure(Exception e) {
                Log.d(TAG, "Serial number failed", e);
                result.error(e.getMessage(), e.getMessage(), e.getMessage());
            }
        });
    }

    public void setProvisionKey(MethodChannel.Result result, byte[] pkey) {
        Log.d(TAG, "Sending oob key length " + pkey.length);
        espDevice.sendDataToCustomEndPoint("provision-key", pkey, new ResponseListener() {
            @Override
            public void onSuccess(byte[] returnData) {
                result.success(null);
            }

            @Override
            public void onFailure(Exception e) {
                result.error(e.getMessage(), e.getMessage(), e.getMessage());
            }
        });
    }

    public void setPopKey(MethodChannel.Result result, String key) {
        espDevice.setProofOfPossession(key);
        result.success(true);
    }

    private CompletableFuture<Void> connectToWifiInternal(String ssid, String password) {
        CompletableFuture<Void> future = new CompletableFuture<>();
        espDevice.provision(ssid, password, new ProvisionListener() {
            @Override
            public void createSessionFailed(Exception e) {
                future.completeExceptionally(e);
            }

            @Override
            public void wifiConfigSent() {
                Log.d(TAG, "wifiConfigSent");
            }

            @Override
            public void wifiConfigFailed(Exception e) {
                future.completeExceptionally(e);
            }

            @Override
            public void wifiConfigApplied() {
                Log.d(TAG, "wifiConfigApplied");
            }

            @Override
            public void wifiConfigApplyFailed(Exception e) {
                future.completeExceptionally(e);
            }

            @Override
            public void provisioningFailedFromDevice(ESPConstants.ProvisionFailureReason reason) {
                future.completeExceptionally(new ESPProvisioningFailureException(reason));
            }

            @Override
            public void deviceProvisioningSuccess() {
                future.complete(null);
            }

            @Override
            public void onProvisioningFailed(Exception e) {
                future.completeExceptionally(e);
            }
        });
        return future;
    }

    public void connectToWifi(MethodChannel.Result result, String ssid, String password) {
        connectToWifiInternal(ssid, password)
                .thenAccept(c -> {
                    result.success(true);
                })
                .exceptionally(rawEx -> {
                    Throwable ex = rawEx instanceof CompletionException ? rawEx.getCause() : rawEx;
                    if(ex instanceof ESPProvisioningFailureException) {
                        ESPProvisioningFailureException f = (ESPProvisioningFailureException)ex;
                        result.error(
                                f.getReason().name(),
                                ex.getMessage(),
                                ((ESPProvisioningFailureException)ex).getReason().name()
                        );
                    } else {
                        result.error(
                                "PROVISIONING_FAILED",
                                ex.getMessage(),
                                null
                        );
                    }

                   return null;
                });
    }

    public void scanWifiNetworks(MethodChannel.Result result) {
        espDevice.scanNetworks(new WiFiScanListener() {
            @Override
            public void onWifiListReceived(ArrayList<WiFiAccessPoint> wifiList) {
                List<Map<String, String>> res = new ArrayList<>();
                for(WiFiAccessPoint ap : wifiList) {
                    Map<String, String> map = new HashMap<>();
                    map.put("name", ap.getWifiName());
                    map.put("rssi", Integer.toString(ap.getRssi()));
                    map.put("security", Integer.toString(ap.getSecurity()));
                    res.add(map);
                }
                result.success(res);
            }

            @Override
            public void onWiFiScanFailed(Exception e) {
                result.error(e.getMessage(), e.getMessage(), e.getMessage());
            }
        });
    }

    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onMessageEvent(DeviceConnectionEvent event) {
        switch (event.getEventType()) {
            case ESPConstants.EVENT_DEVICE_CONNECTED:
                if(connectFuture != null && !connectFuture.isDone()) {
                    connectFuture.complete(espDevice);
                }
                break;
            case ESPConstants.EVENT_DEVICE_CONNECTION_FAILED:
                if(connectFuture != null && !connectFuture.isDone()) {
                    connectFuture.completeExceptionally(new RuntimeException("failed to connect"));
                }
                break;
            case ESPConstants.EVENT_DEVICE_DISCONNECTED:
                if(disconnectFuture != null && !disconnectFuture.isDone()) {
                    disconnectFuture.complete(null);
                }
                break;
        }
    }

}
