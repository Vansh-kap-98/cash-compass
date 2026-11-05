"""Builds the Cash Compass technical report PDF.

Design mirrors the app itself: monochrome, hairline-bordered surfaces, one
typeface. Re-run after changing the content blocks below or refreshing the
screenshots in docs/pdf-assets/.

    python docs/build_report_pdf.py
"""

import os

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    Image,
    KeepTogether,
    NextPageTemplate,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
)

HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.join(HERE, "pdf-assets")
OUT = os.path.join(HERE, "Cash-Compass-Technical-Report.pdf")

# ---------------------------------------------------------------- palette
# Transcribed from mobile/lib/app/theme/app_colors.dart so the document and
# the product it describes use one palette.
INK = colors.HexColor("#000000")
SURFACE = colors.HexColor("#FFFFFF")
INK_SECONDARY = colors.HexColor("#4A4A4A")
HAIRLINE = colors.HexColor("#E0E0E0")
SUBTLE = colors.HexColor("#F5F5F5")
DISABLED = colors.HexColor("#9E9E9E")

PAGE_W, PAGE_H = A4
MARGIN = 18 * mm

# Helvetica rather than the app's Manrope: Manrope is fetched at runtime by
# google_fonts and is not vendored in the repo, so there is no TTF to embed.
# Helvetica is metrically clean and ships with every PDF reader.
BASE = "Helvetica"
BOLD = "Helvetica-Bold"


def styles():
    s = getSampleStyleSheet()
    s.add(ParagraphStyle(
        "CoverTitle", fontName=BOLD, fontSize=40, leading=44,
        textColor=SURFACE, spaceAfter=0,
    ))
    s.add(ParagraphStyle(
        "CoverSub", fontName=BASE, fontSize=13, leading=19,
        textColor=colors.HexColor("#C8C8C8"),
    ))
    s.add(ParagraphStyle(
        "CoverMeta", fontName=BASE, fontSize=9.5, leading=15,
        textColor=colors.HexColor("#8A8A8A"),
    ))
    s.add(ParagraphStyle(
        "H1", fontName=BOLD, fontSize=21, leading=25, textColor=INK,
        spaceBefore=2, spaceAfter=3,
    ))
    s.add(ParagraphStyle(
        "H2", fontName=BOLD, fontSize=13, leading=17, textColor=INK,
        spaceBefore=13, spaceAfter=5,
    ))
    s.add(ParagraphStyle(
        "H3", fontName=BOLD, fontSize=10.5, leading=14, textColor=INK,
        spaceBefore=9, spaceAfter=3,
    ))
    s.add(ParagraphStyle(
        "Body", fontName=BASE, fontSize=9.6, leading=14.4,
        textColor=INK_SECONDARY, alignment=TA_JUSTIFY, spaceAfter=6,
    ))
    s.add(ParagraphStyle(
        "Bul", parent=s["Body"], leftIndent=11, bulletIndent=2,
        spaceAfter=3, alignment=0,
    ))
    s.add(ParagraphStyle(
        "Caption", fontName=BASE, fontSize=7.8, leading=10.5,
        textColor=DISABLED, alignment=TA_CENTER, spaceBefore=4,
    ))
    s.add(ParagraphStyle(
        "Kicker", fontName=BOLD, fontSize=7.8, leading=11,
        textColor=DISABLED, spaceAfter=2,
    ))
    s.add(ParagraphStyle(
        "Cell", fontName=BASE, fontSize=8.4, leading=11.6, textColor=INK_SECONDARY,
    ))
    s.add(ParagraphStyle(
        "CellB", fontName=BOLD, fontSize=8.4, leading=11.6, textColor=INK,
    ))
    s.add(ParagraphStyle(
        "Note", fontName=BASE, fontSize=8.6, leading=12.6,
        textColor=INK_SECONDARY,
    ))
    return s


S = styles()


