package ir.kargahyar.kargah_yar

import android.content.ContentValues
import android.content.Context
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class BackupStorePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var appContext: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "ir.kargahyar.kargah_yar/backup")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "saveDb" -> {
                val name = call.argument<String>("name")
                val bytes = call.argument<ByteArray>("bytes")
                if (name.isNullOrBlank() || bytes == null) {
                    result.error("arg", "name/bytes", null)
                    return
                }
                try {
                    result.success(saveToDownloads(name, bytes, "application/octet-stream"))
                } catch (error: Exception) {
                    result.error("save", error.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun saveToDownloads(name: String, bytes: ByteArray, mimeType: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, name)
                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/GearPilot")
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val resolver = appContext.contentResolver
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("insert failed")
            resolver.openOutputStream(uri)?.use { stream -> stream.write(bytes) }
                ?: throw IllegalStateException("stream failed")
            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return "Download/GearPilot/$name"
        }
        val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "GearPilot")
        if (!dir.exists()) {
            dir.mkdirs()
        }
        val file = File(dir, name)
        file.writeBytes(bytes)
        return file.absolutePath
    }
}
