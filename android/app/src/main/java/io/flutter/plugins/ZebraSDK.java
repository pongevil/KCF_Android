package io.flutter.plugins;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import androidx.annotation.NonNull;
import com.zebra.rfid.api3.*;
import com.zebra.scannercontrol.*;


import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;

public class ZebraSDK implements MethodCallHandler, Readers.RFIDReaderEventHandler {
    private static volatile ZebraSDK instance;
    private Context context;
    private BinaryMessenger messenger;
    private MethodChannel channel;
    private RFIDReader rfidReader;
    private ReaderDevice readerDevice;
    private Readers readers;
    private ArrayList<ReaderDevice> availableRFIDReaderList;
    private boolean isConnected = false;
    private EventHandler eventHandler;
    public static final String TAG = "usdk";
    private int MAX_POWER = 270;
    private ExecutorService executorService = Executors.newSingleThreadExecutor();
    private UrovoSoundTool soundTool;
    private volatile boolean isInventoryRunning = false;
    private volatile boolean isScanEnabled = false;
    private volatile boolean isTriggerPressed = false;

    public static synchronized ZebraSDK getInstance(Context context, BinaryMessenger messenger) {
        if (instance == null) {
            instance = new ZebraSDK();
            instance.context = context.getApplicationContext();
            instance.messenger = messenger;
            instance.channel = new MethodChannel(messenger, "sdk_function_channel");
            instance.readers = new Readers(context, ENUM_TRANSPORT.SERVICE_USB);
         
        }
        return instance;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
       
        switch (call.method) {
            case "connectRFID":
                connectRFID(result);
                soundTool = UrovoSoundTool.getInstance(context);
                break;
            case "startInventory":
                performInventory();
                result.success("Inventory started");
                break;
            case "stopInventory":
                stopInventory();
                result.success("Inventory stopped");
                break;
            case "setScanEnabled":
                Boolean enabled = call.argument("isEnabled");
                isScanEnabled = Boolean.TRUE.equals(enabled);
                if (!isScanEnabled) {
                    isTriggerPressed = false;
                    if (isInventoryRunning) {
                        executorService.execute(this::stopInventoryInternal);
                    }
                }
                result.success(isScanEnabled);
                break;
            case "playSound":
                if (soundTool == null) {
                    soundTool = UrovoSoundTool.getInstance(context);
                }
                soundTool.playBeep();
                result.success("Played");
                break;
  
            default:
                result.notImplemented();
                break;
        }
    }

    private void connectRFID(MethodChannel.Result result) {
        Log.d(TAG, "Connecting to RFID");
        executeConnectionTask(result);
    }

    private void readTags(MethodChannel.Result result) {
       performInventory();
    }

    private void readRFID(MethodChannel.Result result) {
        Log.d(TAG, "Reading RFID");
        // if (isReaderConnected()) {
        //     try {
        //         ArrayList<String> tags = new ArrayList<>();
        //         TagData[] tagData = rfidReader.Actions.getReadTags(100);
        //         if (tagData != null) {
        //             Log.d(TAG, "Read tags: " + tagData.length);
        //             for (TagData tag : tagData) {
        //                 Log.d(TAG, "Tag ID: " + tag.getTagID());
        //                 tags.add(tag.getTagID());
        //             }
        //             result.success(tags);
        //         } else {
        //             Log.d(TAG, "No tags read");
        //             result.success(tags); // Return an empty list if no tags are read
        //         }
        //     } catch (Exception e) {
        //         Log.e(TAG, "Error reading RFID tags: " + e.getMessage());
        //         result.error("ReadError", "Error reading RFID tags: " + e.getMessage(), null);
        //     }
        // } else {
        //     Log.e(TAG, "RFID reader is not connected");
        //     result.error("NotConnected", "RFID reader is not connected", null);
        // }
    }

    private void readTagsRFID(MethodChannel.Result result) {
        Log.d(TAG, "Reading RFID tags");
        // if (isReaderConnected()) {
        //     try {
        //         ArrayList<String> tags = new ArrayList<>();
        //         TagData[] tagData = rfidReader.Actions.getReadTags(100);
        //         if (tagData != null) {
        //             Log.d(TAG, "Read tags: " + tagData.length);
        //             for (TagData tag : tagData) {
        //                 Log.d(TAG, "Tag ID: " + tag.getTagID());
        //                 tags.add(tag.getTagID());
        //             }
        //             result.success(tags);
        //         } else {
        //             Log.d(TAG, "No tags read");
        //             result.success(tags); // Return an empty list if no tags are read
        //         }
        //     } catch (Exception e) {
        //         Log.e(TAG, "Error reading RFID tags: " + e.getMessage());
        //         result.error("ReadError", "Error reading RFID tags: " + e.getMessage(), null);
        //     }
        // } else {
        //     Log.e(TAG, "RFID reader is not connected");
        //     result.error("NotConnected", "RFID reader is not connected", null);
        // }
    }

