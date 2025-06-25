// File: android/app/src/main/kotlin/com/spendsight/knom/MainActivity.kt
package com.spendsight.knom

import android.Manifest
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.provider.Telephony
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "sms_reader"
    private val SMS_PERMISSION_CODE = 100

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "readSMS" -> {
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED) {
                        val smsMessages = readSMSMessages()
                        result.success(smsMessages)
                    } else {
                        result.error("PERMISSION_DENIED", "SMS permission not granted", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun readSMSMessages(): List<Map<String, Any>> {
        val smsMessages = mutableListOf<Map<String, Any>>()
        val uri = Uri.parse("content://sms/inbox")
        val projection = arrayOf(
            Telephony.Sms._ID,
            Telephony.Sms.ADDRESS,
            Telephony.Sms.BODY,
            Telephony.Sms.DATE,
            Telephony.Sms.TYPE
        )

        try {
            val cursor: Cursor? = contentResolver.query(
                uri,
                projection,
                null,
                null,
                "${Telephony.Sms.DATE} DESC LIMIT 1000" // Get last 1000 messages
            )

            cursor?.use {
                val idIndex = it.getColumnIndex(Telephony.Sms._ID)
                val addressIndex = it.getColumnIndex(Telephony.Sms.ADDRESS)
                val bodyIndex = it.getColumnIndex(Telephony.Sms.BODY)
                val dateIndex = it.getColumnIndex(Telephony.Sms.DATE)
                val typeIndex = it.getColumnIndex(Telephony.Sms.TYPE)

                while (it.moveToNext()) {
                    val id = if (idIndex >= 0) it.getString(idIndex) else ""
                    val address = if (addressIndex >= 0) it.getString(addressIndex) ?: "" else ""
                    val body = if (bodyIndex >= 0) it.getString(bodyIndex) ?: "" else ""
                    val date = if (dateIndex >= 0) it.getLong(dateIndex) else System.currentTimeMillis()
                    val type = if (typeIndex >= 0) it.getInt(typeIndex) else 1

                    // Only include inbox messages (type 1)
                    if (type == 1) {
                        val smsMap = mapOf(
                            "id" to id,
                            "address" to address,
                            "body" to body,
                            "date" to date,
                            "type" to type
                        )
                        smsMessages.add(smsMap)
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        return smsMessages
    }
}