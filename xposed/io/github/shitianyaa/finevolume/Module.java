package io.github.shitianyaa.finevolume;

import java.lang.reflect.Executable;

import io.github.libxposed.api.XposedInterface;
import io.github.libxposed.api.XposedModule;
import io.github.libxposed.api.XposedModuleInterface.ModuleLoadedParam;
import io.github.libxposed.api.XposedModuleInterface.SystemServerStartingParam;

/**
 * FineVolume -- the Xposed half of the FineVolume pair. An LSPosed module (libxposed API 102)
 * that keeps every media-volume step audible on a Bluetooth headset by turning off AVRCP
 * absolute volume. See {@link BtVolume} for the mechanism.
 *
 * <p>Scope: System Framework (system_server). The hook lives in AudioService, so it is installed
 * once from {@code onSystemServerStarting}. Nothing else is hooked. There is no settings UI: the
 * module is active whenever it is enabled and in scope.
 */
public class Module extends XposedModule {

    static final String TAG = "FineVolume";

    private static XposedInterface sX;

    public Module() {
        super();
    }

    @Override
    public void onModuleLoaded(ModuleLoadedParam param) {
        sX = this;   // the module object itself is the Xposed API once the framework attaches it
        log("loaded in " + param.getProcessName());
    }

    @Override
    public void onSystemServerStarting(SystemServerStartingParam param) {
        BtVolume.install(param.getClassLoader());
    }

    /** Intercept one method. The hooker edits the arguments and/or the result as it sees fit. */
    static void hook(Executable exec, XposedInterface.Hooker hooker) {
        XposedInterface x = sX;
        if (x == null || exec == null) return;
        x.hook(exec).intercept(hooker);
    }

    static void log(String msg) {
        XposedInterface x = sX;
        if (x != null) x.log(4 /* INFO */, TAG, msg);
    }

    static void log(String msg, Throwable t) {
        XposedInterface x = sX;
        if (x != null) x.log(6 /* ERROR */, TAG, msg, t);
    }
}