    private void getAvailableReader() {
        try {
            readers = new Readers(context, ENUM_TRANSPORT.SERVICE_USB);
            availableRFIDReaderList = readers.GetAvailableRFIDReaderList();
            if (availableRFIDReaderList.isEmpty()){
                Log.d(TAG, "No available RFID reader found on USB, trying serial");
                readers.setTransport(ENUM_TRANSPORT.SERVICE_SERIAL);
                availableRFIDReaderList = readers.GetAvailableRFIDReaderList();
            }
            if (availableRFIDReaderList.isEmpty()){
                Log.d(TAG, "No available RFID reader found on serial, trying bluetooth");
                readers.setTransport(ENUM_TRANSPORT.BLUETOOTH);
                availableRFIDReaderList = readers.GetAvailableRFIDReaderList();
            }
            if (availableRFIDReaderList.isEmpty()){
                Log.d(TAG, "No available RFID reader found on bluetooth");
                return;
            }
            rfidReader = availableRFIDReaderList.get(0).getRFIDReader();
        } catch (InvalidUsageException e) {
            throw new RuntimeException(e);
        }
    }

    @Override
    public void RFIDReaderAppeared(ReaderDevice readerDevice) {
        Log.d(TAG, "RFIDReaderAppeared " + readerDevice.getName());
        showMessage("RFIDReaderAppeared");
        getAvailableReader();
    }

    @Override
    public void RFIDReaderDisappeared(ReaderDevice readerDevice) {
        Log.d(TAG, "RFIDReaderDisappeared " + readerDevice.getName());
        showMessage("RFIDReaderDisappeared");
        if (readerDevice.getName().equals(rfidReader.getHostName())) {
            disconnect();
        }
    }

    private void showMessage(String message) {
        // Implement this method to show messages in your context
    }

    private boolean isReaderConnected() {
        return rfidReader != null && rfidReader.isConnected();
    }

    private synchronized void disconnect() {
        Log.d(TAG, "Disconnect");
        try {
            if (rfidReader != null) {
                if (eventHandler != null)
                    rfidReader.Events.removeEventsListener(eventHandler);
                rfidReader.disconnect();
            }
        } catch (InvalidUsageException | OperationFailureException e) {
            e.printStackTrace();
        }
    }

