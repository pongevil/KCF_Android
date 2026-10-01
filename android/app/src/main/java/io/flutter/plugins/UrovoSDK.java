package io.flutter.plugins;

import java.io.File;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.media.MediaPlayer;
import android.util.Log;
import android.view.KeyEvent;

//Package for RFID

import com.ubx.usdk.rfid.RfidManager;
import com.ubx.usdk.RFIDSDKManager;
import com.ubx.usdk.util.QueryMode;
import com.ubx.usdk.rfid.aidl.IRfidCallback;
import android.net.ConnectivityManager;
import com.ubx.usdk.USDKManager;
import com.ubx.usdk.listener.InitListener;

import android.os.Handler;
import android.os.Looper;
import android.os.Build;
import com.ubx.usdk.rfid.RfidManager;
import android.device.ScanManager;
import io.flutter.embedding.engine.FlutterEngine;
import java.util.concurrent.CompletableFuture;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import java.nio.charset.StandardCharsets;
//Sound
import io.flutter.plugins.UrovoSoundTool;

public class UrovoSDK implements MethodCallHandler {
    protected static volatile UrovoSDK instance;
    private static final int DEFAULT_POWER = 33;
    private static final int INIT_RETRY_COUNT = 6;
    private static final long INIT_RETRY_DELAY_MS = 300L;
    private MethodChannel channel;
    private RfidManager mRfidManager;
    private RfidManager mRfidManager1;
    private ScanManager mScanManager;
    public static final String TAG = "usdk";
    public static final String DECODE_DATA_TAG = "com.example.app.DECODE_DATA";
    private ScanCallback callback;
    private RfidManager callbackRegisteredManager;
    private Context context;
    private BinaryMessenger messenger;
    private CompletableFuture<Boolean> initInFlight;

    private UrovoSoundTool soundTool;

    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    // useContext binding.getApplicationContext()
    public static synchronized UrovoSDK getInstance(Context context, BinaryMessenger messenger) {
        if (instance == null) {
            instance = new UrovoSDK();
            Log.d(TAG, "UrovoSDK instance created. Waiting for explicit RFID init.");
        }
        instance.rebind(context, messenger);
        return instance;
    }

    private synchronized void rebind(Context context, BinaryMessenger messenger) {
        Context appContext = context == null ? null : context.getApplicationContext();
        boolean messengerChanged = this.messenger != messenger;

        this.context = appContext;
        this.messenger = messenger;

        if (channel == null || messengerChanged) {
            channel = messenger == null ? null : new MethodChannel(messenger, "sdk_function_channel");
        }
    }

    private boolean isScannerReady() {
        return mRfidManager != null && mScanManager != null && callback != null;
    }

    synchronized void detachFromEngine() {
        releaseResources();
        channel = null;
        messenger = null;
        context = null;
        if (instance == this) {
            instance = null;
        }
    }

    private synchronized CompletableFuture<Boolean> initRfid(Context context) {
        if (context == null) {
            Log.w(TAG, "initRfid() skipped because plugin context is not bound.");
            return CompletableFuture.completedFuture(false);
        }

        if (isScannerReady()) {
            return CompletableFuture.completedFuture(true);
        }

        if (initInFlight != null && !initInFlight.isDone()) {
            Log.d(TAG, "initRfid() already in progress. Reusing existing future.");
            return initInFlight;
        }

        CompletableFuture<Boolean> future = new CompletableFuture<>();
        initInFlight = future;
        future.whenComplete((ignored, error) -> {
            synchronized (UrovoSDK.this) {
                if (initInFlight == future) {
                    initInFlight = null;
                }
            }
        });
        try {
            RFIDSDKManager.getInstance().init(new InitListener() {
                @Override
                public void onStatus(boolean status) {
                    try {
                        if (!status) {
                            Log.w(TAG, "initRfid() reported false from SDK.");
                            future.complete(false);
                            return;
                        }

                        Log.d(TAG, "initRfid() reported success. Waiting for RFID manager warm-up.");
                        finishInitWhenReady(context, future, INIT_RETRY_COUNT);
                    } catch (Throwable callbackError) {
                        Log.e(TAG, "Error while handling RFID init callback", callbackError);
                        future.complete(false);
                    }
                }
            });
        } catch (Throwable e) {
            Log.e(TAG, "Error in initRfid", e);
            future.complete(false);
        }
        return future;
    }

    private void finishInitWhenReady(Context context, CompletableFuture<Boolean> future, int attemptsRemaining) {
        if (future.isDone()) {
            return;
        }

        try {
            if (tryPrepareManagers(context)) {
                future.complete(true);
                return;
            }
        } catch (Throwable e) {
            Log.w(TAG, "RFID warm-up attempt failed", e);
        }

        if (attemptsRemaining <= 0) {
            Log.e(TAG, "RFID manager never became ready after init.");
            future.complete(false);
            return;
        }

        mainHandler.postDelayed(
                () -> finishInitWhenReady(context, future, attemptsRemaining - 1),
                INIT_RETRY_DELAY_MS);
    }

