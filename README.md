# FineVolume / 音量细调

Finer media volume on Android: **more steps**, and on Bluetooth **every step audible**.

**中文说明见下方 [中文](#中文说明)。**

This repository ships **two independent modules** that together fix one problem. Neither is
useful on Bluetooth without the other.

| | Deliverable | Type | What it does |
|---|---|---|---|
| 1 | [`kernelsu/`](kernelsu) | KernelSU / Magisk module | Media volume 15 → 30 steps (a property, set before `AudioService` starts) |
| 2 | [`xposed/`](xposed) | LSPosed module | Turns off Bluetooth AVRCP absolute volume, so the extra steps stay audible over Bluetooth |

```
stock:             15 steps   each key press ~6.6%   Bluetooth: headset does the attenuation
FineVolume (both): 30 steps   each key press ~3.3%   Bluetooth: phone does it, every step works
```

## Why two modules, and why these two mechanisms

The two halves live in different places, and each can only be done one way:

- **The step count** is a system property (`ro.config.media_vol_steps`) that `AudioService`
  reads **once, at startup, before any Xposed module can run**. Only a KernelSU / Magisk module
  can set it in time (`system.prop` is applied before `AudioService` starts). An Xposed module
  is too late.
- **Bluetooth absolute volume** cannot be a property any more. Android used to expose it as the
  developer option *Disable absolute volume* (`persist.bluetooth.disableabsvol`), but **Android
  17 QPR1 removed that option and the property is no longer honoured** (Google issue
  [536132206](https://issuetracker.google.com/issues/536132206), marked intended behaviour).
  The only thing left is to intercept `AudioService.setDeviceVolumeBehavior()` inside
  `system_server`, which needs code injection -- an Xposed hook.

So: property half → KernelSU module; code-injection half → Xposed module. Both are independent;
install either one, or both.

## Install

1. Flash [`kernelsu/out/FineVolume.zip`](kernelsu) in KernelSU and **reboot**.
2. Install [`xposed/out/FineVolume.apk`](xposed) in LSPosed, enable it for **System Framework**,
   and **reboot**. There is no settings screen -- installing and enabling the module *is* the
   switch; turn it off in LSPosed to disable.

Wired and USB-C output only need step 1. Bluetooth needs both.

## Tested on

Only tested on a **POCO F6 (peridot)** running **PixelOS 17 (Android 17)**. Other devices and
ROMs are untested.

## Build

Each deliverable builds on its own. See [`kernelsu/`](kernelsu) and [`xposed/BUILD.md`](xposed/BUILD.md):

```bash
bash kernelsu/build-module.sh   # -> kernelsu/out/FineVolume.zip    (no compiler needed)
bash xposed/build.sh            # -> xposed/out/FineVolume.apk      (javac + d8 + aapt + apksigner)
```

---

## 中文说明

让 Android 媒体音量更细腻：**档数更多**，蓝牙上**每一档都听得见**。

本仓库是**两个互相独立的模块**，合起来解决一个问题。蓝牙下缺一不可。

| | 交付物 | 类型 | 作用 |
|---|---|---|---|
| 1 | [`kernelsu/`](kernelsu) | KernelSU / Magisk 模块 | 媒体音量 15 → 30 档（写系统属性，在 `AudioService` 启动前生效） |
| 2 | [`xposed/`](xposed) | LSPosed 模块 | 关掉蓝牙 AVRCP 绝对音量，让多出来的档位在蓝牙上真正听得见 |

```
默认：               15 档   每按一下约 6.6%   蓝牙：耳机自己衰减
FineVolume（两个）：  30 档   每按一下约 3.3%   蓝牙：手机衰减，每档都生效
```

### 为什么是两个模块、两种机制

两半在不同的地方，各自只有一种做法：

- **档数**是系统属性 `ro.config.media_vol_steps`，`AudioService` **启动时读一次，早于任何
  Xposed 模块能运行**。只有 KernelSU / Magisk 模块能在它之前写好（`system.prop` 在
  `AudioService` 启动前应用）。Xposed 模块来不及。
- **蓝牙绝对音量**已经不能靠属性了。以前是开发者选项「禁用绝对音量」，底层属性
  `persist.bluetooth.disableabsvol`，但 **Android 17 QPR1 移除了该选项，属性也不再生效**
  （Google issue [536132206](https://issuetracker.google.com/issues/536132206)，标记为
  intended behavior）。剩下唯一的办法是在 `system_server` 里拦截
  `AudioService.setDeviceVolumeBehavior()`，这需要注入代码 —— Xposed 钩子。

所以：属性那半 → KernelSU 模块；注入代码那半 → Xposed 模块。两个互相独立，装其一或都装都行。

### 安装

1. 在 KernelSU 里刷 [`kernelsu/out/FineVolume.zip`](kernelsu)，**重启**。
2. 在 LSPosed 里装 [`xposed/out/FineVolume.apk`](xposed)，勾选 **系统框架**，**重启**。
   没有设置界面 —— 装上并启用**就是**开关；在 LSPosed 里停用即可关闭。

只走有线 / USB-C 的话，第 1 步就够。蓝牙两个都要。

### 测试环境

仅在 **POCO F6（peridot）** 上、**PixelOS 17（Android 17）** 下测试过。其它机型和 ROM 未经验证。

### 构建

两个交付物各自独立构建：

```bash
bash kernelsu/build-module.sh   # -> kernelsu/out/FineVolume.zip    （无需编译器）
bash xposed/build.sh            # -> xposed/out/FineVolume.apk      （javac + d8 + aapt + apksigner）
```

---

## Credits

The volume-steps property route follows **[LineageOS](https://review.lineageos.org/c/LineageOS/android_frameworks_base/+/226009)**
and **[crDroid](https://crdroid.net)**. Everything else here is this repository's own work.

## License

[MIT](LICENSE).
