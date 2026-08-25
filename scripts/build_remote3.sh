#!/usr/bin/env bash
set -euo pipefail

python --version
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
python -m pip install netifaces==0.11.0 pyinstaller
rm -rf build dist driver.spec
pyinstaller --clean --onedir --name driver intg-samsungtv/driver.py
file dist/driver/driver | grep -qi 'ARM aarch64'
test -x dist/driver/driver
test -f dist/driver/_internal/_netifaces.cpython-311-aarch64-linux-gnu.so

echo "Samsung TV ARM64 build completed"