def cover_page(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(INK)
    canvas.rect(0, PAGE_H * 0.42, PAGE_W, PAGE_H * 0.58, stroke=0, fill=1)
    # A compass mark, drawn rather than imported: one circle, one needle.
    cx, cy, r = PAGE_W - MARGIN - 26, PAGE_H - MARGIN - 26, 15
    canvas.setStrokeColor(SURFACE)
    canvas.setLineWidth(1.6)
    canvas.circle(cx, cy, r, stroke=1, fill=0)
    canvas.setLineWidth(2.2)
    canvas.line(cx - 5, cy - 5, cx + 5, cy + 5)
    canvas.restoreState()
    footer(canvas, doc, on_dark=False)


def footer(canvas, doc, on_dark=False):
    canvas.saveState()
    canvas.setFont(BASE, 7.5)
    canvas.setFillColor(DISABLED)
    canvas.drawString(MARGIN, 11 * mm, "Cash Compass - Technical Report")
    canvas.drawRightString(PAGE_W - MARGIN, 11 * mm, "Page %d" % doc.page)
    canvas.setStrokeColor(HAIRLINE)
    canvas.setLineWidth(0.5)
    canvas.line(MARGIN, 14.5 * mm, PAGE_W - MARGIN, 14.5 * mm)
    canvas.restoreState()


def content_page(canvas, doc):
    footer(canvas, doc)


def rule():
    """The black accent bar that opens each section."""
    t = Table([[""]], colWidths=[26 * mm], rowHeights=[2.6])
    t.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, -1), INK)]))
    return t


def section(title, kicker=None):
    out = []
    if kicker:
        out.append(Paragraph(kicker.upper(), S["Kicker"]))
    out.append(rule())
    out.append(Spacer(1, 6))
    out.append(Paragraph(title, S["H1"]))
    out.append(Spacer(1, 4))
    return out


def body(text):
    return Paragraph(text, S["Body"])


def bullets(items):
    return [Paragraph(i, S["Bul"], bulletText="•") for i in items]


def data_table(rows, widths, header=True):
    """Hairline table, ink header - matches the app's card treatment."""
    data = []
    for r_i, row in enumerate(rows):
        style = S["CellB"] if (header and r_i == 0) else S["Cell"]
        data.append([Paragraph(str(c), style) for c in row])

    t = Table(data, colWidths=widths, repeatRows=1 if header else 0)
    cmds = [
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ("LEFTPADDING", (0, 0), (-1, -1), 7),
        ("RIGHTPADDING", (0, 0), (-1, -1), 7),
        ("BOX", (0, 0), (-1, -1), 0.9, INK),
        ("LINEBELOW", (0, 0), (-1, -2), 0.4, HAIRLINE),
    ]
    if header:
        cmds += [
            ("BACKGROUND", (0, 0), (-1, 0), SUBTLE),
            ("LINEBELOW", (0, 0), (-1, 0), 0.9, INK),
        ]
    t.setStyle(TableStyle(cmds))
    return t


def metric_row(items):
    """Stat tiles, as on the dashboard: big figure over a small label."""
    cells = []
    for value, label in items:
        inner = Table(
            [[Paragraph('<font size="17"><b>%s</b></font>' % value,
                        ParagraphStyle("m", fontName=BOLD, fontSize=17,
                                       leading=20, textColor=INK))],
             [Paragraph(label, ParagraphStyle("l", fontName=BASE, fontSize=7.4,
                                              leading=10, textColor=DISABLED))]],
            colWidths=[(PAGE_W - 2 * MARGIN) / len(items) - 4],
        )
        inner.setStyle(TableStyle([
            ("TOPPADDING", (0, 0), (-1, -1), 2),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 2),
            ("LEFTPADDING", (0, 0), (-1, -1), 8),
            ("RIGHTPADDING", (0, 0), (-1, -1), 4),
            ("BOX", (0, 0), (-1, -1), 0.9, INK),
        ]))
        cells.append(inner)

    t = Table([cells], colWidths=[(PAGE_W - 2 * MARGIN) / len(items)] * len(items))
    t.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 0),
        ("RIGHTPADDING", (0, 0), (-1, -1), 4),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
    ]))
    return t


