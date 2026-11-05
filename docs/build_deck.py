"""Rebuilds the Cash Compass defense deck: 12 slides, 3-minute run.

Keeps the team's existing visual identity (dark green / gold / pale green) and
fixes what was wrong in the source deck:

  * every avatar is a circle of identical diameter, centre-cropped from its
    original so no face is stretched (the source stretched them up to 52%)
  * every icon and screenshot keeps its true aspect ratio
  * two missing slides added (Mobile; Economics & Data) so the deck matches the
    agreed 12-slide speaking order

    python docs/build_deck.py
"""

import os
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
AV = os.path.join(HERE, "deck-avatars")
MEDIA = os.path.join(HERE, "deck-media")
SHOTS = os.path.join(HERE, "pdf-assets")
OUT = os.path.join(HERE, "Cash-Compass-Defense-Deck.pptx")

# ------------------------------------------------------------------ palette
# Sampled from the team's existing deck so the identity carries over exactly.
DARK = RGBColor(0x0B, 0x3F, 0x30)      # deep green - headers, dark slides
GREEN = RGBColor(0x1F, 0x7A, 0x52)     # mid green - accents, avatars
GOLD = RGBColor(0xC6, 0x8F, 0x2F)      # gold - figures, emphasis
PALE = RGBColor(0xE0, 0xF2, 0xE8)      # pale green - card fills
MIST = RGBColor(0xF1, 0xF9, 0xF4)      # lightest tint
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
GREY = RGBColor(0x52, 0x60, 0x5A)      # body text
INK = RGBColor(0x1A, 0x24, 0x1F)

# Calibri, not the source deck's Aptos: Aptos has no metric-compatible
# substitute outside recent Office installs, so a marker on an older machine
# would see different line breaks. Calibri ships everywhere and was already
# used throughout the source deck.
FONT = "Calibri"

W, H = 13.333, 7.5
M = 0.62                                # page margin


# ------------------------------------------------------------------ helpers
def blank(prs):
    return prs.slides.add_slide(prs.slide_layouts[6])


def rect(slide, x, y, w, h, fill=None, line=None, lw=1.0, radius=None,
         shape=MSO_SHAPE.ROUNDED_RECTANGLE):
    s = slide.shapes.add_shape(shape, Inches(x), Inches(y), Inches(w), Inches(h))
    if fill is None:
        s.fill.background()
    else:
        s.fill.solid()
        s.fill.fore_color.rgb = fill
    if line is None:
        s.line.fill.background()
    else:
        s.line.color.rgb = line
        s.line.width = Pt(lw)
    s.shadow.inherit = False
    if radius is not None and shape == MSO_SHAPE.ROUNDED_RECTANGLE:
        try:
            s.adjustments[0] = radius
        except Exception:
            pass
    if s.has_text_frame:
        s.text_frame.text = ""
    return s


def text(slide, x, y, w, h, body, size=14, bold=False, color=GREY,
         align=PP_ALIGN.LEFT, space=0, anchor=MSO_ANCHOR.TOP, line_sp=None):
    tb = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    tf = tb.text_frame
    tf.word_wrap = True
    tf.margin_left = tf.margin_right = tf.margin_top = tf.margin_bottom = 0
    tf.vertical_anchor = anchor
    for i, line in enumerate(body.split("\n")):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.alignment = align
        if space:
            p.space_after = Pt(space)
        if line_sp:
            p.line_spacing = line_sp
        r = p.add_run()
        r.text = line
        r.font.size = Pt(size)
        r.font.bold = bold
        r.font.color.rgb = color
        r.font.name = FONT
    return tb


def pic_fit(slide, path, cx, y, box_w, box_h):
    """Place an image inside a box, centred, aspect ratio preserved.

    The source deck set width and height independently, which stretched several
    portraits by up to 52%. Everything here is scaled by one factor.
    """
    iw, ih = Image.open(path).size
    scale = min(box_w / iw, box_h / ih)
    w, h = iw * scale, ih * scale
    return slide.shapes.add_picture(path, Inches(cx - w / 2), Inches(y),
                                    Inches(w), Inches(h))


