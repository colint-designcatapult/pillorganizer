package jct.pillorganizer.app;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;

import androidx.core.app.ActivityCompat;

import io.flutter.plugin.common.MethodChannel;

public class PermissionsUtil {

    public static String[] permissionsNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return new String[]{Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT};
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            return new String[]{Manifest.permission.ACCESS_FINE_LOCATION};
        } else return new String[]{Manifest.permission.ACCESS_COARSE_LOCATION};
    }

    public static void checkOrRequestPermissions(Activity activity, Context context, MethodChannel.Result result) {
        for(String perm : permissionsNeeded()) {
            if(ActivityCompat.checkSelfPermission(context, perm) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(activity, new
                        String[]{perm}, 2);
            }
        }
    }

}