    private boolean tryPrepareManagers(Context context) {
        if (mScanManager == null) {
            try {
                mScanManager = new ScanManager();
            } catch (Throwable scanError) {
                Log.w(TAG, "ScanManager is not ready yet", scanError);
            }
        }

        if (mScanManager == null) {
            Log.w(TAG, "ScanManager is still null during warm-up");
            return false;
        }

        RfidManager nextManager = RFIDSDKManager.getInstance().getRfidManager();
        if (nextManager == null) {
            Log.w(TAG, "getRfidManager() returned null during warm-up");
            return false;
        }

        mRfidManager = nextManager;

        if (callback == null) {
            callback = new ScanCallback();
        }

        registerCallbackIfNeeded();
        mRfidManager.setQueryMode(QueryMode.EPC_TID);
        if (soundTool == null) {
            soundTool = UrovoSoundTool.getInstance(context);
        }

        return true;
    }

    private void registerCallbackIfNeeded() {
        if (callback == null || mRfidManager == null || callbackRegisteredManager == mRfidManager) {
            return;
        }

        if (callbackRegisteredManager != null) {
            try {
                callbackRegisteredManager.unregisterCallback(callback);
            } catch (Throwable unregisterError) {
                Log.w(TAG, "Unable to unregister callback from previous RFID manager", unregisterError);
            }
        }

        mRfidManager.registerCallback(callback);
        callbackRegisteredManager = mRfidManager;
    }

    private void unregisterCallbackQuietly() {
        if (callback == null || callbackRegisteredManager == null) {
            callbackRegisteredManager = null;
            return;
        }

        try {
            callbackRegisteredManager.unregisterCallback(callback);
        } catch (Throwable unregisterError) {
            Log.w(TAG, "Unable to unregister RFID callback", unregisterError);
        } finally {
            callbackRegisteredManager = null;
        }
    }

    private synchronized void releaseResources() {
        mainHandler.removeCallbacksAndMessages(null);

        if (mRfidManager != null) {
            try {
                mRfidManager.stopInventory();
            } catch (Throwable stopError) {
                Log.w(TAG, "Unable to stop inventory during release", stopError);
            }

            try {
                mRfidManager.release();
            } catch (Throwable releaseError) {
                Log.w(TAG, "Unable to release RFID manager", releaseError);
            }
        }

        unregisterCallbackQuietly();

        if (mScanManager != null) {
            try {
                mScanManager.closeScanner();
            } catch (Throwable closeError) {
                Log.w(TAG, "Unable to close scanner during release", closeError);
            }
        }

        if (soundTool != null) {
            try {
                soundTool.release();
            } catch (Throwable soundError) {
                Log.w(TAG, "Unable to release sound tool", soundError);
            }
        }

        mScanManager = null;
        mRfidManager = null;
        callback = null;
        soundTool = null;
        initInFlight = null;
    }

    private void setPowerWithRecovery(int power, MethodChannel.Result result) {
        try {
            if (mRfidManager != null) {
                int setPowerStatus = mRfidManager.setOutputPower(power);
                if (setPowerStatus == 0) {
                    result.success("Power set to " + power);
                    return;
                }
                Log.w(TAG, "setOutputPower failed with code " + setPowerStatus + ". Reinitializing RFID.");
            } else {
                Log.w(TAG, "setOutputPower requested before RFID manager was ready. Reinitializing RFID.");
            }

            initRfid(context).whenComplete((success, error) -> {
                mainHandler.post(() -> {
                    if (error != null) {
                        Log.e(TAG, "Exception while retrying set power", error);
                        result.error("TRY_ERROR", "Exception setting power after retry: " + error.getMessage(), null);
                        return;
                    }

                    if (!Boolean.TRUE.equals(success) || mRfidManager == null) {
                        result.error("TRY_ERROR", "Error setting power after retry", null);
                        return;
                    }

                    try {
                        int retryStatus = mRfidManager.setOutputPower(power);
                        if (retryStatus == 0) {
                            result.success("Power set to " + power);
                        } else {
                            result.error("TRY_ERROR", "Error setting power after retry", retryStatus);
                        }
                    } catch (Throwable retryError) {
                        Log.e(TAG, "Exception while applying power after retry", retryError);
                        result.error("TRY_ERROR", "Exception setting power after retry: " + retryError.getMessage(),
                                null);
                    }
                });
            });
        } catch (Throwable e) {
            Log.e(TAG, "Exception setting power", e);
            result.error("EXCEPTION", "Exception setting power: " + e.getMessage(), null);
        }
    }

