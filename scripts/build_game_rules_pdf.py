from __future__ import annotations

from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import (
    Flowable,
    KeepTogether,
    ListFlowable,
    ListItem,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "output" / "pdf" / "car-wash-rush-game-rules-and-mechanics.pdf"

BLUE = colors.HexColor("#1F6FEB")
DARK = colors.HexColor("#172033")
MUTED = colors.HexColor("#5D667A")
LIGHT_BLUE = colors.HexColor("#EAF3FF")
LIGHT_GRAY = colors.HexColor("#F3F5F8")
BORDER = colors.HexColor("#CFD7E3")
GREEN = colors.HexColor("#1F8A4C")
ORANGE = colors.HexColor("#B65C00")


class Rule(Flowable):
    def __init__(self, color=BORDER, thickness=0.7, width=None):
        super().__init__()
        self.color = color
        self.thickness = thickness
        self.width = width
        self.height = 8

    def wrap(self, availWidth, availHeight):
        self._availWidth = availWidth
        return availWidth, self.height

    def draw(self):
        self.canv.setStrokeColor(self.color)
        self.canv.setLineWidth(self.thickness)
        width = self.width or self._availWidth
        self.canv.line(0, 4, width, 4)


def make_styles():
    base = getSampleStyleSheet()
    styles = {
        "Title": ParagraphStyle(
            "Title",
            parent=base["Title"],
            fontName="Helvetica-Bold",
            fontSize=28,
            leading=32,
            textColor=DARK,
            alignment=TA_CENTER,
            spaceAfter=8,
        ),
        "Subtitle": ParagraphStyle(
            "Subtitle",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=12,
            leading=16,
            textColor=MUTED,
            alignment=TA_CENTER,
            spaceAfter=22,
        ),
        "H1": ParagraphStyle(
            "H1",
            parent=base["Heading1"],
            fontName="Helvetica-Bold",
            fontSize=17,
            leading=21,
            textColor=BLUE,
            spaceBefore=16,
            spaceAfter=8,
            keepWithNext=True,
        ),
        "H2": ParagraphStyle(
            "H2",
            parent=base["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=12.5,
            leading=16,
            textColor=DARK,
            spaceBefore=10,
            spaceAfter=5,
            keepWithNext=True,
        ),
        "Body": ParagraphStyle(
            "Body",
            parent=base["BodyText"],
            fontName="Helvetica",
            fontSize=9.6,
            leading=13.2,
            textColor=DARK,
            spaceAfter=6,
        ),
        "Small": ParagraphStyle(
            "Small",
            parent=base["BodyText"],
            fontName="Helvetica",
            fontSize=8.4,
            leading=11.2,
            textColor=MUTED,
            spaceAfter=4,
        ),
        "TableHeader": ParagraphStyle(
            "TableHeader",
            parent=base["BodyText"],
            fontName="Helvetica-Bold",
            fontSize=8.3,
            leading=10,
            textColor=DARK,
        ),
        "Cell": ParagraphStyle(
            "Cell",
            parent=base["BodyText"],
            fontName="Helvetica",
            fontSize=8.1,
            leading=10.3,
            textColor=DARK,
        ),
        "CellBold": ParagraphStyle(
            "CellBold",
            parent=base["BodyText"],
            fontName="Helvetica-Bold",
            fontSize=8.1,
            leading=10.3,
            textColor=DARK,
        ),
        "Callout": ParagraphStyle(
            "Callout",
            parent=base["BodyText"],
            fontName="Helvetica",
            fontSize=9.2,
            leading=12.2,
            textColor=DARK,
            leftIndent=8,
            rightIndent=8,
            spaceBefore=4,
            spaceAfter=4,
        ),
    }
    return styles


def p(text: str, style="Body"):
    return Paragraph(text, STYLES[style])


def bullets(items: list[str]):
    return ListFlowable(
        [ListItem(p(item), leftIndent=14) for item in items],
        bulletType="bullet",
        start="circle",
        leftIndent=16,
        bulletFontName="Helvetica",
        bulletFontSize=6,
    )


def numbered(items: list[str]):
    return ListFlowable(
        [ListItem(p(item), leftIndent=16) for item in items],
        bulletType="1",
        leftIndent=18,
        bulletFontName="Helvetica",
        bulletFontSize=8.5,
    )


def table(rows, widths, header=True):
    data = []
    for row_index, row in enumerate(rows):
        style_name = "TableHeader" if header and row_index == 0 else "Cell"
        data.append([p(str(cell), style_name) for cell in row])

    t = Table(data, colWidths=widths, repeatRows=1 if header else 0, hAlign="LEFT")
    commands = [
        ("GRID", (0, 0), (-1, -1), 0.35, BORDER),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
    ]
    if header:
        commands += [
            ("BACKGROUND", (0, 0), (-1, 0), LIGHT_BLUE),
            ("TEXTCOLOR", (0, 0), (-1, 0), DARK),
        ]
    t.setStyle(TableStyle(commands))
    return t


def callout(title: str, body: str, color=LIGHT_BLUE):
    data = [[p(f"<b>{title}</b><br/>{body}", "Callout")]]
    t = Table(data, colWidths=[6.45 * inch], hAlign="LEFT")
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), color),
                ("BOX", (0, 0), (-1, -1), 0.5, BORDER),
                ("LEFTPADDING", (0, 0), (-1, -1), 8),
                ("RIGHTPADDING", (0, 0), (-1, -1), 8),
                ("TOPPADDING", (0, 0), (-1, -1), 7),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
            ]
        )
    )
    return t