def shot(name, w_mm):
    """A screenshot, boxed in ink to match the app's outlined surfaces."""
    path = os.path.join(ASSETS, name)
    w = w_mm * mm
    h = w * (2400.0 / 1080.0)
    img = Image(path, width=w, height=h)
    t = Table([[img]], colWidths=[w + 4], rowHeights=[h + 4])
    t.setStyle(TableStyle([
        ("BOX", (0, 0), (-1, -1), 0.9, INK),
        ("ALIGN", (0, 0), (-1, -1), "CENTER"),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 2),
        ("RIGHTPADDING", (0, 0), (-1, -1), 2),
        ("TOPPADDING", (0, 0), (-1, -1), 2),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 2),
    ]))
    return t


def gallery(entries, w_mm=44):
    """A row of screenshots with captions underneath."""
    imgs, caps = [], []
    for name, caption in entries:
        imgs.append(shot(name, w_mm))
        caps.append(Paragraph(caption, S["Caption"]))
    col = (PAGE_W - 2 * MARGIN) / len(entries)
    t = Table([imgs, caps], colWidths=[col] * len(entries))
    t.setStyle(TableStyle([
        ("ALIGN", (0, 0), (-1, -1), "CENTER"),
        ("VALIGN", (0, 0), (-1, 0), "TOP"),
        ("TOPPADDING", (0, 0), (-1, -1), 0),
        ("BOTTOMPADDING", (0, 0), (-1, 0), 2),
    ]))
    # Captions must never be orphaned from the screenshots they label.
    return KeepTogether(t)


def callout(title, text):
    inner = [
        Paragraph(title, S["H3"]),
        Paragraph(text, S["Note"]),
    ]
    t = Table([[inner]], colWidths=[PAGE_W - 2 * MARGIN])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), SUBTLE),
        ("BOX", (0, 0), (-1, -1), 0.9, INK),
        ("LEFTPADDING", (0, 0), (-1, -1), 10),
        ("RIGHTPADDING", (0, 0), (-1, -1), 10),
        ("TOPPADDING", (0, 0), (-1, -1), 2),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
    ]))
    return t


# ================================================================= content
story = []

# ---- cover
story.append(Spacer(1, 62 * mm))
story.append(Paragraph("Cash&nbsp;Compass", S["CoverTitle"]))
story.append(Spacer(1, 5))
story.append(Paragraph(
    "A privacy-first personal finance companion for Android.<br/>"
    "Built in Flutter. Everything on device.", S["CoverSub"]))
story.append(Spacer(1, 70 * mm))
story.append(Paragraph("TECHNICAL REPORT", ParagraphStyle(
    "ct", fontName=BOLD, fontSize=9, leading=13, textColor=INK)))
story.append(Spacer(1, 3))
story.append(Paragraph(
    "Version 0.2.0 (build 9) &nbsp;&middot;&nbsp; Android, minSdk 24 / targetSdk 36<br/>"
    "Vansh &nbsp;&middot;&nbsp; Kintan &nbsp;&middot;&nbsp; Athena "
    "&nbsp;&middot;&nbsp; Akshit &nbsp;&middot;&nbsp; Meehika",
    S["CoverMeta"]))

story.append(NextPageTemplate("content"))
story.append(PageBreak())

# ---- 1. overview
story += section("What the app does", "01 - Overview")
story.append(body(
    "Cash Compass is an Android application for tracking day-to-day money: what came in, "
    "what went out, what is safe to spend today, and how close each savings goal is. It is "
    "built for students and early-career users, where the interesting question is rarely "
    "\"what is my net worth\" and almost always \"can I afford this right now\"."))
story.append(body(
    "The defining constraint is that <b>there is no server</b>. No account is required, no "
    "financial record leaves the handset, and the app is fully usable with the network off. "
    "Two things reach the internet at all: the daily exchange-rate lookup and the webfont on "
    "first launch. Receipt scanning, which is the heaviest feature in the product, runs its "
    "optical character recognition entirely on-device."))

