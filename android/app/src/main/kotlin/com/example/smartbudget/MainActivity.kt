package com.example.smartbudget

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Prevent the app from appearing in the Recent Apps thumbnail and block
        // third-party screenshot tools from capturing financial data.
        // FLAG_SECURE applies to the entire Activity window for the app's lifetime.
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
    }
}
