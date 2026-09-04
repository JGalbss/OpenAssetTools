#!/usr/bin/env bash
# Build OpenAssetTools natively on Apple Silicon.
# premake emits x86_64 + -Werror + a zlib that misses <unistd.h>; fix all three,
# then build. Config name stays "release_x64" - only the -arch flag changed.
set -euo pipefail
cd "$(dirname "$0")"
premake5 gmake
find build -name Makefile -exec sed -i '' \
  -e 's/-mmacosx-version-min=latest/-mmacosx-version-min=14.0/g' \
  -e 's/-arch x86_64/-arch arm64/g' \
  -e 's/ -Werror//g' {} +
python3 - <<'PY'
import pathlib, re
p = pathlib.Path("build/thirdparty/zlib/Makefile"); s = p.read_text()
p.write_text(re.sub(r'(\n\s*DEFINES\s*\+?=\s*)', r'\1-DHAVE_UNISTD_H ', s))
PY
make -C build -j"${KB_JOBS:-4}" config=release_x64 "${1:-UnlinkerCli}"
echo "built: build/bin/Release_x64/"