def avatar(slide, key, cx, y, d, name, role):
    """Circular portrait of fixed diameter, with name and role beneath."""
    path = os.path.join(AV, key + ".png")
    slide.shapes.add_picture(path, Inches(cx - d / 2), Inches(y),
                             Inches(d), Inches(d))          # square = circle
    text(slide, cx - 1.25, y + d + 0.16, 2.5, 0.28, name, 13.5, True, INK,
         PP_ALIGN.CENTER)
    text(slide, cx - 1.25, y + d + 0.46, 2.5, 0.44, role, 10.5, False, GREY,
         PP_ALIGN.CENTER)


def heading(slide, title, kicker=None, sub=None, speaker=None):
    y = M
    if kicker:
        text(slide, M, y, 7.0, 0.22, kicker.upper(), 10, True, GOLD)
        y += 0.30
    text(slide, M, y, 9.4, 0.62, title, 31, True, DARK)
    y += 0.68
    if sub:
        text(slide, M, y, 9.6, 0.40, sub, 13.5, False, GREY)
        y += 0.46
    if speaker:
        chip = rect(slide, W - M - 2.5, M - 0.04, 2.5, 0.40, PALE, None,
                    radius=0.5)
        text(slide, W - M - 2.5, M + 0.05, 2.5, 0.24, speaker, 11.5, True,
             DARK, PP_ALIGN.CENTER)
    return y


def footer(slide, right=None):
    text(slide, M, H - 0.46, 5.0, 0.22, "CASH COMPASS  •  PENNY PILOTS", 9,
         True, RGBColor(0xA8, 0xB5, 0xAE))
    if right:
        text(slide, W - M - 5.0, H - 0.46, 5.0, 0.22, right, 9, False,
             RGBColor(0xA8, 0xB5, 0xAE), PP_ALIGN.RIGHT)


def stat(slide, x, y, w, value, label, h=1.08):
    rect(slide, x, y, w, h, MIST, PALE, 1.0, radius=0.18)
    text(slide, x + 0.22, y + 0.16, w - 0.44, 0.48, value, 26, True, GOLD)
    text(slide, x + 0.22, y + 0.68, w - 0.44, 0.28, label.upper(), 9, True,
         GREY)


def card(slide, x, y, w, h, num, title, bodytext):
    rect(slide, x, y, w, h, WHITE, PALE, 1.25, radius=0.12)
    badge = rect(slide, x + 0.26, y + 0.26, 0.42, 0.42, GREEN, None,
                 shape=MSO_SHAPE.OVAL)
    text(slide, x + 0.26, y + 0.35, 0.42, 0.26, num, 11, True, WHITE,
         PP_ALIGN.CENTER)
    text(slide, x + 0.82, y + 0.28, w - 1.08, 0.46, title, 13.5, True, DARK)
    text(slide, x + 0.26, y + 0.92, w - 0.52, h - 1.10, bodytext, 11, False,
         GREY, line_sp=1.08)


LOGO = os.path.join(MEDIA, "d80ec4daed.png")
COMPARE = os.path.join(MEDIA, "5a84b660d4.png")


# ======================================================================= deck
prs = Presentation()
prs.slide_width, prs.slide_height = Inches(W), Inches(H)

# ---------------------------------------------------------------- 1 · title
s = blank(prs)
rect(s, 0, 0, W, H, DARK, None, shape=MSO_SHAPE.RECTANGLE)
rect(s, 0, 0, 0.26, H, GREEN, None, shape=MSO_SHAPE.RECTANGLE)
pic_fit(s, LOGO, W - 3.3, 1.55, 4.3, 4.3)
text(s, 1.15, 1.95, 7.6, 0.30, "INTERNATIONAL PROJECT  •  2026", 12, True, GOLD)
text(s, 1.15, 2.38, 8.2, 1.9, "CASH\nCOMPASS", 60, True, WHITE, line_sp=0.92)
text(s, 1.15, 4.62, 7.4, 0.34, "Smart financial management for students", 19,
     False, PALE)
rect(s, 1.15, 5.30, 4.9, 0.05, GOLD, None, shape=MSO_SHAPE.RECTANGLE)
text(s, 1.15, 5.56, 8.0, 0.80,
     "Southern Federal University, Russia   ×   Manipal University Jaipur, India",
     12.5, False, RGBColor(0x9F, 0xC4, 0xB2))
