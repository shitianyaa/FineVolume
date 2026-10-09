package io.github.shitianyaa.finevolume;

import java.lang.reflect.Method;
import java.util.List;

import io.github.libxposed.api.XposedInterface;

/**
 * Finer media volume over Bluetooth: turns off AVRCP absolute volume, so the phone attenuates
 * the audio itself instead of asking the headset to do it.
 *
 * <p>Why this is needed. With absolute volume on, the phone sends un-attenuated audio plus a
 * level (0..127) and the headset applies it. That level is rendered by the headset's own
 * amplifier, which has only a handful of steps -- 15 on a typical pair. Raising
 * {@code ro.config.media_vol_steps} gives the phone more steps, but the headset still has 15,
 * so two presses of the volume key move the headset one step: the extra steps are dead.
 *
 * <p>With absolute volume off, the phone scales the samples in software (32-bit float, no fixed
 * step count) and the headset plays at its own fixed level. The volume keys then move one phone
 * step each -- 30 key presses for 30 steps, all audible.
 *
 * <p>How it is switched. {@code AudioService.setDeviceVolumeBehavior()} is the only supported
 * way to change this at runtime, and for an A2DP device it does exactly one thing: calls
 * {@code avrcpSupportsAbsoluteVolume(addr, behavior == ABSOLUTE)}. That call is made by the
 * Bluetooth stack itself every time the headset connects (AvrcpVolumeManager.switchVolumeDevice),
 * so hooking it here also covers reconnects and device switches -- a one-shot command would be
 * overwritten on the next connect.
 *
 * <p>Cost, so it is not a surprise: the phone and the headset each keep their own level, and the
 * loudness heard is the two multiplied. The headset's own volume keys still work (AVRCP
 * passthrough, a different channel), they just move the headset's level and not the phone's.
 * Leaving the headset at a low level and using the phone slider is the way to use it.
 *
 * <p>This module has no settings UI: the rewrite is unconditional, so it is active whenever the
 * module is enabled and in scope (System Framework). To turn it off, disable the module.
 */
final class BtVolume {

    private static final String AUDIO_SERVICE = "com.android.server.audio.AudioService";
    /** AudioDeviceInfo.TYPE_BLUETOOTH_A2DP */
    private static final int TYPE_BLUETOOTH_A2DP = 8;
    /** AudioManager.DEVICE_VOLUME_BEHAVIOR_ABSOLUTE */
    private static final int BEHAVIOR_ABSOLUTE = 3;
    /** AudioManager.DEVICE_VOLUME_BEHAVIOR_VARIABLE -- software attenuation, what we want. */
    private static final int BEHAVIOR_VARIABLE = 0;

    private BtVolume() {}

    static void install(ClassLoader cl) {
        try {
            Class<?> svc = Class.forName(AUDIO_SERVICE, false, cl);
            int hooked = 0;
            for (Method m : svc.getDeclaredMethods()) {
                if (!m.getName().equals("setDeviceVolumeBehavior")) continue;
                Module.hook(m, new XposedInterface.Hooker() {
                    @Override
                    public Object intercept(XposedInterface.Chain chain) throws Throwable {
                        List<Object> args = chain.getArgs();
                        if (args.size() >= 2) {
                            Object device = args.get(0);
                            Object behavior = args.get(1);
                            if (behavior instanceof Integer
                                    && ((Integer) behavior).intValue() == BEHAVIOR_ABSOLUTE
                                    && isA2dp(device)) {
                                // Rewrite the call in place: the original then runs with VARIABLE,
                                // so the Bluetooth stack's own bookkeeping (mDeviceMap, stored
                                // volume) stays correct.
                                Object[] edited = args.toArray();
                                edited[1] = Integer.valueOf(BEHAVIOR_VARIABLE);
                                Module.log("absolute -> variable for " + address(device));
                                return chain.proceed(edited);
                            }
                        }
                        return chain.proceed();
                    }
                });
                hooked++;
            }
            Module.log(hooked > 0
                    ? "hook installed (" + hooked + " overload(s))"
                    : "setDeviceVolumeBehavior not found");
        } catch (Throwable t) {
            Module.log("hook setup failed", t);
        }
    }

    /** The arg is an AudioDeviceAttributes; its type is an SDK constant, not an internal one. */
    private static boolean isA2dp(Object device) {
        if (device == null) return false;
        try {
            Method getType = device.getClass().getMethod("getType");
            Object t = getType.invoke(device);
            return (t instanceof Integer) && ((Integer) t).intValue() == TYPE_BLUETOOTH_A2DP;
        } catch (Throwable t) {
            return false;
        }
    }

    private static String address(Object device) {
        if (device == null) return "?";
        try {
            Method getAddress = device.getClass().getMethod("getAddress");
            Object a = getAddress.invoke(device);
            return a == null ? "?" : a.toString();
        } catch (Throwable t) {
            return "?";
        }
    }
}
