package io.flutter.plugins;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;

import io.flutter.plugins.UrovoSDK;

public class MainlauncherSDK implements FlutterPlugin, MethodCallHandler {
    private static final String CHANNEL_NAME = "sdk_function_channel";
    private static final String METHOD_SET_DEVICE_TYPE = "setDeviceType";
    private static final String DEVICE_UROVO = "Urovo";
    private static final String DEVICE_CIPHERLAB = "CipherLab";
    private static final String DEVICE_ZEBRA = "Zebra";

    private MethodChannel channel;
    private UrovoSDK urovoTool;
    private CipherlabSDK cipherlabTool;
    private ZebraSDK zebraTool;
    private String deviceType = null;
    FlutterPluginBinding bindingObj;

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        bindingObj = binding;
        channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
        channel.setMethodCallHandler(this);

    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        clearInstances();
        deviceType = null;
        bindingObj = null;
        if (channel != null) {
            channel.setMethodCallHandler(null);
            channel = null;
        }
    }

    private void clearInstances() {
        if (urovoTool != null) {
            urovoTool.detachFromEngine();
        }
        urovoTool = null;
        cipherlabTool = null;
        zebraTool = null;
    }

    private String normalizeDeviceType(String requestedDeviceType) {
        return requestedDeviceType == null ? null : requestedDeviceType.trim();
    }

    private MethodCallHandler getCurrentHandler() {
        if (DEVICE_UROVO.equals(deviceType)) {
            return urovoTool;
        }
        if (DEVICE_CIPHERLAB.equals(deviceType)) {
            return cipherlabTool;
        }
        if (DEVICE_ZEBRA.equals(deviceType)) {
            return zebraTool;
        }
        return null;
    }

    private String initializeDeviceTool(String requestedDeviceType) {
        if (bindingObj == null) {
            return null;
        }

        clearInstances();
        switch (requestedDeviceType) {
            case DEVICE_UROVO:
                urovoTool = UrovoSDK.getInstance(bindingObj.getApplicationContext(), bindingObj.getBinaryMessenger());
                return "Connected RFID Urovo";
            case DEVICE_CIPHERLAB:
                cipherlabTool = CipherlabSDK.getInstance(bindingObj.getApplicationContext(),
                        bindingObj.getBinaryMessenger());
                return "Connected RFID Cipherlab";
            case DEVICE_ZEBRA:
                zebraTool = ZebraSDK.getInstance(bindingObj.getApplicationContext(), bindingObj.getBinaryMessenger());
                return "Connected RFID Zebra";
            default:
                return null;
        }
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        if (METHOD_SET_DEVICE_TYPE.equals(call.method)) {
            String requestedDeviceType = normalizeDeviceType(call.argument(METHOD_SET_DEVICE_TYPE));
            if (requestedDeviceType == null || requestedDeviceType.isEmpty()) {
                result.error("DEVICE_TYPE_ERROR", "Device type not found", null);
                return;
            }

            String initializeMessage = initializeDeviceTool(requestedDeviceType);
            if (initializeMessage == null) {
                result.error("DEVICE_TYPE_ERROR", "Device type not found", null);
                return;
            }

            deviceType = requestedDeviceType;
            result.success(initializeMessage);
            return;
        }

        if (deviceType == null) {
            result.error("DEVICE_NOT_SET", "Please call setDeviceType first", null);
            return;
        }

        MethodCallHandler currentHandler = getCurrentHandler();
        if (currentHandler != null) {
            currentHandler.onMethodCall(call, result);
            return;
        }

        result.error("DEVICE_NOT_READY", "Selected device SDK is not initialized", null);
    }
}