story.append(Spacer(1, 4))
story.append(metric_row([
    ("23,436", "LINES OF DART"),
    ("537", "TESTS PASSING"),
    ("1,044", "TRANSLATED STRINGS"),
    ("16", "WORKSPACE WIDGETS"),
]))
story.append(Spacer(1, 8))

story.append(Paragraph("At a glance", S["H2"]))
story.append(data_table([
    ["Area", "Detail"],
    ["Platform", "Android only. Flutter / Dart, Material 3, minSdk 24, targetSdk 36."],
    ["Architecture", "Three layers - pure-Dart logic, ChangeNotifier state, widget tree - "
                     "bridged by a presenter layer that turns rules into words."],
    ["Persistence", "shared_preferences, one JSON blob per domain, debounced writes "
                    "flushed on app pause."],
    ["Currencies", "USD, INR and RUB, with live rates. All amounts stored in USD and "
                   "converted only at the display boundary."],
    ["Languages", "English and Russian, complete - 522 keys each, including plural forms "
                  "that decline correctly in Russian."],
    ["Offline", "Complete. Demo mode needs no account and no connection."],
], [30 * mm, PAGE_W - 2 * MARGIN - 30 * mm]))

story.append(PageBreak())

# ---- 2. the app itself
story += section("The product, screen by screen", "02 - Feature tour")
story.append(body(
    "Five tabs carry the day-to-day work; two further screens - Financial Tips and "
    "Achievements - open from Settings. Every screenshot below is from the current build "
    "running on an Android emulator."))
story.append(Spacer(1, 4))

story.append(gallery([
    ("00-auth.png", "<b>Sign in</b><br/>Demo mode needs no account"),
    ("01-dashboard.png", "<b>Dashboard</b><br/>Balance, stats, budget window"),
    ("08-quick-actions.png", "<b>Quick actions</b><br/>Five ways to add data"),
]))
story.append(Spacer(1, 9))

story.append(Paragraph("Dashboard", S["H3"]))
story.append(body(
    "The dashboard is the app's centre of gravity. A manual balance snapshot drives "
    "everything below it: four derived statistics, a budgeting window that spreads the "
    "remaining balance over a chosen date range, then a stack of cards - smart insights, "
    "spending pattern, daily planner, location guidance, subscriptions, event calendar and "
    "recent transactions. Every figure on the page is recomputed from the live transaction "
    "list, never cached."))

story.append(Paragraph("The design language", S["H3"]))
story.append(body(
    "The interface is deliberately monochrome: black, white and three greys, one geometric "
    "typeface, and a single reserved red used only to confirm a destructive action. Every "
    "container - card, input, tile, chip - carries a slim ink border, while the rules drawn "
    "<i>inside</i> a container stay pale. That distinction is what stops a card full of rows "
    "reading as a table, and it is enforced by its own test suite rather than by eye. Colour "
    "emoji are excluded for the same reason: they render in the platform's own colour font "
    "whatever the styling says, so category marks are drawn as line icons instead."))

story.append(PageBreak())
story += section("Saving, planning, arranging", "02 - Feature tour, continued")
story.append(Spacer(1, 2))
story.append(gallery([
    ("02-goals.png", "<b>Goals</b><br/>Savings targets and trends"),
    ("03-planner.png", "<b>Planner</b><br/>Survival calculator, runway"),
    ("04-workspace.png", "<b>Workspace</b><br/>16 arrangeable widgets"),
]))
story.append(Spacer(1, 9))

story.append(Paragraph("Goals, Planner and Workspace", S["H3"]))
story.append(body(
    "<b>Goals</b> holds savings targets with progress rings, a six-month income-versus-expense "
    "chart and narrative guidance derived from the user's two largest spending categories. "
    "<b>Planner</b> is the forward-looking half: a survival calculator that turns income "
    "streams, fixed costs and upcoming bills into a daily spendable figure and a Green / "
    "Tight / Critical verdict, plus social-event budgeting and a loan runway visualiser. "
    "<b>Workspace</b> is a free-form canvas of sixteen widget types the user arranges, "
    "resizes and reorders; the layout persists across launches."))

