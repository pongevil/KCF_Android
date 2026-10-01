package io.flutter.plugins;
import android.content.Context;
import android.media.AudioAttributes;
import android.media.SoundPool;
import android.util.SparseIntArray;
import app.bsmobile.businessolution.R;

public class UrovoSoundTool {
    protected static volatile UrovoSoundTool instance;
    private SoundPool soundPool;
    private SparseIntArray soundMap; // To keep track of loaded sound IDs

    public UrovoSoundTool(Context context) {
        AudioAttributes audioAttributes = new AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build();

        soundPool = new SoundPool.Builder()
                .setMaxStreams(1)
                .setAudioAttributes(audioAttributes)
                .build();

        soundMap = new SparseIntArray();
        loadSounds(context);
    }
    public static synchronized UrovoSoundTool getInstance(Context context) {
        if(instance == null) {
            instance = new UrovoSoundTool(context);
        }
        return instance;
    }

    private void loadSounds(Context context) {
        // Load the scan_buzzer.ogg sound and store its ID in soundMap for later reference
        int soundID = soundPool.load(context, R.raw.scan_buzzer, 1);
        soundMap.put(R.raw.scan_buzzer, soundID);
    }

    public void playBeep() {
        // Retrieve the sound ID for scan_buzzer.ogg and play it
        int soundID = soundMap.get(R.raw.scan_buzzer);
        if (soundID != 0) {
            soundPool.play(soundID, 1, 1, 0, 0, 1);
        }
    }

    public void release() {
        if (soundPool != null) {
            soundPool.release();
            soundPool = null;
        }
        instance = null;
    }
}