text(s, 1.15, 6.52, 6.0, 0.26, "PENNY PILOTS  •  NINE STUDENTS, TWO COUNTRIES",
     10, True, RGBColor(0x7F, 0xA8, 0x95))

# ------------------------------------------------------- 2 · team, India
s = blank(prs)
heading(s, "The team in India", "01 · who we are",
        "Mobile product, interface, economics and user research.", "Kintan")
INDIA = [("kintan", "Kintan Jain", "Frontend Lead"),
         ("meehika", "Meehika Sharma", "Lead UI/UX Designer"),
         ("athena", "Athena Nair", "Marketing & User Research"),
         ("akshit", "Akshit Saini", "Lead Economist"),
         ("vansh", "Vansh Kapoor", "Backend & API Architect")]
d = 1.55
gap = (W - 2 * M) / 5
for i, (k, n, r) in enumerate(INDIA):
    avatar(s, k, M + gap * (i + 0.5), 2.56, d, n, r)
rect(s, M, 5.52, W - 2 * M, 0.80, MIST, PALE, 1.0, radius=0.14)
text(s, M + 0.3, 5.76, W - 2 * M - 0.6, 0.36,
     "Five at Manipal Jaipur — they own the Android build and the product design.",
     12.5, False, GREY)
footer(s)

# ------------------------------------------------------ 3 · team, Russia
s = blank(prs)
heading(s, "The team in Russia", "01 · who we are",
        "Backend services, data analysis and market research.", "Gleb")
RUSSIA = [("gleb", "Gleb Salnikov", "Full-stack Developer"),
          ("vlad", "Vladislav Usenko", "Lead Data Analyst"),
          ("ismail", "Ismail Sumamhna", "Market Researcher"),
          ("simphiwe", "Simphiwe Manaba", "Lead Graphic Designer")]
gap = (W - 2 * M) / 4
for i, (k, n, r) in enumerate(RUSSIA):
    avatar(s, k, M + gap * (i + 0.5), 2.56, d, n, r)
rect(s, M, 5.52, W - 2 * M, 0.80, MIST, PALE, 1.0, radius=0.14)
text(s, M + 0.3, 5.76, W - 2 * M - 0.6, 0.36,
     "Four at Southern Federal University — one backend serves both platforms.",
     12.5, False, GREY)
footer(s)

# ------------------------------------------------------- 4 · the problem
s = blank(prs)
heading(s, "Students don't need a report", "02 · the problem", None, "Athena")
text(s, M, 1.92, 7.4, 1.5,
     "Every finance app tells you where your money went.\nThat is a report, not a decision.",
     21, True, DARK, line_sp=1.14)
text(s, M, 3.40, 7.0, 1.2,
     "A student standing in a shop with four days left does not need a report.\n"
     "They need to know whether they can afford this, right now.",
     14, False, GREY, line_sp=1.18)
rect(s, M, 4.90, 7.0, 0.92, DARK, None, radius=0.14)
text(s, M + 0.34, 5.14, 6.4, 0.46, "“Can I afford this now?”", 19,
     True, WHITE)
for i, (v, l) in enumerate([("43.3M", "students in market"),
                            ("18%", "track any spending"),
                            ("~65%", "run out 7–10 days early")]):
    stat(s, 8.20, 1.95 + i * 1.30, 4.5, v, l, 1.14)
footer(s, "Source: Team Progress & Research Report")

# ------------------------------------------------------ 5 · key features
s = blank(prs)
heading(s, "Six features, one question", "03 · the product",
        "Every one of them built to answer “can I afford this now?”", "Gleb")
FEATS = [("01", "Safe-to-Spend limit", "A daily figure calculated after regular bills and savings goals."),
         ("02", "Reason tags", "Surfaces impulse, social and discount-driven spending patterns."),
         ("03", "Recurring charges", "Catches repeat payments and subscriptions before they are missed."),
         ("04", "Savings goals", "Plan toward future costs and watch progress against a target."),
         ("05", "Calendar alerts", "Links exams and festivals to the spending they bring with them."),
         ("06", "Insight dashboard", "Organises the financial picture and surfaces useful comparisons.")]
