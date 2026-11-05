"""Builds the 3-minute defense script as a Word document.

Formatted for reading aloud, not for screen: the spoken lines are set large and
loosely leaded so a presenter can find their place at a glance, while timings,
word counts and stage directions are small and grey so they never compete with
the words.

    python docs/build_script_docx.py
"""

import os
from docx import Document
from docx.shared import Pt, Inches, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "Cash-Compass-Defense-Script-3min.docx")

# Same identity as the deck.
DARK = RGBColor(0x0B, 0x3F, 0x30)
GREEN = RGBColor(0x1F, 0x7A, 0x52)
GOLD = RGBColor(0xC6, 0x8F, 0x2F)
GREY = RGBColor(0x52, 0x60, 0x5A)
MUTED = RGBColor(0x8A, 0x97, 0x90)
INK = RGBColor(0x1A, 0x24, 0x1F)
FONT = "Calibri"


def shade(cell, hex_fill):
    el = OxmlElement("w:shd")
    el.set(qn("w:val"), "clear")
    el.set(qn("w:fill"), hex_fill)
    cell._tc.get_or_add_tcPr().append(el)


def para(doc, text="", size=11, bold=False, color=GREY, space_after=6,
         space_before=0, align=None, italic=False, leading=None):
    p = doc.add_paragraph()
    if align is not None:
        p.alignment = align
    pf = p.paragraph_format
    pf.space_after = Pt(space_after)
    pf.space_before = Pt(space_before)
    if leading:
        pf.line_spacing = leading
    if text:
        r = p.add_run(text)
        r.font.size = Pt(size)
        r.font.bold = bold
        r.font.italic = italic
        r.font.color.rgb = color
        r.font.name = FONT
    return p


def rule(doc, color="C9DCD1"):
    """A thin horizontal rule as a paragraph border (never a table)."""
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(10)
    p.paragraph_format.space_before = Pt(2)
    pPr = p._p.get_or_add_pPr()
    bdr = OxmlElement("w:pBdr")
    bottom = OxmlElement("w:bottom")
    bottom.set(qn("w:val"), "single")
    bottom.set(qn("w:sz"), "6")
    bottom.set(qn("w:space"), "1")
    bottom.set(qn("w:color"), color)
    bdr.append(bottom)
    pPr.append(bdr)
    return p


