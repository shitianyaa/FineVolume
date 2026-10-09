#!/bin/bash
# Build the KernelSU volume-steps module zip.
#
# The zip is what you flash in KernelSU / Magisk. Nothing is compiled here:
# the module is just module.prop + system.prop + customize.sh.
#
#   bash build-module.sh            ->  out/FineVolume.zip
#
set -euo pipefail
cd "$(dirname "$0")"

OUT=out
NAME=FineVolume

rm -rf "$OUT"
mkdir -p "$OUT"

STAGE="$OUT/stage"
mkdir -p "$STAGE"
cp module.prop system.prop customize.sh "$STAGE/"

# Strip CRLF: these files are edited on Windows and the shell scripts must be LF
# for the device's busybox ash to run them.
sed -i 's/\r$//' "$STAGE/customize.sh" "$STAGE/module.prop" "$STAGE/system.prop"

# Sanity: module.prop must have the fields KernelSU reads.
for f in id name version versionCode author description; do
    grep -q "^$f=" "$STAGE/module.prop" || { echo "module.prop: missing $f"; exit 1; }
done

# Package. Use Python's zipfile so entry names are plain ASCII and the archive
# has no extra directory entries that some installers choke on.
python - "$OUT/$NAME.zip" "$STAGE" <<'PY'
import os, sys, zipfile
zip_path, stage = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
    for name in sorted(os.listdir(stage)):
        z.write(os.path.join(stage, name), name)
PY

echo "built: $OUT/$NAME.zip"
unzip -l "$OUT/$NAME.zip" 2>/dev/null || python -c "
import zipfile,sys
z=zipfile.ZipFile('$OUT/$NAME.zip')
[print('  %-16s %d bytes' % (i.filename, i.file_size)) for i in z.infolist()]
"
