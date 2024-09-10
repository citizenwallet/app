package xyz.citizenwallet.wallet

import io.flutter.embedding.android.FlutterActivity
    import io.flutter.embedding.android.FlutterFragmentActivity
    import android.app.PendingIntent
    import android.content.Intent
    import android.nfc.NfcAdapter

class MainActivity: FlutterActivity() {
    override fun onResume() {
        super.onResume()
        val adapter: NfcAdapter? = NfcAdapter.getDefaultAdapter(this)
        val pendingIntent: PendingIntent = PendingIntent.getActivity(
            this, 0, Intent(this, javaClass).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP), PendingIntent.FLAG_IMMUTABLE)
        adapter?.enableForegroundDispatch(this, pendingIntent, null, null)
    }
    override fun onPause() {
        super.onPause()
        val adapter: NfcAdapter? = NfcAdapter.getDefaultAdapter(this)
        adapter?.disableForegroundDispatch(this)
    }
}