# ---------------------------------------------------------------- the script
ORDER = [
    ("1", "GLEB", "Title", "0:00–0:10", 26,
     ["Good morning. We're Penny Pilots — nine students across Russia and "
      "India. This is Cash Compass: a finance app that answers one question "
      "students actually ask."]),
    ("2", "KINTAN", "Team — India", "0:10–0:20", 26,
     ["Our team in India built the mobile product and the interface — "
      "frontend, design, economics and user research, five of us at Manipal "
      "Jaipur."]),
    ("3", "GLEB", "Team — Russia", "0:20–0:30", 25,
     ["And four of us at Southern Federal University built the backend, the "
      "data analysis and the market research that shaped it. One team, one "
      "codebase."]),
    ("4", "ATHENA", "The problem", "0:30–0:48", 47,
     ["Every finance app tells you where your money went. That's a report, "
      "not a decision.",
      "A student standing in a shop with four days left doesn't need a "
      "report. They need to know: can I afford this, right now? Nothing on "
      "the market answers that. So we built it."]),
    ("5", "GLEB", "Key features", "0:48–1:06", 46,
     ["Six features, all built around that one question.",
      "Safe-to-Spend gives a daily limit after bills and goals. Reason tags "
      "expose impulse and social spending. Recurring charges get caught "
      "automatically. Goals, calendar alerts and a personalised dashboard "
      "complete it.",
      "Three of us built the platforms underneath."]),
    ("6", "KINTAN", "Front end — web", "1:06–1:20", 36,
     ["The web app is React and TypeScript, with Tailwind and Recharts, "
      "deployed on Vercel.",
      "It ships in three languages through i18next — because half this team "
      "doesn't speak the other half's language, and neither do our users."]),
    ("7", "GLEB", "Back end", "1:20–1:34", 36,
     ["Behind both platforms: Python and FastAPI on TiDB, deployed on "
      "Railway. Eighteen endpoints, four tables, responses under a hundred "
      "milliseconds.",
      "One backend serves the website and the phone — so the logic exists "
      "once, not twice."]),
    ("8", "VANSH", "Mobile", "1:34–1:48", 36,
     ["The Android app is Flutter — twenty-three thousand lines of Dart, "
      "five hundred and thirty-seven tests passing.",
      "It works with no account and no connection. Receipts are read "
      "on-device, so the photograph never leaves your phone."]),
    ("9", "ISMAIL", "Market research", "1:48–2:08", 52,
     ["We compared Cash Compass against the tools students already have.",
      "Forty-three million students in our market. Typical allowance, five "
      "to ten thousand rupees. Only eighteen per cent track their spending at "
      "all — and around sixty-five per cent run out seven to ten days early.",
      "Mint and Wallet are built for salaried users. That gap is the "
      "product."]),
    ("10", "AKSHIT  →  VLAD", "Economics & data", "2:08–2:28", 52,
     ["AKSHIT — Underneath it are five mathematical models. The survival "
      "calculator takes income, fixed costs and upcoming bills, and returns "
      "one number: what's safe to spend today. Green, Tight, or Critical.",
      "VLAD — And every figure is derived live from the transaction data — "
      "never cached, never stale. The number you see is the number that's "
      "true now."]),
    ("11", "MEEHIKA  →  SIMPHIWE", "UI/UX & design", "2:28–2:46", 47,
     ["MEEHIKA — Twenty-two high-fidelity screens define the product. Three "
      "steps throughout: capture, understand, decide. The mobile app stays "
      "deliberately restrained so the numbers carry the page.",
      "SIMPHIWE — And the brand carries across both platforms and this deck "
      "— one identity, from the app icon to the slide you're looking at."]),
    ("12", "GLEB", "Close", "2:46–2:56", 26,
     ["Two countries, one product, built in parallel and shipping today. "
      "Everything is on GitHub. We're happy to take questions. Thank you."]),
]

CUES = [
    ("Gleb speaks five times", "Slides 1, 3, 5, 7 and 12. Practise those "
     "re-entries — they are where a three-minute run usually loses ten seconds."),
    ("Slides 10 and 11 are two-voice", "Hand over mid-slide without pausing. "
     "The second speaker starts as the first finishes their last word."),
    ("Nobody says their own name or role", "The slide shows it. Nine "
     "introductions would cost twenty-five seconds — fourteen per cent of your "
     "entire time."),
    ("Drop first if you are over", "Gleb's last line in 5, Vlad's second "
     "sentence in 10, Simphiwe's clause after the dash in 11."),
    ("Say these slowly", "537 tests · 43.3 million · 18 per cent · 65 per "
     "cent · 100 milliseconds. They are the credibility beats."),
    ("There is no recovery time", "If a slide runs long, the next speaker "
     "cuts rather than catching up."),
]

# ------------------------------------------------------------------- build
doc = Document()
sec = doc.sections[0]
sec.page_width, sec.page_height = Inches(8.27), Inches(11.69)      # A4
sec.left_margin = sec.right_margin = Inches(0.85)
sec.top_margin = Inches(0.8)
sec.bottom_margin = Inches(0.75)

normal = doc.styles["Normal"]
normal.font.name = FONT
normal.font.size = Pt(11)

# --- title block
para(doc, "PENNY PILOTS  ·  INTERNATIONAL PROJECT 2026", 9.5, True, GOLD, 2)
para(doc, "Cash Compass — Defense Script", 26, True, DARK, 2)
para(doc, "Three minutes · 12 slides · 9 speakers", 13, False, GREEN, 10)
rule(doc)
para(doc,
     "About 460 spoken words for the whole team — roughly 35 words each. Every "
     "line below is counted to fit its slot. There is no slack: if you add a "
     "sentence, someone else loses one.",
     10.5, False, GREY, 14)

