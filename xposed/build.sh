#!/bin/bash
# Build the FineVolume Xposed module (libxposed API 102).
#
# No Gradle: javac compiles the stubs and the module, dalvik-exchange (or d8) makes the dex,
# aapt packages the resources, apksigner signs. See BUILD.md for the tool list.
set -euo pipefail
cd "$(dirname "$0")"

AJ=${AJ:-/usr/lib/android-sdk/platforms/android-23/android.jar}
AAPT=${AAPT:-aapt}
ZIPALIGN=${ZIPALIGN:-zipalign}
APKSIGNER=${APKSIGNER:-apksigner}

rm -rf out && mkdir -p out/stubs out/classes

# Stubs: compile-only copies of the libxposed API surface. The real classes are supplied by
# LSPosed at runtime; compiling against these keeps the framework off the build classpath.
javac -nowarn -encoding UTF-8 --release 8 -cp "$AJ" -d out/stubs $(find stubs -name '*.java')

# Module code. --release 8 also brings in the JDK API (java.lang.reflect.Executable is API 24,
# which android.jar 23 lacks, but it is only named here, never called at build time).
javac -nowarn -encoding UTF-8 --release 8 -cp "$AJ:out/stubs" -d out/classes $(find io -name '*.java')

# DEX. dalvik-exchange is what the CI toolchain provides (an apt package); d8 from the
# Android build-tools is the fallback for a machine that has those instead.
if command -v dalvik-exchange >/dev/null 2>&1; then
    dalvik-exchange --dex --min-sdk-version=26 --output=out/classes.dex out/classes
    DEX=out/classes.dex
else
    mkdir -p out/dex
    "${D8:-d8}" --min-api 26 --output out/dex $(find out/classes -name '*.class')
    DEX=out/dex/classes.dex
fi

"$AAPT" package -f -M AndroidManifest.xml -S res -I "$AJ" -0 arsc -F out/unsigned.apk
cd out
zip -q -0 unsigned.apk "${DEX#out/}"
mkdir -p META-INF/xposed
cp ../meta/xposed/java_init.list ../meta/xposed/module.prop ../meta/xposed/scope.list META-INF/xposed/
zip -q -X unsigned.apk META-INF/xposed/java_init.list META-INF/xposed/module.prop META-INF/xposed/scope.list
cd ..
"$ZIPALIGN" -f -p 4 out/unsigned.apk out/aligned.apk
[ -f key.jks ] || keytool -genkeypair -keystore key.jks -alias finevolume -keyalg RSA -keysize 2048 \
  -validity 10000 -storepass finevolume -keypass finevolume -dname "CN=FineVolume" >/dev/null 2>&1
"$APKSIGNER" sign --ks key.jks --ks-pass pass:finevolume --ks-key-alias finevolume \
  --min-sdk-version 26 --v4-signing-enabled false --out out/FineVolume.apk out/aligned.apk
"$APKSIGNER" verify -v out/FineVolume.apk | head -5
