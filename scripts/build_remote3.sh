#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="/workspace"
BUILD_DIR="/build"

python --version
python -m pip install --upgrade pip
python -m pip install -r "${SOURCE_DIR}/requirements.txt"
python -m pip install netifaces==0.11.0 pyinstaller

rm -rf "${BUILD_DIR}/build" "${BUILD_DIR}/dist" "${BUILD_DIR}/driver.spec"

cd "${BUILD_DIR}"
pyinstaller --clean --onedir --name driver \
  --paths "${SOURCE_DIR}/intg-samsungtv" \
  "${SOURCE_DIR}/intg-samsungtv/driver.py"

file "${BUILD_DIR}/dist/driver/driver" | grep -qi 'ARM aarch64'
test -x "${BUILD_DIR}/dist/driver/driver"
test -f "${BUILD_DIR}/dist/driver/_internal/_netifaces.cpython-311-aarch64-linux-gnu.so"

echo "Samsung TV ARM64 build completed"
