# Building the FineVolume Xposed module / 构建 FineVolume 的 Xposed 模块

## Requirements / 环境要求

Linux, macOS, or Windows with WSL (Ubuntu). / Linux、macOS，或带 WSL (Ubuntu) 的 Windows。

- Bash
- JDK 8 or newer / JDK 8 或更新
- Android platform 23 (`android.jar`) / Android platform 23 (`android.jar`)
- `aapt`, `zipalign`, `apksigner`, `d8`

On Ubuntu / Debian (including WSL) / 在 Ubuntu / Debian（含 WSL）上：

```bash
sudo apt install default-jdk-headless aapt zipalign apksigner android-sdk-platform-23
```

`d8` ships with the Android SDK build-tools (`$ANDROID_HOME/build-tools/<version>/d8`).
`d8` 随 Android SDK build-tools 提供（`$ANDROID_HOME/build-tools/<version>/d8`）。

## Build / 构建

From the `xposed` directory / 在 `xposed` 目录下：

```bash
cd xposed
sed -i 's/\r$//' build.sh meta/xposed/*   # only for Windows line endings / 仅当文件是 Windows 换行时
bash build.sh
```

The script / 脚本会：

1. Compiles the libxposed API stubs and the module code. / 编译 libxposed API stub 与模块代码。
2. Converts the classes to DEX. / 转换为 DEX。
3. Packages the APK. / 打包 APK。
4. Signs it with a throwaway test key (`key.jks`, generated on the first run). / 用一次性测试密钥
   （`key.jks`，首次运行时生成）签名。
5. Writes `out/FineVolume.apk`. / 输出 `out/FineVolume.apk`。

If the toolchain is not on `PATH`, point the script at it with `AJ`, `D8`, `AAPT`, `ZIPALIGN`,
`APKSIGNER`. / 若工具链不在 `PATH`，可用 `AJ`、`D8`、`AAPT`、`ZIPALIGN`、`APKSIGNER` 指定路径。

## Signing a release / 发布签名

The test-signed APK is fine for trying the module. For a release, sign it with your own keystore
(the password is requested at the prompt) / 测试签名的 APK 足以试用；发布请用你自己的密钥库签名
（口令会在提示符处询问）：

```bash
apksigner sign --ks your-keystore.jks --ks-key-alias youralias \
  --min-sdk-version 26 --out FineVolume-signed.apk out/aligned.apk
```

An update only installs over an existing install if it is signed with the same key. Keep your
keystore private and never commit it. / 只有用同一密钥签名，更新才能覆盖安装。密钥库请自行保管，
切勿提交。
