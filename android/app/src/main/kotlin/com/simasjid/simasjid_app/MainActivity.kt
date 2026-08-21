package com.simasjid.simasjid_app

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth (login biometrik) butuh FlutterFragmentActivity, bukan
// FlutterActivity biasa — dia pakai androidx BiometricPrompt yang perlu
// FragmentActivity untuk menampilkan dialognya.
class MainActivity : FlutterFragmentActivity()