story.append(body(
    "All three are empty in these captures because demo mode starts from a clean slate, which "
    "is itself a deliberate piece of the design: every empty state says what it is waiting for "
    "rather than simply reporting nothing, and no screen invents placeholder data to look "
    "busy. An earlier build did fabricate a sample subscription when the user had no "
    "transactions, and it read as a bug the moment the first real entry made it disappear."))

story.append(PageBreak())

story += section("Learning and motivation", "02 - Feature tour, continued")
story.append(Spacer(1, 2))
story.append(gallery([
    ("06-financial-tips.png", "<b>Financial Tips</b><br/>18 cards, 5 categories"),
    ("07-achievements.png", "<b>Achievements</b><br/>14 badges, 4 categories"),
    ("05-settings.png", "<b>Settings</b><br/>Language, currency, type size"),
]))
story.append(Spacer(1, 9))

story.append(body(
    "Two features exist to keep people coming back rather than to compute anything. "
    "<b>Financial Tips</b> is a library of eighteen short money-management cards grouped "
    "into five themes, with read-tracking so the list remembers where the user got to. "
    "<b>Achievements</b> awards fourteen badges across savings, budget control, habit "
    "streaks and a small special category - unlocked by real behaviour such as reaching a "
    "goal, categorising expenses consistently for a fortnight, or finishing a month under "
    "budget."))
story.append(body(
    "Both are deliberately content-free in code: the modules hold only stable identifiers "
    "and category groupings, while every title and description lives in the localisation "
    "catalogue. Wording can change, and Russian can differ structurally from English, "
    "without either module being touched."))

story.append(Spacer(1, 6))
story.append(callout(
    "Receipt scanning",
    "The most technically involved feature does not have a tab of its own. From the quick-action "
    "sheet the user can photograph a receipt or pick several from the gallery at once. Text "
    "recognition runs on-device via ML Kit; a parser then extracts the merchant, total, currency "
    "and line items, cross-checks the total against the receipt's own arithmetic, and hands back "
    "a confidence rating. Nothing is written until the user confirms it on a review screen."))

story.append(PageBreak())

# ---- 3. architecture
story += section("How it is put together", "03 - Architecture")
story.append(body(
    "The codebase is organised in three layers with a hard rule between them, which is what "
    "makes the interesting half of the product testable without a device."))

story.append(data_table([
    ["Layer", "Contents", "Rule"],
    ["<b>logic/</b>", "9 pure-Dart modules: budget maths, insights, subscription detection, "
                      "receipt parsing, badges, literacy cards, events, student planner, "
                      "batch queue.",
     "No Flutter imports, no display strings, no clock. Decides what is true."],
    ["<b>state/</b>", "11 ChangeNotifier providers - finance, currency, planner, workspace, "
                      "budgets, achievements, literacy, locale, theme, auth, student planner.",
     "Owns mutation and persistence. One source of truth per domain."],
    ["<b>screens/ + widgets/</b>", "5 tabs, 4 pushed screens, a shared design-system "
                                   "component set.",
     "Renders. Holds no business rules."],
    ["<b>l10n/presenters.dart</b>", "The bridge. Turns a logic-layer descriptor into a "
                                    "sentence in the active language.",
     "The reason one rule can read correctly in two languages."],
], [26 * mm, 74 * mm, PAGE_W - 2 * MARGIN - 100 * mm]))

story.append(Paragraph("Why the logic layer is kept Flutter-free", S["H2"]))
story.append(body(
    "A rule expressed as a widget can only be tested by building a widget tree. A rule "
    "expressed as a function over plain data can be tested with a list and an expectation. "
    "The receipt parser is the clearest case: it takes lines of already-recognised text and "
    "returns a structured result, so the whole of its behaviour is exercised against fixture "
    "text with no camera, no emulator and no native dependency anywhere in the test."))

