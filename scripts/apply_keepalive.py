from pathlib import Path

p = Path('intg-samsungtv/tv.py')
s = p.read_text()

if 'Samsung REST keep-alive' in s:
    raise SystemExit('keep-alive patch already present')

# Source-specific patch will be applied after exact upstream source validation.
# This file is intentionally a guard until the exact insertion points are known.
raise SystemExit('PATCH NOT APPLIED: exact upstream source must be reviewed before build')
