#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="/workspace"
BUILD_DIR="/build"
VENV_DIR="${BUILD_DIR}/venv"

rm -rf "${BUILD_DIR}/build" "${BUILD_DIR}/dist" "${BUILD_DIR}/driver.spec" "${VENV_DIR}"
python -m venv "${VENV_DIR}"
source "${VENV_DIR}/bin/activate"
python -m pip install --upgrade pip
python -m pip install -r "${SOURCE_DIR}/requirements.txt"
python -m pip install -r "${SOURCE_DIR}/runtime-reference.txt"
python -m pip install "pyinstaller==6.21.0"
python -c 'import attrs, cffi, cryptography, netifaces, websockets, zeroconf; print("Reference runtime imports OK")'

cd "${BUILD_DIR}"
pyinstaller --clean --onedir --name driver \
  --paths "${SOURCE_DIR}/intg-samsungtv" \
  "${SOURCE_DIR}/intg-samsungtv/driver.py"

file "${BUILD_DIR}/dist/driver/driver" | grep -qi 'ARM aarch64'
test -x "${BUILD_DIR}/dist/driver/driver"
test -f "${BUILD_DIR}/dist/driver/_internal/_netifaces.cpython-311-aarch64-linux-gnu.so"

# These are the four package versions observed in the known-working 1.5.1 bundle.
test -d "${BUILD_DIR}/dist/driver/_internal/attrs-25.3.0.dist-info"
test -d "${BUILD_DIR}/dist/driver/_internal/cryptography-44.0.2.dist-info"
test -d "${BUILD_DIR}/dist/driver/_internal/websockets-15.0.1.dist-info"
test -d "${BUILD_DIR}/dist/driver/_internal/zeroconf-0.146.5.dist-info"
test ! -e "${BUILD_DIR}/dist/driver/_internal/cryptography-49.0.0.dist-info"
test ! -e "${BUILD_DIR}/dist/driver/_internal/pydantic"
test ! -e "${BUILD_DIR}/dist/driver/_internal/pydantic_core"

echo "Samsung TV ARM64 build completed"