story.append(Paragraph("Start-up and persistence", S["H2"]))
story.append(body(
    "Every store hydrates from disk <i>before</i> the first frame, so the interface never "
    "flashes zeroes over real data. Currency is the single exception and is deliberately not "
    "awaited, because it may reach the network and the app is perfectly usable on cached or "
    "fallback rates."))
story += bullets([
    "Writes are <b>debounced by 500&nbsp;ms</b>. Encoding the finance blob costs roughly nine "
    "milliseconds, which is over half a frame at 60&nbsp;fps, on the UI thread - so a burst of "
    "keystrokes must collapse into one write.",
    "The app <b>flushes every store on pause, detach and hide</b>, because Android may kill a "
    "backgrounded process at any moment and a debounce window is exactly when data would be lost.",
    "Aggregates are computed <b>once per mutation</b>, not once per widget build. Each dashboard "
    "card used to walk the whole transaction list; a single build read four of them.",
])

story.append(PageBreak())

# ---- 4. engineering detail
story += section("Four problems worth describing", "04 - Engineering detail")

story.append(Paragraph("1. Money was being quantised on the way in", S["H2"]))
story.append(body(
    "Amounts are stored in USD and converted for display. Originally both directions rounded "
    "to two decimals - and the inbound direction is the one that gets <i>persisted</i>. One US "
    "cent is nearly a rupee, so storing a rounded value quantised the underlying figure, and "
    "because the error was a consistent bias rather than noise it accumulated instead of "
    "cancelling out. Entering 50,000 rupees returned 49,999.83; one rupee round-tripped to "
    "0.83, a seventeen per cent error."))
story.append(body(
    "The fix is one line in each direction: conversion into storage is never rounded, and "
    "rounding happens only where a human reads the number. The regression test is written as a "
    "<i>round trip</i> - enter, store, read back - because a test that only checks the "
    "conversion arithmetic passes happily while the round trip is broken."))

story.append(Paragraph("2. Reading a total off a receipt", S["H2"]))
story.append(body(
    "A receipt usually states its total more than once: as a labelled line, as cash minus "
    "change, and implicitly as the sum of its items. The parser ranks labelled candidates by "
    "keyword tier and position, then tries to corroborate the winner against the other two "
    "signals. Where the label disagrees with cash minus change, the arithmetic wins - it is "
    "arithmetic the receipt performed itself - but the label is still reported, so a user "
    "holding the paper can settle it."))
story += bullets([
    "Lines containing cash, change, tender or a card ending are excluded from ever being read "
    "as the total, before ranking <i>and</i> before the largest-number fallback.",
    "Item extraction is deliberately conservative: over-collecting would poison the item-sum "
    "cross-check, and one fewer signal is better than a wrong one.",
    "A sideways photograph is retried at 90, 270 and 180 degrees. Recognition returns almost "
    "nothing on a rotated image, and that is a far more common real-world failure than genuinely "
    "unreadable print.",
])

story.append(Paragraph("3. Batch scanning without killing the process", S["H2"]))
story.append(body(
    "Several receipts can be processed at once, three at a time. The bound is not arbitrary: "
    "fully sequential leaves the user watching a spinner, while fully parallel holds ten decoded "
    "full-resolution bitmaps in memory simultaneously, which is how a mid-range handset gets its "
    "process killed. Dates come from EXIF where the photograph carries them, so a receipt shot on "
    "Tuesday is dated Tuesday; duplicates are flagged, failed rows never block readable ones, and "
    "nothing is written until the batch is confirmed."))

story.append(Paragraph("4. One typeface, two alphabets", S["H2"]))
story.append(body(
    "The Russian translation shipped in an earlier build rendering in whatever substitute font "
    "the handset chose, because the typeface in use carried no Cyrillic glyphs at all. Moving to "
    "Manrope fixed it. Counted phrases decline properly - one, two and five days take different "
    "noun endings in Russian - and amounts follow the currency rather than the interface "
    "language, so rupees keep Indian digit grouping whichever language the app is read in."))

story.append(PageBreak())

# ---- 5. quality
story += section("Testing, security and release", "05 - Quality")

