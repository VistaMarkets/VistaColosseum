"""Builds Open Runde Tabular: Open Runde with fixed-width (tabular) digits.

Open Runde's digits are proportional (a "1" is ~25% narrower than an "8")
and the font has no `tnum` feature, so live prices shift sideways as they
tick. This gives all ten digits the width of the widest one in each weight,
centring each outline in its new width, and gives + and − a shared width so
a sign flip doesn't shift a number either. Every other glyph is untouched.

Run from app/:  python3 tool/tabular_digits.py
Writes assets/fonts/OpenRundeTabular-<Weight>.otf. Open Runde is under the
SIL Open Font License 1.1 (no Reserved Font Name), which allows modified
versions under the same license with a different name.
"""

from fontTools.pens.t2CharStringPen import T2CharStringPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont

WEIGHTS = ["Regular", "Medium", "Semibold", "Bold"]
DIGITS = "0123456789"
SIGNS = "+−"  # plus, minus


def widen(font, names, width):
    """Sets each glyph in [names] to [width], centring its outline."""
    hmtx = font["hmtx"]
    top = font["CFF "].cff.topDictIndex[0]
    nominal = getattr(top.Private, "nominalWidthX", 0)
    glyphs = font.getGlyphSet()
    for name in names:
        advance, lsb = hmtx[name]
        dx = round((width - advance) / 2)
        if dx == 0 and advance == width:
            continue
        pen = T2CharStringPen(width - nominal, glyphs)
        glyphs[name].draw(TransformPen(pen, (1, 0, 0, 1, dx, 0)))
        charstring = pen.getCharString(
            private=top.Private, globalSubrs=top.GlobalSubrs
        )
        top.CharStrings[name] = charstring
        hmtx[name] = (width, lsb + dx)


def rename(font, weight):
    family = "Open Runde Tabular"
    for record in font["name"].names:
        if record.nameID in (1, 16):
            record.string = family
        elif record.nameID == 4:
            record.string = f"{family} {weight}"
        elif record.nameID == 6:
            record.string = f"OpenRundeTabular-{weight}"
    top = font["CFF "].cff
    top.fontNames = [f"OpenRundeTabular-{weight}"]


def build(weight):
    font = TTFont(f"assets/fonts/OpenRunde-{weight}.otf")
    cmap = font.getBestCmap()
    hmtx = font["hmtx"]
    digits = [cmap[ord(c)] for c in DIGITS]
    widen(font, digits, max(hmtx[g][0] for g in digits))
    signs = [cmap[ord(c)] for c in SIGNS if ord(c) in cmap]
    if signs:
        widen(font, signs, max(hmtx[g][0] for g in signs))
    rename(font, weight)
    out = f"assets/fonts/OpenRundeTabular-{weight}.otf"
    font.save(out)
    return out


if __name__ == "__main__":
    for w in WEIGHTS:
        print(build(w))
