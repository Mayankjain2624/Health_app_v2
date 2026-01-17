package com.example.health_app_flutter

import io.flutter.embedding.android.FlutterFragmentActivity
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.content.pm.PackageManager

class MainActivity : FlutterFragmentActivity() {
    private val HEALTH_PERMISSIONS = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
        arrayOf(
            "android.permission.health.READ_STEPS",
            "android.permission.health.READ_ACTIVE_CALORIES_BURNED",
            "android.permission.health.READ_EXERCISE",
            "android.permission.health.READ_HEART_RATE",
            "android.permission.health.READ_DISTANCE"
        )
    } else {
        arrayOf()
    }
    
    private val PERMISSION_REQUEST_CODE = 100
    
    override fun onStart() {
        super.onStart()
        // Request health permissions if not granted
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val notGranted = HEALTH_PERMISSIONS.filter {
                ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
            }.toTypedArray()
            
            if (notGranted.isNotEmpty()) {
                ActivityCompat.requestPermissions(this, notGranted, PERMISSION_REQUEST_CODE)
            }
        }
    }
    
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == PERMISSION_REQUEST_CODE) {
            for (i in permissions.indices) {
                if (grantResults[i] == PackageManager.PERMISSION_GRANTED) {
                    android.util.Log.d("MainActivity", "Permission granted: ${permissions[i]}")
                } else {
                    android.util.Log.d("MainActivity", "Permission denied: ${permissions[i]}")
                }
            }
        }
    }
}