story.append(Paragraph("Test strategy", S["H2"]))
story.append(body(
    "537 tests pass on the current build. The suite is deliberately split by what it is "
    "asking, because the two questions fail in different ways."))
story.append(data_table([
    ["Suite", "Asks", "Examples"],
    ["Logic", "Is the rule correct?",
     "Receipt parser fixtures, budget maths, subscription cadence, student planner, "
     "currency round trip."],
    ["Widget", "Does it render without breaking?",
     "All 16 workspace widgets at three sizes, every tab in both languages, at 1.3x text scale."],
    ["Design", "Is it legible?",
     "Contrast of every control state, no colour emoji, container borders, typography ramp."],
    ["Performance", "Is it fast enough?",
     "Derived-cost benchmarks at 200, 1,000 and 5,000 transactions; persistence write counting."],
], [22 * mm, 34 * mm, PAGE_W - 2 * MARGIN - 56 * mm]))

story.append(body(
    "The widget sweep exists because larger type is the most reliable way to break a layout. "
    "Running every screen in Russian at 1.3x text scale catches overflow that no amount of "
    "looking at an English phone at default size ever will."))

story.append(Paragraph("Security and data handling", S["H2"]))
story += bullets([
    "<b>Session tokens sit in the Android Keystore.</b> The default storage writes access and "
    "refresh tokens as plaintext into shared preferences - readable on a rooted device and "
    "included in an unencrypted backup. Any token left behind by an older build is deleted on "
    "upgrade rather than migrated: a token that has been sitting in a world-backupable file "
    "should not be treated as trustworthy.",
    "<b>Logging is stripped from release builds.</b> Debug printing is not removed automatically "
    "and is readable over a cable; for a finance app that means amounts, merchants and email "
    "addresses. Messages are passed as closures so even the string interpolation never runs, and "
    "failures log an exception's type rather than its text, because exception messages here would "
    "carry the stored finance data or the email being signed in.",
    "<b>Cleartext traffic is denied at the OS level</b>, rather than relying on every call site "
    "happening to use a secure URL.",
    "<b>Backup is disabled</b> and receipt images stay in app-private storage.",
    "<b>Signing keys are kept out of the repository</b>, with no default that would silently "
    "commit a password. Release builds are obfuscated and shrunk.",
])

story.append(Paragraph("Release", S["H2"]))
story.append(body(
    "Current build is <b>v0.2.0 build 9</b>, distributed as signed per-architecture APKs of "
    "roughly 31 to 37&nbsp;MB, with install instructions and SHA-256 checksums alongside them."))

story.append(PageBreak())

# ---- 6. team
story += section("Who built what", "06 - Team")
story.append(callout(
    "Read this section before circulating",
    "The split below was drafted as a starting point, not recorded from the project history. "
    "Please correct it against what each person actually did before this document goes to anyone "
    "else - the rest of the report is drawn from the codebase and is accurate as written."))
story.append(Spacer(1, 7))

story.append(data_table([
    ["Member", "Focus", "Contribution"],
    ["<b>Vansh</b>", "Architecture and state",
     "Set the three-layer structure and the rule that the logic layer stays free of Flutter. "
     "Built the finance store and its derived aggregates, the debounced persistence and "
     "lifecycle flush, and the currency provider - including the storage-rounding fix. Owned "
     "the release pipeline: signing, shrinking, obfuscation and APK distribution."],
    ["<b>Kintan</b>", "Design system and UI",
     "Led the monochrome redesign: the palette, the single type ramp, and the component set of "
     "cards, buttons, progress rings, list rows and icon tiles. Built the animated bottom "
     "navigation and the decorative backdrop, and drove the contrast and text-scale work that "
     "keeps the interface legible at 1.3x."],
    ["<b>Athena</b>", "Receipt pipeline",
     "Built the receipt parser end to end - keyword tiering, payment-line exclusion, the cash-"
     "minus-change and item-sum cross-checks, currency identification and the confidence model. "
     "Added the rotation retry and the bounded-concurrency batch queue with EXIF dating and "
     "duplicate flagging."],
    ["<b>Akshit</b>", "Planner and workspace",
     "Built the survival calculator, the Green / Tight / Critical zone model, social-event "
     "budgeting and the loan runway visualiser. Implemented the workspace canvas with its sixteen "
     "widget types, resizing, reordering and layout persistence."],
    ["<b>Meehika</b>", "Localisation, engagement, QA",
     "Delivered the complete Russian translation including plural declension, and the presenter "
     "layer that separates rules from wording. Built Financial Tips and Achievements with their "
     "read-tracking and unlock rules, and owned the widget sweep that runs every screen in both "
     "languages at enlarged text."],
], [20 * mm, 27 * mm, PAGE_W - 2 * MARGIN - 47 * mm]))

