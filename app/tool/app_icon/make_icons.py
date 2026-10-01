#!/usr/bin/env python3
"""Cut every iOS and Android launcher icon from the 1024 master.

Run from app/ after render_app_icon_test.dart. iOS icons are written
without an alpha channel (App Store requirement for the 1024 icon).
"""
import json
from pathlib import Path

from PIL import Image

MASTER = Path('tool/app_icon/app_icon_1024.png')
IOS = Path('ios/Runner/Assets.xcassets/AppIcon.appiconset')
ANDROID = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
}

src = Image.open(MASTER).convert('RGB')


def resized(px):
    return src.resize((px, px), Image.LANCZOS)


for entry in json.loads((IOS / 'Contents.json').read_text())['images']:
    points = float(entry['size'].split('x')[0])
    scale = int(entry['scale'].rstrip('x'))
    px = round(points * scale)
    resized(px).save(IOS / entry['filename'])
    print(f"ios  {entry['filename']:<32} {px}px")

for density, px in ANDROID.items():
    out = Path(f'android/app/src/main/res/mipmap-{density}/ic_launcher.png')
    resized(px).save(out)
    print(f'android {out}  {px}px')
