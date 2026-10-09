# FineVolume — KernelSU / Magisk half / 音量档数

**中文见下方 [中文](#中文说明)。**

A tiny KernelSU / Magisk module that gives the media volume slider **more steps**, so the volume
keys change the loudness in finer increments.

Android's stock media volume has 15 steps -- each key press moves about 6.6% of the range, which
is often too coarse. This module raises that number.

```
stock:   15 steps   each key press ~6.6%
this:    30 steps   each key press ~3.3%
```

Only the **media** stream is touched. Ring, notification, alarm, call and system volume keep the
ROM's own values.

> **Bluetooth note.** This works on its own for wired and USB-C output. Over Bluetooth you also
> need the [FineVolume Xposed module](../xposed) -- a headset's own amplifier has only about 15
> steps, so the extra ones would land on nothing.

## 中文说明

一个小巧的 KernelSU / Magisk 模块，把媒体音量档数**调多**，让音量键的变化更细腻。

Android 默认媒体音量只有 15 档 —— 每按一下约跳 6.6%，通常太粗。本模块把它调大。

```
默认：  15 档   每按一下约 6.6%
本模块：30 档   每按一下约 3.3%
```

**只动媒体（media）流**。铃声、通知、闹钟、通话和系统音量保持 ROM 原值。

> **蓝牙注意。** 有线输出和 USB-C 输出下它自己就能生效。**蓝牙耳机还需要配合
> [FineVolume Xposed 模块](../xposed)** —— 耳机自身的功放只有约 15 级，多出来的档位会落空。

## Install / 安装

1. Download `FineVolume.zip`. / 下载 `FineVolume.zip`。
2. Open **KernelSU > Modules > Install from storage**, pick the zip. / 打开 **KernelSU › 模块 › 从存储安装**，选这个 zip。
3. **Reboot.** / **重启。**

The installer prints the ROM's current value and what the module will set. / 安装器会打印 ROM 当前值和本模块将要设置的值。

## Change the number of steps / 改档数

Edit the value in the installed module, then reboot / 编辑已安装模块里的值，然后重启：

```
/data/adb/modules/fine_volume/system.prop

ro.config.media_vol_steps=30     # change 30 to whatever you want
```

Or edit the `system.prop` inside the zip *before* flashing. / 也可以在刷入前改 zip 里的 `system.prop`。

**Recommended:** 30-60. Values above ~100 are mostly placebo. / **建议：** 30–60，超过约 100 基本是心理作用。

## How it works / 原理

`AudioService` reads `ro.config.media_vol_steps` once, at startup, and builds its media volume
table from it. `ro.` properties are locked early in boot, which is why this is a module
(`system.prop` is applied before `AudioService` starts) and not an Xposed hook.

`AudioService` 启动时读取 `ro.config.media_vol_steps` 一次，据此建立媒体音量表。`ro.` 属性在
启动早期即锁定，所以这必须做成模块（`system.prop` 在 `AudioService` 启动前应用），而非 Xposed 钩子。

## Build / 构建

```bash
bash build-module.sh            # ->  out/FineVolume.zip
```

Nothing is compiled: the module is just `module.prop` + `system.prop` + `customize.sh`. / 无需
编译：模块就是 `module.prop` + `system.prop` + `customize.sh` 三个文件。

## License / 协议

[MIT](../LICENSE).