cw, ch = (W - 2 * M - 2 * 0.28) / 3, 1.76
for i, (n, t, b) in enumerate(FEATS):
    card(s, M + (cw + 0.28) * (i % 3), 2.34 + (ch + 0.26) * (i // 3), cw, ch, n, t, b)
footer(s)

# --------------------------------------------------------- 6 · front end
s = blank(prs)
heading(s, "Front end — the web app", "04 · how it is built",
        "React in the browser, shipping in three languages.", "Kintan")
rect(s, M, 2.30, 6.3, 3.5, MIST, PALE, 1.25, radius=0.10)
text(s, M + 0.34, 2.58, 5.6, 0.34, "WEB APPLICATION", 11, True, GREEN)
text(s, M + 0.34, 2.96, 5.6, 0.46, "React + TypeScript", 21, True, DARK)
for i, (k, v) in enumerate([("Styling", "Tailwind CSS"),
                            ("Charts", "Recharts"),
                            ("Languages", "i18next — 3 languages"),
                            ("Hosting", "Vercel")]):
    yy = 3.62 + i * 0.52
    text(s, M + 0.34, yy, 1.7, 0.30, k.upper(), 9.5, True, GREY)
    text(s, M + 2.10, yy - 0.04, 3.8, 0.34, v, 13.5, True, DARK)
rect(s, 7.35, 2.30, W - M - 7.35, 3.5, WHITE, PALE, 1.25, radius=0.10)
text(s, 7.69, 2.58, 4.6, 0.34, "WHY THREE LANGUAGES", 11, True, GREEN)
text(s, 7.69, 3.00, 4.9, 2.6,
     "Half this team does not speak the other half's first language.\n\n"
     "Neither do our users. Translation was not a feature we added at the end — "
     "it is a condition of the team that built it.",
     13.5, False, GREY, line_sp=1.22)
footer(s)

# ---------------------------------------------------------- 7 · back end
s = blank(prs)
heading(s, "Back end — one service, both platforms", "04 · how it is built",
        None, "Gleb")
flow = [("WEB APP", "React"), ("MOBILE APP", "Flutter")]
for i, (t, sub) in enumerate(flow):
    rect(s, M, 2.26 + i * 1.12, 2.9, 0.92, WHITE, PALE, 1.25, radius=0.14)
    text(s, M + 0.26, 2.44 + i * 1.12, 2.4, 0.30, t, 12.5, True, DARK)
    text(s, M + 0.26, 2.74 + i * 1.12, 2.4, 0.26, sub, 10.5, False, GREY)
text(s, 3.62, 2.72, 0.7, 0.4, "→", 24, True, GOLD, PP_ALIGN.CENTER)
text(s, 3.62, 3.84, 0.7, 0.4, "→", 24, True, GOLD, PP_ALIGN.CENTER)
rect(s, 4.40, 2.26, 3.5, 1.98, DARK, None, radius=0.12)
text(s, 4.66, 2.56, 3.0, 0.34, "API LAYER", 10.5, True, GOLD)
text(s, 4.66, 2.94, 3.0, 0.84, "Python\nFastAPI", 20, True, WHITE, line_sp=1.05)
text(s, 8.10, 2.72, 0.7, 0.4, "→", 24, True, GOLD, PP_ALIGN.CENTER)
rect(s, 8.86, 2.26, 3.85, 1.98, GREEN, None, radius=0.12)
text(s, 9.12, 2.56, 3.2, 0.34, "DATABASE", 10.5, True, PALE)
text(s, 9.12, 2.94, 3.2, 0.50, "TiDB", 20, True, WHITE)
text(s, 9.12, 3.52, 3.2, 0.30, "Deployed on Railway", 11, False, PALE)
for i, (v, l) in enumerate([("18", "API endpoints"), ("4", "database tables"),
                            ("<100ms", "core route response")]):
    stat(s, M + i * ((W - 2 * M - 2 * 0.3) / 3 + 0.3), 4.70,
         (W - 2 * M - 2 * 0.3) / 3, v, l, 1.06)
text(s, M, 6.02, W - 2 * M, 0.40,
     "The logic exists once, not twice — the website and the phone ask the same service the same questions.",
     13, False, GREY)
footer(s)

# ------------------------------------------------------------ 8 · mobile
s = blank(prs)
heading(s, "Mobile — works with no account, no signal", "04 · how it is built",
        None, "Vansh")
shots = [("01-dashboard.png", "Dashboard"), ("03-planner.png", "Planner"),
         ("07-achievements.png", "Achievements")]
for i, (fn, cap) in enumerate(shots):
    path = os.path.join(SHOTS, fn)
    if os.path.exists(path):
        cx = 1.95 + i * 2.05
        pic_fit(s, path, cx, 2.14, 1.62, 3.34)
        text(s, cx - 1.0, 5.56, 2.0, 0.26, cap, 10.5, True, GREY,
             PP_ALIGN.CENTER)
rect(s, 7.35, 2.14, W - M - 7.35, 3.36, MIST, PALE, 1.25, radius=0.10)
text(s, 7.69, 2.40, 4.6, 0.34, "FLUTTER / DART · ANDROID", 11, True, GREEN)
text(s, 7.69, 2.80, 4.9, 2.6,
     "No server. No account. No sign-up.\n\n"
     "Financial data never leaves the handset, and the app is fully usable "
     "offline.\n\n"
     "Receipts are read on-device — the photograph is never uploaded anywhere.",
     13, False, GREY, line_sp=1.20)
for i, (v, l) in enumerate([("23,436", "lines of Dart"), ("537", "tests passing"),
                            ("1,044", "translated strings")]):
    stat(s, M + i * ((6.3 - 2 * 0.24) / 3 + 0.24), 5.92,
         (6.3 - 2 * 0.24) / 3, v, l, 0.84)
footer(s, "Source: Cash Compass Technical Report")

# --------------------------------------------------- 9 · market research
s = blank(prs)
heading(s, "How we compare", "05 · market research",
        "Student-budgeting tools, by documented feature fit.", "Ismail")
if os.path.exists(COMPARE):
    pic_fit(s, COMPARE, 4.55, 2.22, 7.7, 3.95)
rect(s, 8.72, 2.22, W - M - 8.72, 4.00, MIST, PALE, 1.25, radius=0.10)
text(s, 9.00, 2.50, 3.5, 0.32, "WHERE WE DIFFER", 11, True, GREEN)
for i, (t, b) in enumerate([
        ("Student-first decision", "Safe-to-Spend answers “can I afford this now”, not “what am I worth”."),
        ("Planning, not tracking", "Goals, upcoming bills and a daily spendable figure."),
        ("Privacy-aware capture", "On-device receipt reading; offline-first; user confirms before saving.")]):
    yy = 2.94 + i * 1.08
    text(s, 9.00, yy, 3.5, 0.28, t, 12.5, True, DARK)
    text(s, 9.00, yy + 0.30, 3.5, 0.70, b, 10.5, False, GREY, line_sp=1.10)
footer(s, "Source: Team Progress & Research Report")

# ------------------------------------------------ 10 · economics & data
s = blank(prs)
heading(s, "The maths behind the number", "06 · economics & data",
        None, "Akshit  ·  Vlad")
text(s, M, 2.16, 6.4, 0.34, "THE CORE MODELS", 11, True, GREEN)
for i, (t, b) in enumerate([
        ("Survival calculator", "Income streams, fixed costs and upcoming bills reduced to one daily figure."),
        ("Social-event budgeting", "Tests the cost of a night out before the money is committed."),
        ("Loan-runway visualiser", "How long a lump sum lasts at the current burn rate.")]):
    yy = 2.58 + i * 1.02
    rect(s, M, yy, 6.4, 0.86, WHITE, PALE, 1.25, radius=0.14)
    text(s, M + 0.26, yy + 0.14, 5.9, 0.28, t, 12.5, True, DARK)
    text(s, M + 0.26, yy + 0.44, 5.9, 0.34, b, 10.5, False, GREY)
text(s, 7.45, 2.16, 5.3, 0.34, "AND ONE VERDICT", 11, True, GREEN)
ZONES = [("GREEN", "Comfortably inside the daily limit", RGBColor(0x1F, 0x7A, 0x52)),
         ("TIGHT", "Close to the limit — plan the rest of the week", GOLD),
         ("CRITICAL", "Over the limit — the app says so plainly", RGBColor(0x9B, 0x3A, 0x2F))]
for i, (z, b, c) in enumerate(ZONES):
    yy = 2.58 + i * 1.02
    rect(s, 7.45, yy, 5.26, 0.86, c, None, radius=0.14)
    text(s, 7.71, yy + 0.14, 4.7, 0.30, z, 13, True, WHITE)
    text(s, 7.71, yy + 0.46, 4.7, 0.30, b, 10.5, False, RGBColor(0xEC, 0xF5, 0xEF))
rect(s, M, 5.78, W - 2 * M, 0.84, DARK, None, radius=0.14)
text(s, M + 0.32, 6.02, W - 2 * M - 0.64, 0.40,
     "Five models in total — and every figure is derived live from the transaction data, never cached.",
     14, True, WHITE)
footer(s)

# ------------------------------------------------------ 11 · UI/UX design
s = blank(prs)
heading(s, "One identity, two platforms", "07 · UI/UX & design",
        None, "Meehika  ·  Simphiwe")
for i, (fn, cap) in enumerate([("00-auth.png", "Sign in"),
                               ("02-goals.png", "Goals"),
                               ("05-settings.png", "Settings")]):
    path = os.path.join(SHOTS, fn)
    if os.path.exists(path):
        cx = 2.00 + i * 2.10
        pic_fit(s, path, cx, 2.14, 1.66, 3.60)
        text(s, cx - 1.0, 5.86, 2.0, 0.26, cap, 10.5, True, GREY, PP_ALIGN.CENTER)
rect(s, 7.45, 2.14, W - M - 7.45, 3.62, MIST, PALE, 1.25, radius=0.10)
text(s, 7.75, 2.42, 4.6, 0.32, "DESIGN SYSTEM", 11, True, GREEN)
for i, (t, b) in enumerate([
        ("22 high-fidelity screens", "Figma, covering every state before a line of UI was written."),
        ("Capture → understand → decide", "The same three steps on both platforms."),
        ("Restraint on mobile", "A monochrome system so the numbers carry the page.")]):
    yy = 2.84 + i * 1.00
    text(s, 7.75, yy, 4.5, 0.28, t, 12.5, True, DARK)
    text(s, 7.75, yy + 0.30, 4.5, 0.60, b, 10.5, False, GREY, line_sp=1.10)
stat(s, 7.45, 6.00, (W - M - 7.45 - 0.24) / 2, "22", "Figma screens", 0.82)
stat(s, 7.45 + (W - M - 7.45 - 0.24) / 2 + 0.24, 6.00,
     (W - M - 7.45 - 0.24) / 2, "16", "workspace widgets", 0.82)
footer(s)

# ------------------------------------------------------------- 12 · close
s = blank(prs)
rect(s, 0, 0, W, H, DARK, None, shape=MSO_SHAPE.RECTANGLE)
rect(s, 0, 0, 0.26, H, GREEN, None, shape=MSO_SHAPE.RECTANGLE)
text(s, 1.15, 1.30, 9.0, 0.30, "THANK YOU", 12, True, GOLD)
text(s, 1.15, 1.74, 10.4, 1.30, "Two countries. One product.", 44, True, WHITE)
text(s, 1.15, 3.06, 9.6, 0.40,
     "Built in parallel across Russia and India — and shipping today.", 16,
     False, PALE)
rect(s, 1.15, 3.78, 6.4, 0.86, RGBColor(0x12, 0x55, 0x40), None, radius=0.14)
text(s, 1.45, 3.94, 5.9, 0.30, "PROJECT REPOSITORY", 10, True, GOLD)
text(s, 1.45, 4.22, 5.9, 0.30, "github.com/Vansh-kap-98/cash-compass", 13.5,
     True, WHITE)
allp = [k for k, _, _ in INDIA] + [k for k, _, _ in RUSSIA]
for i, k in enumerate(allp):
    slot = 0.78
    slide_x = 1.15 + i * slot
    s.shapes.add_picture(os.path.join(AV, k + ".png"), Inches(slide_x),
                         Inches(5.30), Inches(0.66), Inches(0.66))
text(s, 1.15, 6.18, 8.0, 0.30, "PENNY PILOTS  •  NINE STUDENTS", 10, True,
     RGBColor(0x7F, 0xA8, 0x95))
pic_fit(s, LOGO, W - 2.9, 2.20, 3.3, 3.3)

prs.save(OUT)
print("wrote %s (%.0f KB, %d slides)" % (OUT, os.path.getsize(OUT) / 1024,
                                         len(prs.slides.__iter__.__self__._sldIdLst)))
