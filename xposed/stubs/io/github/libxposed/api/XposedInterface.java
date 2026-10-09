package io.github.libxposed.api;

import java.lang.reflect.Executable;
import java.util.List;

/**
 * Compile-only stub of the libxposed API (api 102). The real classes are supplied by LSPosed at
 * runtime; this exists only so the module compiles without the framework on the classpath. It
 * declares the public surface this module uses -- the method signatures are the framework's
 * public API.
 */
public interface XposedInterface {

    int API_101 = 101;
    int API_102 = 102;
    int LIB_API = 102;

    int PRIORITY_DEFAULT = 50;

    HookBuilder hook(Executable origin);

    void log(int priority, String tag, String message);
    void log(int priority, String tag, String message, Throwable throwable);

    interface Hooker {
        Object intercept(Chain chain) throws Throwable;
    }

    interface Chain {
        Executable getExecutable();
        Object getThisObject();
        List<Object> getArgs();
        Object getArg(int index);
        Object proceed() throws Throwable;
        Object proceed(Object[] args) throws Throwable;
        Object proceedWith(Object thisObject) throws Throwable;
        Object proceedWith(Object thisObject, Object[] args) throws Throwable;
    }

    interface HookBuilder {
        HookBuilder setId(String id);
        HookBuilder setPriority(int priority);
        HookBuilder setExceptionMode(ExceptionMode mode);
        HookHandle intercept(Hooker hooker);
    }

    interface HookHandle {
        Executable getExecutable();
        String getId();
        void unhook();
        HookHandle replaceHook(Hooker hooker);
    }

    enum ExceptionMode { SWALLOW, THROW }
}
