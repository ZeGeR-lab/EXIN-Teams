local _, FT = ...

-- Bump this when the ordered raid list or its completion rules change. Reports
-- with a different version are ignored instead of being displayed incorrectly.
FT.progressVersion = 1

FT.attunementData = {
  {
    key="barrow", name="Barrow Deeps", size="10-player", phase="Launch",
    published=false,
    requirement="Blizzard has announced the raid, but no attunement requirement has been published.",
  },
  {
    key="hyjal", name="Hyjal Summit", size="20-player", phase="Launch",
    published=false,
    requirement="Blizzard has announced the raid, but no attunement requirement has been published.",
  },
  {
    key="onyxia", name="Onyxia's Lair", size="40-player", phase="Launch",
    published=true, completeIDs={6502}, itemID=16309,
    activeIDs={6501,6502,6601,6602},
    requirement="Complete the faction attunement chain and obtain the Drakefire Amulet. The tracker accepts quest 6502 or the amulet in your bags/bank.",
  },
  {
    key="molten", name="Molten Core", size="40-player", phase="Later / unconfirmed",
    published=true, completeIDs={7848}, activeIDs={7848},
    requirement="Classic shortcut attunement: complete Attunement to the Core for Lothos Riftwalker at Blackrock Mountain.",
  },
  {
    key="blackwing", name="Blackwing Lair", size="40-player", phase="Later / unconfirmed",
    published=true, completeIDs={7761}, activeIDs={7761},
    requirement="Classic orb access: complete Blackhand's Command, begun from the Scarshield Quartermaster in Blackrock Mountain.",
  },
  {
    key="naxx", name="Naxxramas", size="40-player", phase="Later / unconfirmed",
    published=true, completeIDs={9121,9122,9123}, activeIDs={9121,9122,9123},
    requirement="Classic attunement: complete your Argent Dawn reputation version of The Dread Citadel - Naxxramas at Light's Hope Chapel.",
  },
}

