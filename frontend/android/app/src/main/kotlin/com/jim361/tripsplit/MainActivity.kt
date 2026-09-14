package com.jim361.tripsplit

import android.app.Activity
import android.content.Intent
import android.content.ClipData
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.net.Uri
import android.provider.MediaStore
import android.os.Build
import android.os.Bundle
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File

class MainActivity : FlutterActivity() {
    private var imageResult: MethodChannel.Result? = null
    private var cameraFile: File? = null
    private val imageRequest = 4162
    private val maxBytes = 5 * 1024 * 1024

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 이전 프로세스 종료로 남은 전용 촬영 cache만 정리합니다.
        File(cacheDir, "receipt_capture").listFiles()?.filter { it.isFile && it.name.startsWith("receipt-") && it.extension == "jpg" }?.forEach { it.delete() }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "trip_split/android_actions")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "shareText" -> {
                            val text = requireNotNull(call.argument<String>("text"))
                            startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).apply {
                                type = "text/plain"
                                putExtra(Intent.EXTRA_TEXT, text)
                            }, "여행 공유"))
                            result.success(null)
                        }
                        "openUrl" -> {
                            val uri = Uri.parse(requireNotNull(call.argument<String>("url")))
                            require(uri.scheme in listOf("http", "https") && !uri.host.isNullOrBlank())
                            startActivity(Intent(Intent.ACTION_VIEW, uri))
                            result.success(null)
                        }
                        "pickReceipt", "captureReceipt" -> {
                            if (imageResult != null) result.error("conflict", "이미지 선택 중입니다.", null)
                            else {
                                imageResult = result
                                if (call.method == "captureReceipt") {
                                    val directory = File(cacheDir, "receipt_capture").apply { mkdirs() }
                                    val file = File.createTempFile("receipt-", ".jpg", directory)
                                    cameraFile = file
                                    val uri = FileProvider.getUriForFile(this, "$packageName.receipt-files", file)
                                    startActivityForResult(Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
                                        putExtra(MediaStore.EXTRA_OUTPUT, uri)
                                        clipData = ClipData.newRawUri("receipt", uri)
                                        addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                    }, imageRequest)
                                } else startActivityForResult(Intent(if (Build.VERSION.SDK_INT >= 33) MediaStore.ACTION_PICK_IMAGES else Intent.ACTION_OPEN_DOCUMENT).apply {
                                    if (Build.VERSION.SDK_INT < 33) addCategory(Intent.CATEGORY_OPENABLE)
                                    type = "image/*"
                                    putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("image/jpeg", "image/png", "image/webp"))
                                }, imageRequest)
                            }
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    if (imageResult === result) imageResult = null
                    clearCapture()
                    result.error("unavailable", "이 기기에서 작업을 열 수 없습니다.", null)
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != imageRequest) return
        val result = imageResult ?: return
        val capture = cameraFile
        val uri = capture?.let { FileProvider.getUriForFile(this, "$packageName.receipt-files", it) } ?: data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            imageResult = null
            clearCapture()
            result.success(null)
            return
        }
        Thread {
            try {
                require(capture != null || contentResolver.getType(uri) in listOf("image/jpeg", "image/png", "image/webp"))
                val original = contentResolver.openInputStream(uri)?.use { stream ->
                    val output = ByteArrayOutputStream()
                    val chunk = ByteArray(8192)
                    while (true) {
                        val count = stream.read(chunk)
                        if (count == -1) break
                        if (output.size() + count > maxBytes) throw IllegalArgumentException("payload-too-large")
                        output.write(chunk, 0, count)
                    }
                    output.toByteArray()
                } ?: throw IllegalArgumentException("invalid-image")
                val bytes = normalizeImage(original)
                runOnUiThread {
                    if (imageResult === result) {
                        imageResult = null
                        clearCapture()
                        result.success(mapOf("bytes" to bytes, "mimeType" to "image/jpeg"))
                    }
                }
            } catch (error: Exception) {
                val code = if (error.message == "payload-too-large") "payload-too-large" else "invalid-image"
                runOnUiThread {
                    if (imageResult === result) {
                        imageResult = null
                        clearCapture()
                        result.error(code, if (code == "payload-too-large") "5 MiB 이하 이미지를 선택해 주세요." else "이미지를 읽지 못했습니다. 다른 파일을 선택해 주세요.", null)
                    }
                }
            }
        }.start()
    }

    // 방향을 적용하고 다시 인코딩하여 EXIF 위치정보를 외부로 보내지 않습니다.
    private fun normalizeImage(bytes: ByteArray): ByteArray {
        val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options)
        require(options.outWidth in 1..20000 && options.outHeight in 1..20000 && options.outWidth.toLong() * options.outHeight <= 40000000)
        var sample = 1
        while (options.outWidth / sample > 2048 || options.outHeight / sample > 2048) sample *= 2
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size, BitmapFactory.Options().apply { inSampleSize = sample })
            ?: throw IllegalArgumentException("invalid-image")
        val orientation = try { ExifInterface(ByteArrayInputStream(bytes)).getAttributeInt(ExifInterface.TAG_ORIENTATION, 1) } catch (_: Exception) { 1 }
        val matrix = Matrix()
        when (orientation) {
            2 -> matrix.setScale(-1f, 1f)
            3 -> matrix.setRotate(180f)
            4 -> matrix.setScale(1f, -1f)
            5 -> { matrix.setRotate(90f); matrix.postScale(-1f, 1f) }
            6 -> matrix.setRotate(90f)
            7 -> { matrix.setRotate(-90f); matrix.postScale(-1f, 1f) }
            8 -> matrix.setRotate(-90f)
        }
        val rotated = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
        return ByteArrayOutputStream().use { output ->
            rotated.compress(Bitmap.CompressFormat.JPEG, 90, output)
            if (rotated !== bitmap) rotated.recycle()
            bitmap.recycle()
            require(output.size() <= maxBytes) { "payload-too-large" }
            output.toByteArray()
        }
    }

    override fun onDestroy() {
        imageResult?.error("unavailable", "이미지 선택이 취소되었습니다.", null)
        imageResult = null
        clearCapture()
        super.onDestroy()
    }

    private fun clearCapture() {
        cameraFile?.let {
            revokeUriPermission(FileProvider.getUriForFile(this, "$packageName.receipt-files", it), Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION)
            it.delete()
        }
        cameraFile = null
    }
}