    private synchronized void dispose() {
        disconnect();
        try {
            if (rfidReader != null) {
                rfidReader = null;
                readers.Dispose();
                readers = null;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private boolean performInventoryInternal() {
        if (!isScanEnabled || !isTriggerPressed) {
            Log.d(TAG, "Skipping inventory start: scan is disabled or trigger is no longer pressed");
            return false;
        }

        if (!isReaderConnected()) {
            Log.e(TAG, "Cannot start inventory: reader is not connected");
            isInventoryRunning = false;
            return false;
        }

        if (isInventoryRunning) {
            Log.d(TAG, "Inventory is already running");
            return false;
        }

        try {
            isInventoryRunning = true;
            rfidReader.Actions.Inventory.perform();
            Log.d(TAG, "Inventory started");
            return true;
        } catch (InvalidUsageException | OperationFailureException e) {
            Log.e(TAG, "Error starting inventory: " + e.getMessage());
            isInventoryRunning = false;
            return false;
        }
    }

    public void performInventory() {
        executorService.execute(this::performInventoryInternal);
    }

    private boolean stopInventoryInternal() {
        if (!isReaderConnected()) {
            Log.e(TAG, "Cannot stop inventory: reader is not connected");
            isInventoryRunning = false;
            return false;
        }

        if (!isInventoryRunning) {
            Log.d(TAG, "Inventory is not running");
            return false;
        }

        try {
            rfidReader.Actions.Inventory.stop();
            isInventoryRunning = false;
            Log.d(TAG, "Inventory stopped");
            return true;
        } catch (InvalidUsageException | OperationFailureException e) {
            Log.e(TAG, "Error stopping inventory: " + e.getMessage());
            return false;
        }
    }

    public void stopInventory() {
        executorService.execute(this::stopInventoryInternal);
    }
private void ConfigureReader() {
    Log.d(TAG, "ConfigureReader " + rfidReader.getHostName());
    if (rfidReader.isConnected()) {
        try {
            // Set antenna configuration
            Antennas.AntennaRfConfig config = rfidReader.Config.Antennas.getAntennaRfConfig(1);
            config.setTransmitPowerIndex(270); // Set maximum power
            config.setrfModeTableIndex(0);
            config.setTari(0);
            rfidReader.Config.Antennas.setAntennaRfConfig(1, config);
            // Log.d(TAG, "Antenna configuration set" + config.getMaxTransmitPower());

            // Set Singulation control
            Antennas.SingulationControl s1_singulationControl = 
                rfidReader.Config.Antennas.getSingulationControl(1);
            s1_singulationControl.setSession(SESSION.SESSION_S0);
            s1_singulationControl.Action.setInventoryState(INVENTORY_STATE.INVENTORY_STATE_A);
            s1_singulationControl.Action.setSLFlag(SL_FLAG.SL_ALL);
            rfidReader.Config.Antennas.setSingulationControl(1, s1_singulationControl);

            // Set trigger info
            TriggerInfo triggerInfo = new TriggerInfo();
            triggerInfo.StartTrigger.setTriggerType(START_TRIGGER_TYPE.START_TRIGGER_TYPE_IMMEDIATE);
            triggerInfo.StopTrigger.setTriggerType(STOP_TRIGGER_TYPE.STOP_TRIGGER_TYPE_IMMEDIATE);
            
            // Configure events
            if (eventHandler == null)
                eventHandler = new EventHandler();
            rfidReader.Events.addEventsListener(eventHandler);
            rfidReader.Events.setInventoryStartEvent(true);
            rfidReader.Events.setInventoryStopEvent(true);
            rfidReader.Events.setTagReadEvent(true);
            rfidReader.Events.setAttachTagDataWithReadEvent(false);
            rfidReader.Events.setHandheldEvent(true);

            // Set trigger mode
            rfidReader.Config.setTriggerMode(ENUM_TRIGGER_MODE.RFID_MODE, true);
            rfidReader.Config.setStartTrigger(triggerInfo.StartTrigger);
            rfidReader.Config.setStopTrigger(triggerInfo.StopTrigger);

            // Save configuration
            rfidReader.Config.saveConfig();
            
            Log.d(TAG, "Reader configured successfully");
        } catch (InvalidUsageException | OperationFailureException e) {
            Log.e(TAG, "Error configuring reader: " + e.getMessage());
        }
    } else {
        Log.e(TAG, "Reader is not connected");
    }
}
private void sendDataToFlutter(String epc, String rssi) {
    try {
        Map<String, String> tagData = new HashMap<>();
        tagData.put("epc", epc.trim());
        tagData.put("rssi", rssi);
        // Log.d(TAG, "Sending data to flutter: EPC=" + epc + ", RSSI=" + rssi);

        // Ensure the method is called on the main thread
        new Handler(Looper.getMainLooper()).post(() -> {
            try {
                // Log.d(TAG, "Invoking method on flutter with data: " + tagData);
                channel.invokeMethod("onTagScanned", tagData);
            } catch (Exception e) {
                Log.d(TAG, "Error invoking method on flutter: " + e.getMessage());
                Log.e(TAG, "Error sending data to flutter: " + e.getMessage());
            }
        });
    } catch (Exception e) {
        Log.d(TAG, "Error preparing data to send to flutter: " + e.getMessage());
        Log.e(TAG, "Error preparing data to send to flutter: " + e.getMessage());
    }
}

private void sendTriggerEventToFlutter(String methodName) {
    new Handler(Looper.getMainLooper()).post(() -> {
        try {
            channel.invokeMethod(methodName, null);
        } catch (Exception e) {
            Log.e(TAG, "Error sending trigger event to flutter: " + e.getMessage());
        }
    });
}

public class EventHandler implements RfidEventsListener {

public void eventReadNotify(RfidReadEvents e) {
    if (!isReaderConnected()) {
        return;
    }

    TagData[] myTags = rfidReader.Actions.getReadTags(100);

    if (myTags == null || myTags.length == 0) {
        return;
    }

    if (!isScanEnabled || !isTriggerPressed || !isInventoryRunning) {
        return;
    }

    for (int index = 0; index < myTags.length; index++) {
        sendDataToFlutter(myTags[index].getTagID(), String.valueOf(myTags[index].getPeakRSSI()));
    }
}

    @Override
    public void eventStatusNotify(RfidStatusEvents rfidStatusEvents) {
        if (rfidStatusEvents.StatusEventData == null ||
            rfidStatusEvents.StatusEventData.getStatusEventType() != STATUS_EVENT_TYPE.HANDHELD_TRIGGER_EVENT ||
            rfidStatusEvents.StatusEventData.HandheldTriggerEventData == null) {
            return;
        }

        HANDHELD_TRIGGER_EVENT_TYPE handheldEvent =
            rfidStatusEvents.StatusEventData.HandheldTriggerEventData.getHandheldEvent();

        if (handheldEvent == HANDHELD_TRIGGER_EVENT_TYPE.HANDHELD_TRIGGER_PRESSED) {
            isTriggerPressed = true;

            if (!isScanEnabled) {
                isTriggerPressed = false;
                sendTriggerEventToFlutter("onTriggerBlocked");
                return;
            }

            executorService.execute(() -> {
                if (performInventoryInternal()) {
                    sendTriggerEventToFlutter("onTriggerPressed");
                }
            });
            return;
        }

        if (handheldEvent == HANDHELD_TRIGGER_EVENT_TYPE.HANDHELD_TRIGGER_RELEASED) {
            isTriggerPressed = false;
            stopInventoryInternal();
            sendTriggerEventToFlutter("onTriggerReleased");
        }
    }
}
    public void powerState() {
        for (READER_POWER_STATE powerstate : READER_POWER_STATE.values()) {
            try {
                if (powerstate != READER_POWER_STATE.POWER_STATE_OFF)
                    rfidReader.Config.setReaderPowerState(powerstate);
                powerstate = rfidReader.Config.getReaderPowerState();
                Log.d(TAG, "Current power state " + powerstate);
            } catch (InvalidUsageException | OperationFailureException e) {
                e.printStackTrace();
            }
        }
        try {
            READER_POWER_STATE powerstate = READER_POWER_STATE.POWER_STATE_STANDBY;
            rfidReader.Config.setReaderPowerState(powerstate);
            powerstate = rfidReader.Config.getReaderPowerState();
            Log.d(TAG, "Last power state " + powerstate);
        } catch (InvalidUsageException | OperationFailureException e) {
            e.printStackTrace();
        }
    }
    public void batteryHealth(MethodChannel.Result result) {
        if (rfidReader != null && rfidReader.isConnected()) {
            try {
                int batteryHealth = rfidReader.Config.getBatteryHealth();
                Log.d(TAG, "Battery Health: " + batteryHealth);
                result.success(batteryHealth);
            } catch (InvalidUsageException e) {
                Log.e(TAG, "Invalid usage exception while getting battery health: " + e.getMessage());
                result.error("InvalidUsageException", e.getMessage(), null);
            } catch (OperationFailureException e) {
                Log.e(TAG, "Operation failure exception while getting battery health: " + e.getMessage());
                result.error("OperationFailureException", e.getMessage(), null);
            }
        } else {
            Log.e(TAG, "RFID reader is not connected or is null");
            result.error("NotConnected", "RFID reader is not connected or is null", null);
        }
    }


    public void enableInfoEvent() {
        try {
            rfidReader.Config.getDeviceStatus(false, false, false, true);
        } catch (InvalidUsageException | OperationFailureException e) {
            e.printStackTrace();
        }
    }

    public void doLock() {
        ExecutorService executor = Executors.newSingleThreadExecutor();
        executor.execute(() -> {
            String tagId = "e28011700000020d2a411a23";
            TagAccess tagAccess = new TagAccess();
            TagAccess.LockAccessParams lockAccessParams = tagAccess.new LockAccessParams();
            lockAccessParams.setAccessPassword(11112222);
            LOCK_PRIVILEGE lockPrivilege = LOCK_PRIVILEGE.LOCK_PRIVILEGE_READ_WRITE;
            lockAccessParams.setLockPrivilege(LOCK_DATA_FIELD.LOCK_EPC_MEMORY, lockPrivilege);
            try {
                rfidReader.Actions.TagAccess.lockWait(tagId, lockAccessParams, null, false);
            } catch (InvalidUsageException | OperationFailureException e) {
                showMessage("lock failed ");
                return;
            }
            showMessage("lock success ");
        });
    }

    private void executeConnectionTask(MethodChannel.Result result) {
        Future<String> future = executorService.submit(() -> {
            Log.d(TAG, "ConnectionTask");
            getAvailableReader();
            if (rfidReader != null) {
                try {
                    rfidReader.connect();
                    ConfigureReader();

                    Log.d(TAG, "Connected to reader: " + rfidReader.getHostName());
                    return "Connected";
                } catch (InvalidUsageException | OperationFailureException e) {
                    Log.d(TAG, "Connection failed: " + e.getMessage());
                    return "Connection failed: " + e.getMessage();
                }
            }
            return "Failed to find or connect reader";
        });

        executorService.submit(() -> {
            try {
                String connectionResult = future.get();
                showMessage(connectionResult);
                result.success(connectionResult);
            } catch (Exception e) {
                Log.d(TAG, "Error executing connection task: " + e.getMessage());
                result.error("ConnectionError", "Error executing connection task: " + e.getMessage(), null);
            }
        });
    }
}