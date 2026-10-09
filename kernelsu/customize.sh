#!/system/bin/sh
#
# customize.sh - runs at install time (KernelSU / Magisk).
#
# system.prop is the single source of truth for the step count. This script only
# validates it and clamps it into a sane range, so a typo cannot leave the audio
# service with a broken volume table.
#
# KernelSU / Magisk apply system.prop to the property area before AudioService
# starts, so the value is live on the next reboot.

SKIPUNZIP=0

STEPS_MIN=15
STEPS_MAX=200
STEPS_FALLBACK=30

MODID=fine_volume
PROP="$MODPATH/system.prop"
CURRENT=$(grep '^ro\.config\.media_vol_steps=' "$PROP" 2>/dev/null | head -n 1 | cut -d= -f2 | tr -d ' \r')

# Read the ROM's own value from the prop *files*, not from getprop.
#
# getprop returns whatever is live in memory, which by now may be a value this or
# another module already overrode -- on a reinstall that would show the old module
# value and call it the ROM's. The build.prop files are read-only and no module
# can touch them, so they always hold the stock number. (KernelSU applies
# system.prop to the in-memory property area, never to these files.)
ROM_STEPS=""
for f in /vendor/build.prop /odm/etc/build.prop /system/build.prop \
         /product/build.prop /system_ext/build.prop /system/etc/prop.default; do
    ROM_STEPS=$(grep -h '^ro\.config\.media_vol_steps=' "$f" 2>/dev/null \
                | head -n 1 | cut -d= -f2 | tr -d ' \r')
    [ -n "$ROM_STEPS" ] && break
done

# "each press moves 1/STEPS of the range", as a percentage with one decimal.
# Computed, not hardcoded: 15 -> 6.6%, 30 -> 3.3%, 45 -> 2.2%. Integer shell
# arithmetic only, so scale by 10 first and split the digit back off.
pct() {
    case "$1" in
        ''|*[!0-9]*) echo "?"; return ;;
    esac
    [ "$1" -lt 1 ] && { echo "?"; return; }
    local t=$((1000 / $1))
    echo "$((t / 10)).$((t % 10))"
}

# --- validate, silently; collect a warning for each language -----------------
WARN_ZH=""
WARN_EN=""
case "$CURRENT" in
    ''|*[!0-9]*)
        WARN_ZH="! system.prop 值不可用，改用 $STEPS_FALLBACK"
        WARN_EN="! bad value in system.prop; using $STEPS_FALLBACK"
        STEPS=$STEPS_FALLBACK
        ;;
    *)
        STEPS=$CURRENT
        ;;
esac

if [ "$STEPS" -lt "$STEPS_MIN" ]; then
    WARN_ZH="! $STEPS 低于下限，提到 $STEPS_MIN"
    WARN_EN="! $STEPS too low; raising to $STEPS_MIN"
    STEPS=$STEPS_MIN
elif [ "$STEPS" -gt "$STEPS_MAX" ]; then
    WARN_ZH="! $STEPS 高于上限，降到 $STEPS_MAX"
    WARN_EN="! $STEPS too high; lowering to $STEPS_MAX"
    STEPS=$STEPS_MAX
fi

# --- write back (only the one line; keep the comments) -------------------
if [ "$STEPS" != "$CURRENT" ]; then
    sed -i "s/^ro\.config\.media_vol_steps=.*/ro.config.media_vol_steps=$STEPS/" "$PROP"
fi

# --- output: one language per block, never mixed -------------------------
# Keep lines short: the KernelSU terminal is narrow, and a wrapped line reads as
# broken layout. Chinese glyphs are double width, so the Chinese lines are shorter.

ui_print "FineVolume"
ui_print "------------------------------------"
ui_print " "
ui_print "中文"
[ -n "$WARN_ZH" ] && ui_print "  $WARN_ZH"
[ -n "$ROM_STEPS" ] && ui_print "  本机原值:   $ROM_STEPS 档 (每按 ~$(pct "$ROM_STEPS")%)"
ui_print "  本模块设为: $STEPS 档 (每按 ~$(pct "$STEPS")%)"
[ -n "$ROM_STEPS" ] && ui_print "  音量档数:   $ROM_STEPS -> $STEPS"
ui_print "  重启后生效。"
ui_print " "
ui_print "  蓝牙耳机功放只有约 15 级，多出的档位在"
ui_print "  蓝牙下落空（按两下才动一级）。装上"
ui_print "  FineVolume Xposed 模块即生效，无开关:"
ui_print "  github.com/shitianyaa/FineVolume"
ui_print " "
ui_print "  改数值: /data/adb/modules/$MODID/"
ui_print "          system.prop"
ui_print "  改数字，然后重启。"
ui_print " "
ui_print "English"
[ -n "$WARN_EN" ] && ui_print "  $WARN_EN"
[ -n "$ROM_STEPS" ] && ui_print "  ROM:         $ROM_STEPS steps (press ~$(pct "$ROM_STEPS")%)"
ui_print "  This module: $STEPS steps (press ~$(pct "$STEPS")%)"
[ -n "$ROM_STEPS" ] && ui_print "  Media steps: $ROM_STEPS -> $STEPS"
ui_print "  Reboot to apply."
ui_print " "
ui_print "  A headset has ~15 steps of its own, so the"
ui_print "  extra ones land on nothing (two presses,"
ui_print "  one step). Install the FineVolume Xposed"
ui_print "  module -- no switch, installing it is the"
ui_print "  switch:"
ui_print "  github.com/shitianyaa/FineVolume"
ui_print " "
ui_print "  To change: /data/adb/modules/$MODID/"
ui_print "             system.prop"
ui_print "  Edit the number, reboot."
