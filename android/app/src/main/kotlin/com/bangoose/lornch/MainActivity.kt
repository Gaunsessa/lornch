package com.bangoose.lornch

import android.content.pm.*
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
   private val CHANNEL = "com.bangoose.lornch/android"

   private var PM: PackageManager? = null

   override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
      super.configureFlutterEngine(flutterEngine)

      PM = getActivity().getPackageManager()

      MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
         call, res ->
         when (call.method) {
            "getAppNames" -> {
               val apps = PM!!.getInstalledApplications(PackageManager.GET_META_DATA)

               res.success(apps.filter { (it.flags and ApplicationInfo.FLAG_SYSTEM) == 0 }.map { PM!!.getApplicationLabel(it) })
            }
            "getAppPackages" -> {
               val apps = PM!!.getInstalledApplications(PackageManager.GET_META_DATA)

               res.success(apps.filter { (it.flags and ApplicationInfo.FLAG_SYSTEM) == 0 }.map { it.packageName })
            }
            "launchApp" -> {
               val app = call.arguments as String

               startActivity(PM!!.getLaunchIntentForPackage(app))

               res.success("Succsess")
            }
            "getSavedEdits" -> {
               val sp = getActivity().getPreferences(MODE_PRIVATE)

               res.success(sp.getString("edits", ""))
            }
            "setSavedEdits" -> {
               val sp = getActivity().getPreferences(MODE_PRIVATE);

               with (sp.edit()) {
                  putString("edits", call.arguments as String)

                  apply()
               }

               res.success("")
            }
            else -> res.notImplemented()
         }
      }
   }
}