# --- running order table
para(doc, "RUNNING ORDER", 10, True, GREEN, 6)
tbl = doc.add_table(rows=1, cols=5)
tbl.alignment = WD_TABLE_ALIGNMENT.LEFT
widths = [Inches(0.45), Inches(2.25), Inches(1.9), Inches(1.0), Inches(0.95)]
hdr = tbl.rows[0].cells
for i, h in enumerate(["#", "Speaker", "Slide", "Slot", "Words"]):
    hdr[i].text = ""
    p = hdr[i].paragraphs[0]
    r = p.add_run(h.upper())
    r.font.size = Pt(8.5); r.font.bold = True
    r.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF); r.font.name = FONT
    shade(hdr[i], "0B3F30")

for num, who, slide, slot, words, _ in ORDER:
    cells = tbl.add_row().cells
    for i, v in enumerate([num, who, slide, slot, str(words)]):
        cells[i].text = ""
        r = cells[i].paragraphs[0].add_run(v)
        r.font.size = Pt(9.5)
        r.font.bold = (i == 1)
        r.font.color.rgb = INK if i == 1 else GREY
        r.font.name = FONT
    if int(num) % 2 == 0:
        for c in cells:
            shade(c, "F1F9F4")

for row in tbl.rows:
    for i, c in enumerate(row.cells):
        c.width = widths[i]

para(doc, "", 8, space_after=4)
para(doc, "Buffer: 2:56–3:00.", 9.5, False, MUTED, 0, italic=True)

doc.add_page_break()

# --- the script itself
para(doc, "THE SCRIPT", 10, True, GREEN, 8)

for num, who, slide, slot, words, lines in ORDER:
    # speaker header
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(16)
    p.paragraph_format.space_after = Pt(1)
    r = p.add_run("%s · %s" % (num, who))
    r.font.size = Pt(14); r.font.bold = True
    r.font.color.rgb = DARK; r.font.name = FONT
    r2 = p.add_run("     %s" % slide)
    r2.font.size = Pt(11); r2.font.color.rgb = GREY; r2.font.name = FONT
    p.paragraph_format.keep_with_next = True

    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(7)
    p.paragraph_format.keep_with_next = True
    r = p.add_run("%s   ·   %d words" % (slot, words))
    r.font.size = Pt(9); r.font.bold = True
    r.font.color.rgb = GOLD; r.font.name = FONT

    for n, line in enumerate(lines):
        # Spoken text: large and loosely leaded so it can be read at a glance.
        sp = doc.add_paragraph()
        sp.paragraph_format.space_after = Pt(8)
        sp.paragraph_format.keep_with_next = (n < len(lines) - 1)
        sp.paragraph_format.line_spacing = 1.45
        sp.paragraph_format.left_indent = Inches(0.16)
        # A leading "NAME —" marks the hand-over inside a two-voice slide.
        if " — " in line and line.split(" — ")[0].isupper():
            who_part, rest = line.split(" — ", 1)
            r = sp.add_run(who_part + " — ")
            r.font.size = Pt(12.5); r.font.bold = True
            r.font.color.rgb = GREEN; r.font.name = FONT
            r = sp.add_run(rest)
        else:
            r = sp.add_run(line)
        r.font.size = Pt(12.5)
        r.font.color.rgb = INK
        r.font.name = FONT

doc.add_page_break()

# --- cue sheet
para(doc, "CUE SHEET", 10, True, GREEN, 8)
para(doc, "Read this once before you rehearse", 18, True, DARK, 10)
rule(doc)

for title, body in CUES:
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(9)
    p.paragraph_format.space_after = Pt(2)
    r = p.add_run(title)
    r.font.size = Pt(12); r.font.bold = True
    r.font.color.rgb = DARK; r.font.name = FONT
    para(doc, body, 11, False, GREY, 2, leading=1.25)

para(doc, "", 8, space_after=10)
rule(doc)
para(doc,
     "Cash Compass · Penny Pilots · Southern Federal University (Russia) × "
     "Manipal University Jaipur (India)",
     9, False, MUTED, 0)

doc.save(OUT)
print("wrote %s (%.0f KB)" % (OUT, os.path.getsize(OUT) / 1024))