    class ScanCallback implements IRfidCallback {
        @Override
        public void onInventoryTag(String EPC, final String Data, final String strRSSI) {

            new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    Log.d(TAG, "onInventoryTag() EPC: " + EPC + ", TID: " + Data + ", RSSI: " + strRSSI);
                    sendEPCToFlutter(EPC, strRSSI, Data);

                }
            });
        }

        /**
         * 盘存结束回调(Inventory Command Operate End)
         */
        @Override
        public void onInventoryTagEnd() {
            Log.d(TAG, "onInventoryTagEnd()");

        }
    }

    private void sendEPCToFlutter(String epc, String rssi, String tid) {
        if (channel == null) {
            Log.w(TAG, "Dropping scanned tag because Flutter channel is not attached.");
            return;
        }

        Map<String, String> tagData = new HashMap<>();
        tagData.put("epc", epc.trim());
        tagData.put("tid", tid); // TID is not provided in the current callback, set as empty string
        tagData.put("rssi", rssi);
        channel.invokeMethod("urovoonTagScanned", tagData);
        // soundTool.playBeep();
    }

    private String hexToAscii(String hex) {
        if (hex == null || hex.isEmpty())
            return "";
        if ((hex.length() & 1) != 0) {
            throw new IllegalArgumentException("Hex length must be even");
        }

        byte[] bytes = new byte[hex.length() / 2];
        for (int i = 0; i < hex.length(); i += 2) {
            int hi = Character.digit(hex.charAt(i), 16);
            int lo = Character.digit(hex.charAt(i + 1), 16);
            if (hi < 0 || lo < 0) {
                throw new IllegalArgumentException("Invalid hex at index " + i);
            }
            bytes[i / 2] = (byte) ((hi << 4) + lo);
        }

        return new String(bytes, StandardCharsets.US_ASCII);
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {

        switch (call.method) {
            case "urovogetServiceVersion":

                result.success("asdasd");
                break;
            case "urovostartInventory":
                if (mRfidManager == null) {
                    result.error("RFID_NOT_READY", "RFID is not initialized. Call urovoinitScanner first", null);
                    break;
                }
                result.success(mRfidManager.startInventory(0));
                break;
            case "urovostopInventory":
                if (mRfidManager == null) {
                    result.error("RFID_NOT_READY", "RFID is not initialized. Call urovoinitScanner first", null);
                    break;
                }
                result.success(mRfidManager.stopInventory());
                break;
            case "urovoScanned":
                RFIDSDKManager.getInstance()
                        .enableScanHead(Boolean.parseBoolean(call.argument("statusTrg").toString()));
                result.success("Scanned" + call.argument("statusTrg"));
                break;
            case "urovoGetPower":
                if (mRfidManager == null) {
                    result.error("RFID_NOT_READY", "RFID is not initialized. Call urovoinitScanner first", null);
                    break;
                }
                result.success(mRfidManager.getOutputPower());
                break;
            case "urovoSetPower":
                try {
                    int power = Integer.parseInt(call.argument("power").toString());
                    Log.d(TAG, "Setting RFID power to " + power);
                    setPowerWithRecovery(power, result);
                } catch (Exception e) {
                    Log.e(TAG, "Exception setting power", e);
                    result.error("EXCEPTION", "Exception setting power: " + e.getMessage(), null);
                }
                break;

            case "urovoOpenScanner":
                if (mScanManager == null) {
                    result.error("SCANNER_NOT_READY", "Scanner is not initialized. Call urovoinitScanner first", null);
                    break;
                }
                mScanManager.openScanner();
                // soundTool.playBeep();
                result.success("Scanner opened");
                break;
            case "urovoCloseScanner":
                if (mScanManager == null) {
                    result.error("SCANNER_NOT_READY", "Scanner is not initialized. Call urovoinitScanner first", null);
                    break;
                }
                mScanManager.closeScanner();
                // soundTool.playBeep();
                result.success("Scanner closed");
                break;
            case "CheckScanner":
                try {
                    if (mScanManager == null) {
                        result.error("SCANNER_NOT_READY", "Scanner is not initialized. Call urovoinitScanner first",
                                null);
                        break;
                    }
                    result.success(mScanManager.getScannerState());
                } catch (Exception e) {
                    Log.e(TAG, "Error in CheckScanner", e);
                    result.success(e);
                }
                break;
            case "getTriggerLockState":
                try {
                    if (mScanManager == null) {
                        result.error("SCANNER_NOT_READY", "Scanner is not initialized. Call urovoinitScanner first",
                                null);
                        break;
                    }
                    result.success(mScanManager.getTriggerLockState());
                } catch (Exception e) {
                    Log.e(TAG, "Error in CheckScanner", e);
                    result.success(e);
                }
                break;
            case "urovoinitScanner":
                try {
                    initRfid(context).thenAccept(success -> {
                        mainHandler.post(() -> {
                            try {
                                if (success && isScannerReady()) {
                                    result.success("Scanner initialized");
                                } else {
                                    result.error("RFID_INIT_FAILED", "RFID initialization failed on this device", null);
                                }
                            } catch (Throwable deliveryError) {
                                Log.e(TAG, "Error delivering RFID init result to Flutter", deliveryError);
                            }
                        });
                    });
                } catch (Throwable e) {
                    Log.e(TAG, "Error in initScanner", e);
                    result.error("RFID_INIT_ERROR", "Error in initScanner: " + e.getMessage(), null);
                }
                break;
            case "urovoRelease":
                releaseResources();
                result.success("Released");
                break;
            case "playBeep":
                if (soundTool != null) {
                    soundTool.playBeep();
                    result.success("Beep played");
                } else {
                    result.error("SOUND_TOOL_NOT_READY", "Sound tool is not initialized.", null);
                }
                break;

            default:
                result.notImplemented();
                break;
        }
    }

}