story.append(Paragraph("Shared practice", S["H2"]))
story += bullets([
    "Changes reach the main branch through reviewed pull requests from personal forks.",
    "Analyzer and the full test suite must pass before a review is requested, and behaviour "
    "changes are reflected in the specification in the same change.",
    "The feature-status document is updated in the same change that alters what works, on the "
    "principle that a status document which lags the code is worse than none, because people "
    "trust it.",
])

story.append(PageBreak())

# ---- 7. honest limits
story += section("Known gaps and what comes next", "07 - Roadmap")
story.append(body(
    "Stated plainly, because a report that lists only what works is not much use to whoever "
    "picks the project up next."))

story.append(data_table([
    ["Gap", "Status", "Why it matters"],
    ["Transactions cannot be edited or deleted", "Not started",
     "The most visible gap, and more pressing since batch scanning landed: a batch can write ten "
     "rows at once and the only way to remove a wrong one is a full reset. Highest priority."],
    ["Goals and budget categories cannot be deleted", "Not started", "Same shape as above."],
    ["No backend, no sync, no recovery", "Deferred by decision",
     "All data is device-local. Clearing app data loses everything, and there is no multi-device "
     "story. Accounts are written but unconfigured."],
    ["Fixed liabilities", "Storage key only", "Reserved, with nothing built behind it."],
    ["iOS", "Not started", "Android only; there is no iOS project in the repository."],
    ["Continuous integration", "Not started",
     "Analyzer, tests and builds all run locally, so the release checks depend on someone "
     "remembering to run them."],
], [40 * mm, 24 * mm, PAGE_W - 2 * MARGIN - 64 * mm]))

story.append(Paragraph("Next", S["H2"]))
story += bullets([
    "Transaction edit and delete, routed through the same persistence path so every derived "
    "figure stays correct.",
    "Continuous integration, so the analyzer and the suite stop being a matter of discipline.",
    "A decision on the backend - finishing the hosted-account path or building a service - after "
    "which sync and recovery become possible.",
])

story.append(Spacer(1, 12))
story.append(rule())
story.append(Spacer(1, 5))
story.append(Paragraph(
    "Cash Compass v0.2.0 build 9. Figures in this report were taken from the codebase and the "
    "passing test suite at the time of writing; screenshots are from the current build running "
    "on an Android emulator.",
    S["Caption"]))


# ================================================================== build
def build():
    doc = BaseDocTemplate(
        OUT, pagesize=A4,
        leftMargin=MARGIN, rightMargin=MARGIN,
        topMargin=MARGIN, bottomMargin=22 * mm,
        title="Cash Compass - Technical Report",
        author="Vansh, Kintan, Athena, Akshit, Meehika",
        subject="Android application technical report",
    )
    frame = Frame(MARGIN, 22 * mm, PAGE_W - 2 * MARGIN,
                  PAGE_H - MARGIN - 22 * mm, id="f")
    doc.addPageTemplates([
        PageTemplate(id="cover", frames=[frame], onPage=cover_page),
        PageTemplate(id="content", frames=[frame], onPage=content_page),
    ])
    doc.build(story)
    print("wrote %s (%.1f KB)" % (OUT, os.path.getsize(OUT) / 1024.0))


if __name__ == "__main__":
    build()
