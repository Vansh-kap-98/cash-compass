"""Builds the 1-minute live demo script as a Word document.

Two columns on purpose: the left tells the person driving the phone what to
tap, the right is the only thing the speaker reads. In a live demo the usual
failure is the speaker narrating something that is not on screen yet, so the
two are locked side by side rather than written as prose.

    python docs/build_demo_script_docx.py
"""

import os
from docx import Document
from docx.shared import Pt, Inches, RGBColor
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "Cash-Compass-Demo-Script-1min.docx")

DARK = RGBColor(0x0B, 0x3F, 0x30)
GREEN = RGBColor(0x1F, 0x7A, 0x52)
GOLD = RGBColor(0xC6, 0x8F, 0x2F)
GREY = RGBColor(0x52, 0x60, 0x5A)
MUTED = RGBColor(0x8A, 0x97, 0x90)
INK = RGBColor(0x1A, 0x24, 0x1F)
FONT = "Calibri"

# (slot, tap instruction, spoken line, word count)
BEATS = [
    ("0:00–0:09",
     "Open the app.\nTap “Continue without an account”, then Continue.",
     "This is Cash Compass. No account, no sign-up — straight in. And nothing "
     "I enter here ever leaves this phone.", 23),
    ("0:09–0:21",
     "Dashboard.\nPoint at the black balance card, then the four tiles.",
     "One balance drives everything below it: what's available, what I've "
     "spent today, and a budgeting window that spreads what's left across the "
     "days I choose.", 31),
    ("0:21–0:33",
     "Tap the + button.\nShow the five actions, highlight Scan Receipt.",
     "Adding spending takes a second. I can type it — or photograph a "
     "receipt. The text is read on the phone itself, and nothing saves until "
     "I confirm it.", 30),
    ("0:33–0:45",
     "Planner tab.\nPoint at the daily spendable figure and the zone chip.",
     "The planner turns all that into a decision. Income, fixed costs and "
     "upcoming bills become one number — what's safe to spend today. Green, "
     "tight, or critical.", 30),
    ("0:45–0:53",
     "Settings → Achievements.\nScroll one screen.",
     "Goals and badges keep people coming back — fourteen badges, unlocked by "
     "real behaviour rather than by logging in.", 20),
    ("0:53–1:00",
     "Settings → Language → Русский.\nLet the screen redraw.",
     "And the whole app switches language instantly — which matters, because "
     "it was built by a team across two countries.", 21),
]

NOTES = [
    ("Drive the phone, don't read from it",
     "One person taps, one person speaks. The speaker watches the screen, not "
     "the page — if the tap lands late, hold the line until it does."),
    ("Set the phone up before you start",
     "Demo mode already entered, a balance and two or three transactions "
     "already saved, and the language on English. A blank app demos badly."),
    ("The language switch is the closing beat",
     "It is the only moment that shows the international part of the project "
     "in one second. Leave it last and let the screen finish redrawing."),
    ("If you are running short on time",
     "Cut the Achievements beat. It is the only one that is not load-bearing."),
]


def shade(cell, fill):
    el = OxmlElement("w:shd")
    el.set(qn("w:val"), "clear")
    el.set(qn("w:fill"), fill)
    cell._tc.get_or_add_tcPr().append(el)


def run(p, txt, size=11, bold=False, color=GREY, italic=False):
    r = p.add_run(txt)
    r.font.size = Pt(size)
    r.font.bold = bold
    r.font.italic = italic
    r.font.color.rgb = color
    r.font.name = FONT
    return r


def para(doc, txt="", size=11, bold=False, color=GREY, after=6, before=0,
         italic=False, leading=None):
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(after)
    p.paragraph_format.space_before = Pt(before)
    if leading:
        p.paragraph_format.line_spacing = leading
    if txt:
        run(p, txt, size, bold, color, italic)
    return p


def rule(doc):
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(10)
    pPr = p._p.get_or_add_pPr()
    bdr = OxmlElement("w:pBdr")
    b = OxmlElement("w:bottom")
    b.set(qn("w:val"), "single"); b.set(qn("w:sz"), "6")
    b.set(qn("w:space"), "1"); b.set(qn("w:color"), "C9DCD1")
    bdr.append(b); pPr.append(bdr)


doc = Document()
sec = doc.sections[0]
sec.page_width, sec.page_height = Inches(8.27), Inches(11.69)
sec.left_margin = sec.right_margin = Inches(0.8)
sec.top_margin = Inches(0.75)
sec.bottom_margin = Inches(0.7)
doc.styles["Normal"].font.name = FONT
doc.styles["Normal"].font.size = Pt(11)

para(doc, "PENNY PILOTS  ·  LIVE DEMO", 9.5, True, GOLD, 2)
para(doc, "Cash Compass — Demo Script", 26, True, DARK, 2)
para(doc, "One minute · six beats · two people", 13, False, GREEN, 10)
rule(doc)
para(doc,
     "About 155 spoken words. The left column is what the phone does; the "
     "right column is the only thing you say. Never narrate a screen before "
     "it is showing.",
     10.5, False, GREY, 14)

tbl = doc.add_table(rows=1, cols=3)
tbl.alignment = WD_TABLE_ALIGNMENT.LEFT
widths = [Inches(0.85), Inches(2.45), Inches(3.35)]
hdr = tbl.rows[0].cells
for i, h in enumerate(["TIME", "ON SCREEN", "SAY"]):
    hdr[i].text = ""
    run(hdr[i].paragraphs[0], h, 8.5, True, RGBColor(0xFF, 0xFF, 0xFF))
    shade(hdr[i], "0B3F30")

for n, (slot, tap, say, words) in enumerate(BEATS):
    cells = tbl.add_row().cells

    cells[0].text = ""
    p = cells[0].paragraphs[0]
    run(p, slot, 9.5, True, GOLD)
    p2 = cells[0].add_paragraph()
    p2.paragraph_format.space_before = Pt(2)
    run(p2, "%d words" % words, 8, False, MUTED)

    cells[1].text = ""
    for j, line in enumerate(tap.split("\n")):
        p = cells[1].paragraphs[0] if j == 0 else cells[1].add_paragraph()
        p.paragraph_format.space_after = Pt(2)
        run(p, line, 10, j == 0, DARK if j == 0 else GREY)

    cells[2].text = ""
    p = cells[2].paragraphs[0]
    p.paragraph_format.line_spacing = 1.3
    run(p, say, 12, False, INK)

    if n % 2 == 1:
        for c in cells:
            shade(c, "F1F9F4")

for row in tbl.rows:
    for i, c in enumerate(row.cells):
        c.width = widths[i]

para(doc, "", 8, after=12)
para(doc, "HOW TO RUN IT", 10, True, GREEN, 6)
for t, b in NOTES:
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(8)
    p.paragraph_format.space_after = Pt(2)
    p.paragraph_format.keep_with_next = True
    run(p, t, 12, True, DARK)
    para(doc, b, 11, False, GREY, 2, leading=1.25)

para(doc, "", 8, after=10)
rule(doc)
para(doc,
     "Cash Compass · Penny Pilots · Southern Federal University (Russia) × "
     "Manipal University Jaipur (India)", 9, False, MUTED, 0)

doc.save(OUT)
print("wrote %s (%.0f KB)" % (OUT, os.path.getsize(OUT) / 1024))
print("spoken total: %d words" % sum(b[3] for b in BEATS))
