#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="${SOURCE_DIR:-/workspace}"
BUILD_DIR="${BUILD_DIR:-/build}"
VENV_DIR="${VENV_DIR:-${BUILD_DIR}/venv}"

python --version
rm -rf "${VENV_DIR}"
python -m venv "${VENV_DIR}"

"${VENV_DIR}/bin/python" -m pip install --upgrade pip==26.1.2
"${VENV_DIR}/bin/python" -m pip install -r "${SOURCE_DIR}/requirements.txt"
"${VENV_DIR}/bin/python" -m pip install --no-deps \
  attrs==25.3.0 \
  cffi==1.17.1 \
  cryptography==44.0.2 \
  netifaces==0.11.0 \
  websockets==15.0.1 \
  zeroconf==0.146.5 \
  PyInstaller==6.21.0

"${VENV_DIR}/bin/python" -c 'import sys; assert sys.version_info[:3] == (3, 11, 13); print("Python 3.11.13 validated")'
"${VENV_DIR}/bin/python" -c 'import attrs, cffi, cryptography, netifaces, websockets, zeroconf; assert attrs.__version__ == "25.3.0"; assert cffi.__version__ == "1.17.1"; assert cryptography.__version__ == "44.0.2"; assert websockets.__version__ == "15.0.1"; assert zeroconf.__version__ == "0.146.5"; assert netifaces.interfaces(); print("Reference runtime dependencies validated")'

rm -rf "${BUILD_DIR}/build" "${BUILD_DIR}/dist" "${BUILD_DIR}/driver.spec"
"${VENV_DIR}/bin/pyinstaller" \
  --clean \
  --onedir \
  --name driver \
  --paths "${SOURCE_DIR}/intg-samsungtv" \
  "${SOURCE_DIR}/intg-samsungtv/driver.py"

file "${BUILD_DIR}/dist/driver/driver" | grep -qi 'ARM aarch64'
test -x "${BUILD_DIR}/dist/driver/driver"
test -f "${BUILD_DIR}/dist/driver/_internal/_netifaces.cpython-311-aarch64-linux-gnu.so"
test -f "${BUILD_DIR}/dist/driver/_internal/_cffi_backend.cpython-311-aarch64-linux-gnu.so"
test -d "${BUILD_DIR}/dist/driver/_internal/cryptography-44.0.2.dist-info"
test -d "${BUILD_DIR}/dist/driver/_internal/zeroconf-0.146.5.dist-info"
test -d "${BUILD_DIR}/dist/driver/_internal/websockets-15.0.1.dist-info"
test -d "${BUILD_DIR}/dist/driver/_internal/attrs-25.3.0.dist-info"
test ! -e "${BUILD_DIR}/dist/driver/_internal/cryptography-49.0.0.dist-info"

echo "PyInstaller ARM64 build and reference runtime validation OK"
