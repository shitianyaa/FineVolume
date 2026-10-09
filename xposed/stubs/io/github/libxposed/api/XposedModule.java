package io.github.libxposed.api;

import java.lang.reflect.Executable;

/**
 * Compile-only stub of the libxposed module base class. In the real framework this extends the
 * interface wrapper and the module object itself becomes the Xposed API once the framework has
 * attached it; here the base class simply is an {@link XposedInterface} whose methods the
 * framework overrides at runtime.
 */
public abstract class XposedModule implements XposedModuleInterface, XposedInterface {

    public XposedModule() {}

    // ---- XposedModuleInterface: overridable callbacks, empty by default ----
    @Override public void onModuleLoaded(ModuleLoadedParam param) {}
    @Override public void onPackageLoaded(PackageLoadedParam param) {}
    @Override public void onPackageReady(PackageReadyParam param) {}
    @Override public void onSystemServerStarting(SystemServerStartingParam param) {}
    @Override public boolean onHotReloading(HotReloadingParam param) { return false; }
    @Override public void onHotReloaded(HotReloadedParam param) {}

    // ---- XposedInterface: the framework supplies the real implementation ----
    @Override public HookBuilder hook(Executable origin) { throw new RuntimeException("stub"); }
    @Override public void log(int priority, String tag, String message) { throw new RuntimeException("stub"); }
    @Override public void log(int priority, String tag, String message, Throwable t) { throw new RuntimeException("stub"); }
}