def section(title: str):
    return [p(title, "H1"), Rule()]


def add_footer(canvas, doc):
    canvas.saveState()
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(MUTED)
    canvas.drawString(0.75 * inch, 0.45 * inch, "Car Wash Rush - Game Rules and Mechanics")
    canvas.drawRightString(7.75 * inch, 0.45 * inch, f"Page {doc.page}")
    canvas.restoreState()


def build_story():
    story = []

    story += [
        Spacer(1, 0.75 * inch),
        p("Car Wash Rush", "Title"),
        p("Game Rules, Mechanics, Economy, Inventory, and Build Roadmap<br/>Version 1.0 - August 7, 2026", "Subtitle"),
        callout(
            "Design Thesis",
            "Car Wash Rush is a city sandbox tycoon with chaotic simulator moments. The surface experience should be simple, funny, and immediately readable. Underneath, the game should gradually expose real business forces: location, price, quality, demand, competition, employee reliability, offline events, and expansion.",
        ),
        Spacer(1, 16),
        table(
            [
                ["Current prototype", "Greybox starter corner, dirty car, dirt prompts, temporary coins, sponge upgrade."],
                ["Next technical priority", "Replace temporary player values with a real inventory/profile model, still in memory first, then DataStore persistence."],
                ["Launch product stance", "No pay-to-win. Monetize cosmetics, convenience, server-wide boosts, private servers, subscriptions, and light non-competitive boosts."],
                ["Scope warning", "Do not build the giant city first. Build durable systems that can scale into the city."],
            ],
            [1.7 * inch, 4.75 * inch],
            header=False,
        ),
        PageBreak(),
    ]

    story += section("1. Product Definition")
    story += [
        p("Car Wash Rush starts the player with almost nothing: a rag, a bucket, and a dirty vehicle at a starter intersection. The player earns cash, upgrades tools, controls locations, hires workers, automates wash stations, competes with rivals, and expands across city and rural districts."),
        p("The game should become the first entry in a repeatable studio format: small entrepreneurial activity to large empire. Future games can reuse the same progression, economy, inventory, quest, monetization, and analytics patterns."),
        p("Core design pillars", "H2"),
        bullets(
            [
                "<b>Instant clarity:</b> a first-time player must understand the first wash action in less than 30 seconds.",
                "<b>Hands-on first:</b> manual washing teaches value before automation takes over.",
                "<b>Chaos with rules:</b> foam parties, mud rushes, and rival behavior are funny, but the player always knows the next useful action.",
                "<b>Economics underneath:</b> price, quality, demand, supply, location, and competition shape profit.",
                "<b>Mobile first:</b> prompts, UI, camera, and timing must work on phone and tablet.",
                "<b>No pay-to-win:</b> paid features can save time or look better, but should not create unbeatable paid-only progression.",
            ]
        ),
    ]

    story += section("2. Player Lifecycle")
    story += [
        p("The game should guide players through increasingly complex business systems. The first play session is controlled; later sessions open up city exploration and competition."),
        table(
            [
                ["Stage", "Player Experience", "Primary Systems"],
                ["First 2 minutes", "Spawn at starter corner, clean first car, earn first coins.", "Proximity prompts, dirt patches, coins, simple car spawn."],
                ["First 20 minutes", "Unlock sponge, hose, first helper, price choice, and first meaningful location decision.", "Inventory, upgrades, tutorial state, starter demand model."],
                ["First 1-2 hours", "Reach first owned car wash location and basic automation.", "Location ownership, employees, offline earnings, station upgrades."],
                ["First week", "Compete across locations, respond to offline events, unlock new district.", "District map, rivals, quests, event scheduler."],
                ["Long term", "Expand to city, rural, industrial, beach, and racing districts.", "Prestige, cosmetics, live ops, subscriptions, analytics."],
            ],
            [1.1 * inch, 2.75 * inch, 2.6 * inch],
        ),
    ]

    story += section("3. Core Loop Rules")
    story += [
        p("The first loop must stay clean and deterministic."),
        numbered(
            [
                "A dirty vehicle arrives at a wash spot.",
                "The player uses the currently equipped tool on visible dirt patches.",
                "Each patch requires a prompt hold or future tool action.",
                "When all required dirt patches are cleaned, the car pays the player.",
                "The player spends coins on tools, stations, employees, or location improvements.",
                "Upgrades increase speed, capacity, quality, customer types, idle performance, or cosmetics.",
                "The city responds through demand changes, rivals, events, and location opportunities.",
            ]
        ),
        callout(
            "Prototype rule",
            "Until inventory and saving are correct, do not add more economy depth. Bad data models are expensive to unwind later.",
            LIGHT_GRAY,
        ),
    ]

    story += section("4. Cleaning Mechanics")
    story += [
        p("Cleaning should evolve from simple prompt holds into tool-specific actions. Each vehicle has a generated dirt profile, and each dirt type prefers certain tools."),
        table(
            [
                ["Dirt Type", "Early Tool", "Advanced Tool", "Gameplay Purpose"],
                ["Dust", "Rag", "Microfiber mitt", "Fast starter feedback."],
                ["Mud", "Sponge", "Pressure washer", "Creates satisfying visual removal."],
                ["Grease", "Soap bucket", "Degreaser", "Requires specialized purchase."],
                ["Paint splatter", "Brush", "Polish buffer", "Slower premium task."],
                ["Farm grime", "Hose", "Heavy washer", "Rural district identity."],
                ["Race grime", "Foam sprayer", "Detailing station", "Racing district identity."],
                ["Mystery goo", "Event tool", "Event station", "Limited-time chaos."],
            ],
            [1.1 * inch, 1.25 * inch, 1.35 * inch, 2.75 * inch],
        ),
        p("Cleaning feedback rules", "H2"),
        bullets(
            [
                "Dirt should visibly shrink, fade, pop, or wash off.",
                "Every complete car should have a clear reward moment.",
                "A better tool must feel better immediately: shorter hold time, bigger effect, better sound, larger splash, or higher reward quality.",
                "Avoid making the player hunt tiny dirt pixels. The game should be readable on mobile.",
            ]
        ),
    ]

    story += section("5. Inventory and Player Profile Rules")
    story += [
        p("Inventory is the next system to code. The current prototype only stores temporary session values on the Player instance. That is fine for a smoke test, but it is not enough for a real tycoon."),
        p("Roblox DataStoreService is the platform service for data that must persist between sessions, including inventory and skill-like progression. The game should use server-owned profile data and later save it through DataStoreService."),
        table(
            [
                ["Data Group", "Fields", "Rules"],
                ["Currencies", "coins, gems, eventTickets", "Server authoritative. Client can request actions but never directly set balances."],
                ["Tools", "ownedTools, equippedTool, toolLevels", "A player may equip one cleaning tool at a time in Phase 1."],
                ["Stations", "ownedStations, stationLevels, activeLocationId", "Stations belong to a location, not globally to the player."],
                ["Locations", "ownedLocations, claimedIntersections, permits", "Claims can expire; permanent owned lots persist."],
                ["Employees", "employees, employeeLevels, morale, assignedStation", "Employees drive idle income and offline events."],
                ["Cosmetics", "ownedCosmetics, equippedCosmetics", "Cosmetics never gate core earning power."],
                ["Progress", "tutorialStep, quests, unlockedDistricts, prestige", "Progression gates UI complexity and map access."],
                ["Receipts", "processedPurchaseIds", "Developer product grants must be idempotent."],
            ],
            [1.1 * inch, 2.15 * inch, 3.2 * inch],
        ),
        p("Inventory invariants", "H2"),
        bullets(
            [
                "All grants happen on the server.",
                "Every item has a stable string id, for example <b>tool_rag</b>, <b>tool_sponge</b>, <b>station_basic_pad</b>.",
                "The profile owns ids; config tables define item stats.",
                "Purchasing an already-owned one-time item should not double-grant it.",
                "Equipping requires ownership.",
                "Saving should be versioned from the beginning, for example <b>schemaVersion = 1</b>.",
            ]
        ),
    ]

    story += section("6. Tool Progression")
    story += [
        table(
            [
                ["Tool", "Unlock", "Main Effect", "Design Note"],
                ["Old rag", "Default", "Cleans dust slowly.", "Teaches the action."],
                ["Sponge", "50 coins", "Faster basic cleaning and small bonus.", "First upgrade; must arrive quickly."],
                ["Hose", "150 coins", "Handles mud better.", "Adds range and water feedback."],
                ["Soap sprayer", "400 coins", "Pre-treats dirt groups.", "Bridge to stations."],
                ["Pressure washer", "1,000 coins", "Fast mud and farm grime.", "Strong midgame satisfaction."],
                ["Foam cannon", "Event or 2,500 coins", "Large area cleaning and cosmetic foam.", "Primary viral tool."],
                ["Detail buffer", "5,000 coins", "High-quality finish and VIP tips.", "Introduces quality stat."],
            ],
            [1.15 * inch, 1.0 * inch, 2.2 * inch, 2.1 * inch],
        ),
    ]

    story += section("7. Vehicles and Customers")
    story += [
        p("Vehicles should be mechanically distinct. A compact car is fast and cheap; a tractor is slow and high-ticket; a race bike is rare and socially exciting."),
        table(
            [
                ["Vehicle Class", "Where It Appears", "Dirt Bias", "Economic Role"],
                ["Compact", "Starter streets", "Dust", "Fast onboarding volume."],
                ["Delivery van", "City and strip centers", "Dust, grease", "Reliable mid-ticket job."],
                ["SUV", "Suburbs", "Mud, dust", "Normal family customer."],
                ["Farm tractor", "Rural", "Farm grime, mud", "Low traffic, high payout."],
                ["Construction truck", "Industrial", "Mud, grease", "Tool specialization."],
                ["Luxury car", "Downtown", "Dust, polish", "High elasticity tolerance."],
                ["Fictional race bike", "Racing district/events", "Race grime", "Rare VIP event and cosmetic hook."],
            ],
            [1.35 * inch, 1.55 * inch, 1.3 * inch, 2.25 * inch],
        ),
    ]

    story += section("8. Locations, Territory, and Map Expansion")
    story += [
        p("The map should feel large over time, but launch development should be district-based. Each district unlocks new economic conditions, vehicles, and player decisions."),
        table(
            [
                ["District", "Traffic", "Competition", "Specialty"],
                ["Starter block", "Low", "Low", "Tutorial and first price decisions."],
                ["Downtown", "High", "High", "Price wars, luxury customers, high rent."],
                ["Suburbs", "Medium", "Medium", "Stable demand and family vehicles."],
                ["Strip centers", "Medium", "Medium-high", "Shared parking lots and rival crowding."],
                ["Industrial", "Low-medium", "Medium", "Grease, trucks, contracts."],
                ["Rural", "Low", "Low-medium", "Tractors, farm equipment, high mud jobs."],
                ["Racing district", "Event-driven", "High", "Fictional race vehicles and premium cosmetics."],
            ],
            [1.25 * inch, 0.8 * inch, 1.0 * inch, 3.4 * inch],
        ),
        p("Territory rules", "H2"),
        bullets(
            [
                "Street corners can be claimed temporarily, not permanently.",
                "Owned lots are permanent progression assets.",
                "Other players can stand near a controlled intersection, but the controller receives demand priority.",
                "Undercutting can steal some demand but reduces profit and can trigger price wars.",
                "Better quality and reputation allow higher prices without losing as many customers.",
            ]
        ),
    ]

    story += section("9. Economics Model")
    story += [
        p("The game should use simplified economics that players can feel, even if they do not name the concepts."),
        table(
            [
                ["Concept", "Game Translation", "Player-Facing Result"],
                ["Demand", "Traffic and customer count by location and time.", "Busy corners matter."],
                ["Supply", "Number of active washers serving the same area.", "Too many players lower profit."],
                ["Elasticity", "Customer willingness to accept higher prices.", "Luxury customers tolerate more; commuters leave faster."],
                ["Competition", "Rivals set prices and quality nearby.", "Price wars and relocation decisions."],
                ["Monopoly", "Owning several nearby locations improves control.", "Pricing power, but more events and scrutiny."],
                ["Quality", "Tool/station/service score.", "Higher prices and VIP tips."],
                ["Reputation", "Long-term customer trust by district.", "More stable demand and better customers."],
            ],
            [1.05 * inch, 2.35 * inch, 3.05 * inch],
        ),
        p("Phase 1 economy rule", "H2"),
        p("Only implement one economic equation at first: demand falls when price is too high for a location. Do not implement full competition, monopoly, and elasticity until profile/inventory is stable."),
    ]

    story += section("10. Offline Events")
    story += [
        p("The offline system should be sticky without feeling purely punitive. The player should return to urgent business decisions, not just damage."),
        table(
            [
                ["Event", "Chance Basis", "Effect", "Good Design Version"],
                ["Power outage", "Hourly offline roll", "Station stops temporarily.", "Pay repair, wait, or use backup upgrade."],
                ["Employee quit", "Morale and wage risk", "Worker unavailable.", "Rehire, raise wages, or train replacement."],
                ["Rival pressure", "Competitive intersections", "Demand share drops.", "Lower price, improve quality, or move."],
                ["Territory challenge", "Unowned street corners", "Claim weakens.", "Return to defend or accept lower income."],
                ["Equipment jam", "Station age and usage", "Reduced speed.", "Repair or upgrade."],
                ["Surprise rush", "Positive offline roll", "Bonus queue waiting.", "Come back to cash in."],
            ],
            [1.25 * inch, 1.25 * inch, 1.55 * inch, 2.4 * inch],
        ),
        callout(
            "Hybrid rule",
            "Every offline hour can roll a business event, but hard losses should be capped. The goal is high return urgency, not rage-quitting.",
            LIGHT_GRAY,
        ),
    ]

    story += section("11. Employees and Automation")
    story += [
        bullets(
            [
                "Employees convert owned stations into idle income.",
                "Employees have speed, reliability, morale, and assigned station.",
                "Low morale increases quit chance and mistakes.",
                "Training improves output but costs coins.",
                "Automation should never remove all reasons to actively play; active play should remain the best income per minute.",
            ]
        ),
    ]

    story += section("12. Monetization Rules")
    story += [
        p("Roblox passes are appropriate for one-time privileges; developer products are appropriate for repeat purchases. MarketplaceService purchase grants must be validated and handled server-side."),
        table(
            [
                ["Product Type", "Allowed Examples", "Restriction"],
                ["Game pass", "VIP lounge, auto collect tips, extra cosmetic loadouts.", "Avoid permanent paid-only best earning path."],
                ["Developer product", "Server foam party, temporary rush event, instant clean tokens.", "Receipt granting must be idempotent."],
                ["Subscription", "Cosmetics, idle cap, 25% idle boost, higher supercar chance.", "Do not dominate active competitive leaderboards."],
                ["Private server", "Creator filming, friend sessions, custom event controls.", "No exclusive economy advantage in public progression."],
                ["Cosmetics", "Foam colors, tool skins, signs, employee uniforms.", "Best monetization category for no-pay-to-win."],
            ],
            [1.25 * inch, 2.6 * inch, 2.6 * inch],
        ),
    ]

    story += section("13. Analytics and Tuning")
    story += [
        p("Roblox custom events can track the specific funnels that matter to this game: onboarding, progression, economy, and shop behavior."),
        table(
            [
                ["Metric", "Target Question"],
                ["Time to first wash", "Do players understand the game immediately?"],
                ["Time to first upgrade", "Is the first reward fast enough?"],
                ["Cars cleaned per session", "Is the core loop sticky?"],
                ["Upgrade purchase distribution", "Where does progression stall?"],
                ["Offline return rate", "Do offline events bring players back?"],
                ["Price changes by location", "Are economics understandable?"],
                ["Shop views to purchases", "Is monetization clear without pressure?"],
                ["D1/D7 retention", "Is the game worth returning to?"],
            ],
            [2.0 * inch, 4.45 * inch],
        ),
    ]

    story += section("14. Current Prototype Assessment")
    story += [
        table(
            [
                ["System", "Status", "Comment"],
                ["Greybox world", "Working", "Starter corner is generated from server code."],
                ["Cleaning", "Working prototype", "Dirt patches use ProximityPrompt."],
                ["Currency", "Temporary", "Coins exist only as session leaderstats."],
                ["Inventory", "Not real yet", "Current tool is a single StringValue, not an inventory model."],
                ["Saving", "Not implemented", "No DataStore persistence yet."],
                ["Upgrades", "Temporary", "Sponge is hard-coded, not config-driven inventory."],
                ["Economics", "Not implemented", "No demand, price, rivals, or location ownership yet."],
                ["Monetization", "Not implemented", "Do not add until profile and receipt handling are ready."],
            ],
            [1.45 * inch, 1.25 * inch, 3.75 * inch],
        ),
    ]

    story += section("15. Next Thing To Code")
    story += [
        callout(
            "Recommendation",
            "Code the inventory/profile layer next. Do this before adding more gameplay features. The game needs a stable server-owned data shape for tools, currencies, upgrades, tutorial progress, and later DataStore saving.",
            LIGHT_BLUE,
        ),
        p("Step-by-step implementation order", "H2"),
        numbered(
            [
                "Create a shared item catalog in <b>src/shared/Catalog.luau</b> with tool ids, names, costs, and stats.",
                "Replace <b>Tool = 'Rag'</b> with <b>ownedTools</b>, <b>equippedToolId</b>, and <b>toolLevels</b> in PlayerData.",
                "Expose server functions: <b>ownsTool</b>, <b>grantTool</b>, <b>equipTool</b>, <b>buyTool</b>, and <b>getEquippedToolConfig</b>.",
                "Update cleaning rewards and hold durations to read from equipped tool config.",
                "Update the sponge upgrade prompt to call <b>buyTool(player, 'tool_sponge')</b>.",
                "Add a simple debug print or temporary UI state so we can confirm inventory changes during Play mode.",
                "Only after in-memory inventory works, add DataStore load/save with a schema version.",
            ]
        ),
        p("Acceptance tests for the next code change", "H2"),
        bullets(
            [
                "New player starts owning only <b>tool_rag</b>.",
                "New player has <b>tool_rag</b> equipped.",
                "Player cannot equip <b>tool_sponge</b> before buying it.",
                "Player cannot buy sponge without enough coins.",
                "Buying sponge deducts coins once and grants ownership once.",
                "Buying sponge again does not double-charge or duplicate it.",
                "Equipped sponge changes cleaning speed or reward.",
            ]
        ),
    ]

    story += section("16. Platform Notes and Sources")
    story += [
        p("Official Roblox docs checked August 7, 2026:", "H2"),
        bullets(
            [
                "Data stores: https://create.roblox.com/docs/cloud-services/data-stores",
                "DataStoreService reference: https://create.roblox.com/docs/reference/engine/classes/DataStoreService",
                "Proximity prompts: https://create.roblox.com/docs/ui/proximity-prompts",
                "Passes: https://create.roblox.com/docs/production/monetization/passes",
                "Developer products: https://create.roblox.com/docs/production/monetization/developer-products",
                "Custom analytics events: https://create.roblox.com/docs/production/analytics/custom-events",
            ]
        ),
        p("Implementation note: this document defines design rules and next engineering steps. It is not a legal, tax, or platform-policy guarantee. Re-check Roblox docs before adding monetization, paid random rewards, ads, or external brand deals."),
    ]

    return story


STYLES = make_styles()


def main():
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    doc = SimpleDocTemplate(
        str(OUTPUT),
        pagesize=letter,
        rightMargin=0.75 * inch,
        leftMargin=0.75 * inch,
        topMargin=0.7 * inch,
        bottomMargin=0.65 * inch,
        title="Car Wash Rush Game Rules and Mechanics",
        author="Codex",
    )
    story = build_story()
    doc.build(story, onFirstPage=add_footer, onLaterPages=add_footer)
    print(OUTPUT)


if __name__ == "__main__":
    main()