-- Quest IDs and grouping reflect the Forever beta quest cache for build
-- 1.60.1.70009. Pickup directions are intentionally compact for in-game use.
FT.dungeonData = {
  {
    name="Ragefire Chasm", short="Ragefire Chasm", finder="13", quests={
      {id=5723, name="Testing an Enemy's Strength", level=15, side="Horde", pickup="Rahauro - Thunder Bluff, Elder Rise (70, 30)"},
      {id=5728, name="Hidden Enemies", level=16, side="Horde", pickup="Thrall - Orgrimmar, Valley of Wisdom (31, 37)", note="Requires the earlier Hidden Enemies steps."},
      {id=5724, name="Returning the Lost Satchel", level=16, side="Horde", pickup="Maur Grimtotem - inside Ragefire Chasm", note="Follows Searching for the Lost Satchel."},
      {id=5722, name="Searching for the Lost Satchel", level=16, side="Horde", pickup="Rahauro - Thunder Bluff, Elder Rise (70, 30)"},
      {id=5761, name="Slaying the Beast", level=16, side="Horde", pickup="Neeru Fireblade - Orgrimmar, The Drag (49, 50)"},
      {id=5725, name="The Power to Destroy...", level=16, side="Horde", pickup="Varimathras - Undercity, Royal Quarter (56, 92)"},
    },
  },
  {
    name="The Hall of Thanes", short="Hall of Thanes", finder="13", quests={
      {id=96395, name="An Ancient Grudge", level=15, pickup="Ghostly Attendant - inside Hall of Thanes, Anvilmar's Rest"},
      {id=96403, name="Important Heirlooms", level=15, pickup="Thom Filch - Ironforge, Old Ironforge (32.6, 44.6)"},
      {id=96394, name="The Restless Dead", level=15, side="Alliance", pickup="Afadra Dunwall - Ironforge, Old Ironforge (64.8, 58.4)"},
      {id=96393, name="Old Ironforge Incursion", level=16, pickup="Earthseer Farsen - Dun Morogh, Gol'Bolar Quarry", note="First retrieve the Underground Map in Old Ironforge."},
    },
  },
  {
    name="Ruins of Lordaeron", short="Ruins of Lordaeron", finder="15", quests={
      {id=95250, name="Abominable Creatures", level=21, side="Alliance", pickup="Captain Truman - just inside the Ruins entrance"},
      {id=97288, name="Unending Torment", level=21, side="Horde", pickup="Abominable Head drop / The Baron - inside the Ruins", completeIDs={97292}, activeIDs={97288,97289,97290,97291,97292}, note="A multi-step chain that continues in Undercity."},
      {id=92401, name="A Frightened Request", level=22, side="Horde", pickup="Tabitha Heartweaver - The Sepulcher, Silverpine Forest"},
      {id=92421, name="Light's Justice", level=22, side="Horde", pickup="Morbin Lightbane - Undercity, Royal Quarter (57.8, 89.8)"},
      {id=92415, name="Remember That I Love You", level=22, side="Alliance", pickup="Blood-Stained Letter - graveyard near Rath'mael", completeIDs={95161}, activeIDs={92415,95161}, note="Item-start chain; continues in Stormwind and Duskwood."},
      {id=92422, name="The Wrath of Rath'mael", level=22, side="Horde", pickup="Deathguard Kristof - Brill / east of Undercity"},
      {id=95195, name="Bloodied Insignia", level=22, side="Alliance", pickup="Bloodied Insignia drop - undead inside the Ruins", note="Turn in to General Marcus Jonathan in Stormwind."},
      {id=95189, name="Crest of Lordaeron", level=22, side="Alliance", pickup="Crest item - a random interactable inside the Ruins", note="Alliance version; turn in to Lady Dena Kennedy in Stormwind."},
      {id=95204, name="Crest of Lordaeron", level=22, side="Horde", pickup="Crest item - a random interactable inside the Ruins", note="Horde version; turn in to Oran Snakewrithe in Undercity."},
      {id=95216, name="The New Plague", level=22, side="Horde", pickup="Theodore Griffs - Undercity (47.0, 72.6)"},
    },
  },
  {
    name="Deadmines", short="Deadmines", finder="16", quests={
      {id=214, name="Red Silk Bandanas", level=17, side="Alliance", pickup="Scout Riell - Sentinel Hill, Westfall (56, 47)", note="Requires the Defias Brotherhood chain."},
      {id=92753, name="Destruction in Deadmines", level=18, side="Alliance", pickup="Extra-Destructive Explosives - item start", note="Forever quest; use the explosives at the forge."},
      {id=168, name="Collecting Memories", level=18, side="Alliance", pickup="Wilder Thistlenettle - Stormwind, Dwarven District (65, 21)"},
      {id=167, name="Oh Brother...", level=20, side="Alliance", pickup="Wilder Thistlenettle - Stormwind, Dwarven District (65, 21)"},
      {id=2040, name="Underground Assault", level=20, side="Alliance", pickup="Shoni the Shilent - Stormwind, Dwarven District (55, 13)"},
      {id=166, name="The Defias Brotherhood", level=22, side="Alliance", pickup="Gryan Stoutmantle - Sentinel Hill, Westfall (56, 47)", note="Final dungeon step of the Defias chain."},
      {id=373, name="The Unsent Letter", level=22, side="Alliance", pickup="Unsent Letter drop - Edwin VanCleef inside Deadmines"},
    },
  },
  {
    name="Wailing Caverns", short="Wailing Caverns", finder="17", quests={
      {id=1489, name="Hamuul Runetotem", level=16, side="Horde", pickup="Tonga Runetotem - The Crossroads quest chain", note="Breadcrumb step to Hamuul in Thunder Bluff."},
      {id=1490, name="Nara Wildmane", level=16, side="Horde", pickup="Hamuul Runetotem - Thunder Bluff, Elder Rise", note="Breadcrumb step to Nara Wildmane."},
      {id=1486, name="Deviate Hides", level=17, pickup="Nalpak - cave above the Wailing Caverns entrance (46, 35)"},
      {id=1491, name="Smart Drinks", level=18, pickup="Mebok Mizzyrix - Ratchet (62, 37)", note="Complete Raptor Horns first."},
      {id=962, name="Serpentbloom", level=18, side="Horde", pickup="Apothecary Zamah - Thunder Bluff, Pools of Vision (34, 21)"},
      {id=959, name="Trouble at the Docks", level=18, pickup="Crane Operator Bigglefuzz - Ratchet (63, 37)"},
      {id=1487, name="Deviate Eradication", level=21, pickup="Ebru - cave above the Wailing Caverns entrance (46, 35)"},
      {id=914, name="Leaders of the Fang", level=22, side="Horde", pickup="Nara Wildmane - Thunder Bluff, Elder Rise (45, 23)", note="Requires the chain beginning with The Forgotten Pools."},
      {id=3366, name="The Glowing Shard (part 1)", level=25, pickup="Glowing Shard drop - Mutanus the Devourer", note="Take the shard to Sputtervalve in Ratchet."},
      {id=6981, name="The Glowing Shard (part 2)", level=26, pickup="Sputtervalve - Ratchet", note="Take the shard to Falla Sagewind above Wailing Caverns."},
    },
  },
  {
    name="Shadowfang Keep", short="Shadowfang Keep", finder="18", quests={
      {id=1098, name="Deathstalkers in Shadowfang", level=25, side="Horde", pickup="High Executor Hadrec - The Sepulcher (43, 41)"},
      {id=1740, name="The Orb of Soran'ruk", level=25, class="WARLOCK", pickup="Doan Karhan - The Barrens, near Camp Taurajo (49, 57)", note="Warlock-only; also requires fragments from Blackfathom Deeps."},
      {id=1013, name="The Book of Ur", level=26, side="Horde", pickup="Keeper Bel'dugur - Undercity, Apothecarium (53, 54)"},
      {id=1014, name="Arugal Must Die", level=27, side="Horde", pickup="Dalar Dawnweaver - The Sepulcher (44, 39)"},
    },
  },
  {
    name="Blackfathom Deeps", short="Blackfathom Deeps", finder="22", quests={
      {id=6564, name="Allegiance to the Old Gods (part 1)", level=22, side="Horde", pickup="Damp Note drop - Blackfathom Tide Priestesses outside BFD"},
      {id=6563, name="The Essence of Aku'Mai", level=22, side="Horde", pickup="Je'neu Sancrea - Zoram'gar Outpost, Ashenvale (11, 34)"},
      {id=6562, name="Trouble in the Deeps", level=22, side="Horde", pickup="Tsunaman - Stonetalon Mountains", note="Breadcrumb to Je'neu Sancrea at Zoram'gar Outpost."},
      {id=971, name="Knowledge in the Deeps", level=23, side="Alliance", pickup="Gerrig Bonegrip - Ironforge, Forlorn Cavern (50, 5)"},
      {id=1198, name="In Search of Thaelrid", level=24, side="Alliance", pickup="Dawnwatcher Shaedlass - Darnassus, Craftsmen's Terrace (55, 24)"},
      {id=1275, name="Researching the Corruption", level=24, side="Alliance", pickup="Gershala Nightwhisper - Auberdine, Darkshore (38, 43)"},
      {id=1199, name="Twilight Falls", level=25, side="Alliance", pickup="Argent Guard Manados - Darnassus, Craftsmen's Terrace (55, 24)"},
      {id=6565, name="Allegiance to the Old Gods (part 2)", level=26, side="Horde", pickup="Je'neu Sancrea - Zoram'gar Outpost, Ashenvale (11, 34)", note="Follows the Damp Note turn-in."},
      {id=1200, name="Blackfathom Villainy", level=27, side="Alliance", pickup="Argent Guard Thaelrid - inside BFD, southwest of Ghamoo-ra", note="Requires In Search of Thaelrid."},
      {id=6561, name="Blackfathom Villainy", level=27, side="Horde", pickup="Argent Guard Thaelrid - inside BFD, southwest of Ghamoo-ra"},
    },
  },
  {
    name="Stormwind Stockade", short="The Stockade", finder="23", quests={
      {id=386, name="What Comes Around...", level=25, side="Alliance", pickup="Guard Berton - Lakeshire, Redridge Mountains (26, 46)"},
      {id=377, name="Crime and Punishment", level=26, side="Alliance", pickup="Councilman Millstipe - Darkshire, Duskwood (42, 47)"},
      {id=387, name="Quell the Uprising", level=26, side="Alliance", pickup="Warden Thelwater - outside the Stockade (41, 58)"},
      {id=388, name="The Color of Blood", level=26, side="Alliance", pickup="Nikova Raskol - patrols Stormwind Old Town"},
      {id=391, name="The Stockade Riots", level=29, side="Alliance", pickup="Warden Thelwater - outside the Stockade (41, 58)", note="Requires the chain beginning with The Unsent Letter."},
    },
  },
  {
    name="Razorfen Kraul", short="Razorfen Kraul", finder="24", quests={
      {id=1221, name="Blueleaf Tubers", level=26, pickup="Mebok Mizzyrix - Ratchet (62, 37)", note="Take the Crate with Holes, Snufflenose Command Stick, and Snufflenose Gopher."},
      {id=1144, name="Willix the Importer", level=30, pickup="Willix the Importer - tent near the final boss inside RFK", note="Escort quest."},
    },
  },
  {
    name="Gnomeregan", short="Gnomeregan", finder="25", quests={
      {id=2922, name="Save Techbot's Brain!", level=26, side="Alliance", pickup="Tinkmaster Overspark - Ironforge, Tinkertown (69, 50)", note="Follows the Tinkmaster Overspark breadcrumb."},
      {id=2923, name="Tinkmaster Overspark", level=26, side="Alliance", pickup="Gnoarn - Ironforge, Tinkertown", note="Breadcrumb to Tinkmaster Overspark."},
      {id=2926, name="Gnogaine", level=27, side="Alliance", pickup="Ozzie Togglevolt - Kharanos, Dun Morogh (45, 49)"},
      {id=2927, name="The Day After", level=27, side="Alliance", pickup="Gnoarn - Ironforge, Tinkertown", note="Breadcrumb to Ozzie Togglevolt in Kharanos."},
      {id=2904, name="A Fine Mess", level=30, pickup="Kernobee - inside Gnomeregan, room beside the Clean Room", note="Escort quest."},
      {id=2928, name="Gyrodrillmatic Excavationators", level=30, side="Alliance", pickup="Shoni the Shilent - Stormwind, Dwarven District (55, 12)"},
      {id=2842, name="Chief Engineer Scooty", level=35, side="Horde", pickup="Sovik - Orgrimmar, Valley of Honor (76, 25)", note="Pick up Rig Wars first."},
      {id=2843, name="Gnomer-gooooone!", level=35, side="Horde", pickup="Scooty - Booty Bay (27, 77)", note="Follows Chief Engineer Scooty and unlocks the teleporter."},
    },
  },
  {name="Excavation Site: Wetlands", short="Excavation: Wetlands", finder="24-29", pending=true, note="Forever quest IDs and pickup locations have not been published yet."},
  {name="City of Dalaran", short="City of Dalaran", finder="28-33", pending=true, note="Forever quest IDs and pickup locations have not been published yet."},
  {name="The Drowned City", short="The Drowned City", finder="35-40", pending=true, note="Forever quest IDs and pickup locations have not been published yet."},
  {name="Krol'dok Stronghold", short="Krol'dok Stronghold", finder="40-45", pending=true, note="Forever quest IDs and pickup locations have not been published yet."},
  {name="Alcaz Prison", short="Alcaz Prison", finder="48-53", pending=true, note="Forever quest IDs and pickup locations have not been published yet."},
  {name="Blackmaw Hold", short="Blackmaw Hold", finder="55-60", pending=true, note="Forever quest IDs and pickup locations have not been published yet."},
  {name="Shaper's Terrace", short="Shaper's Terrace", finder="58-60", pending=true, note="Forever quest IDs and pickup locations have not been published yet."},
}
