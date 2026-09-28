# Changelog

## 0.5.0 — 2026-09-27

- Automatically create teams from valid public guild notes formatted `Team - Discord name`, including teams no addon user has created yet. Match each note to one existing team by name or color and keep its roster current as notes change. Team Leaders whose notes match their team become its initial leaders; otherwise an available guild officer is chosen as steward.
- Add an officer-only Transfer button for assigning team leadership to another guild character. The new leader may manage that team without joining its active roster; their delegated rights are synchronized by guild officers.
- Show a leader's displayed guild character name on the team page. Keep deleted note-derived teams deleted until an officer creates a new team deliberately.

## 0.4.4 — 2026-09-27

- Display the installed addon version in the bottom-right corner of the team and calendar windows.
- Add a Rank check button at the bottom-left of the team window, showing the game rank, roster rank, and admin status in a popup. `/exin rankcheck` opens the same popup.
- Document how to check the installed version and verify the guild rank shown by the game.

## 0.4.3 — 2026-09-27

- Fixed guild master administration when the guild roster has not finished loading. The logged-in character's game-provided guild rank now supplies permissions immediately.
- Recognize game-provided Guild Master, Guild Leader, and Officer rank names, including officer ranks placed below guild rank index 1. Team Leaders still manage only their own teams.
- Added `/exin rankcheck` to display the game's rank, roster rank, and current admin permission for troubleshooting.

## 0.4.2 — 2026-09-27

- Styled the calendar, event editor, attendance list, and raid planner with the existing EXIN Teams dark cards, green accent bars, and panel borders.
- Added selected-day, selected-view, and selected-event highlights; adjusted calendar spacing so event pagination and details fit their sections.

## 0.4.1 — 2026-09-27

- Fixed calendar dialogs drawing behind date buttons and other calendar controls. Opening the event editor, attendance list, or raid planner now shows one panel above the calendar.
- Reopening the calendar clears dialogs left open from the previous session.

## 0.4.0 — 2026-09-27

### Calendar

- Added a visual month calendar with day buttons and separate Personal, Team, and Guild views. Event creation now has separate title and time fields instead of a typed date format.
- Personal events can have a private note and targeted invitations to guild members running EXIN Teams. Invitees choose Going or Declined. Personal invitations and responses are retried when their users reconnect.
- Team members can RSVP Yes or No; confirmed team events appear automatically on their personal view. Guild officers can create guild-wide events and members can RSVP to them.
- Added attendance lists for each event and deletion controls for personal owners, team managers, and guild officers as appropriate.

### Raid planning

- Team event managers can choose a 20-player or 40-player raid plan and assign confirmed attendees to four or eight groups of five.
- Added button-triggered attempts to invite confirmed online players (officers first), convert a party to a raid, and place members into planned raid subgroups when supported by the game and the player has group permissions. Live invite and subgroup behavior need an in-game check.

### Limits

- Personal invites are exchanged between addon users; someone without EXIN Teams cannot see or reply to the invitation in the addon.
- Personal and team events are saved locally and synchronized among online addon users. The calendar is an addon interface; it does not add events to Blizzard's built-in calendar.

### Other updates in 0.4.0

- Fixed the sidebar's extra empty team buttons and automatically open the first team in Your Teams when no team is selected.
- Send private addon updates only to guild roster members currently online and target their full canonical character names. A single connection check reports when no other guild member running EXIN Teams answers; refresh reruns the check.
- Added an Activity log button for members, team owners, and guild officers. It retains up to 80 local entries per team for joins, departures, promotions, team message/focus/color changes, guild-note membership changes, and new events.
- Preserve full first and surname character identities instead of discarding text after a hyphen, and display the two parts with a space on team rosters. Existing first-name-only saved entries migrate only when one unambiguous guild roster match exists. `/exin namecheck` reports what this Forever client actually returns for the current character.
- Temporarily grant the Ex Inferno guild character `Snoop Warg` full administrator permissions regardless of guild rank. The override requires that exact roster character name and guild; notes and Discord names cannot activate it.
- Split the team list into Your Teams and Other Teams with page controls, so every guild member can browse all advertised teams and apply. Other-team rosters show names and online status without private role, guild note, profession, or attunement details.
- Guild leader (rank 0) and officers (rank 1) can create, delete, and manage any team. An in-game `Team Leader` or color-specific `Team Leader Blue` rank may create and manage only their own team when their public note is `Blue - DiscordName` (or uses that team's exact name). The guild rank supplies authority; the note identifies the team.
- Team Leaders create teams in the color named by their note and can delete their own teams. Guild officers can also change team officers on any roster.
- Parse the Discord name after the separator in guild notes such as `Black - Sicnus` and show it on authorized team roster hover details.
- Highlight team members without a valid guild note in yellow and list everyone needing a note on the team roster. Valid notes for another team remain valid for members of multiple teams.

## 0.3.0 — 2026-09-27

### Added

- Guild officer and guild leader checks for team creation; officers may delete their own teams, and the guild leader may delete any team.
- Optional owner participation in the active team roster, separate from managing that team.
- Direct Add button for guild roster members without the addon.
- Read public guild notes in `Team - DiscordName` form as the primary team assignment. Added a Black team color.
- Recruitment editor with Save and manually triggered Post to Trade buttons and a one-minute cooldown.
- Saved deletion records so old team advertisements do not recreate a deleted team.

### Privacy

- Restricted roster hover details and attunement reports to team members and guild officers.
- Send personal roles, application preferences, professions, and attunement reports in targeted addon whispers instead of guild broadcasts.
- Remove cached personal reports when a viewer no longer belongs to an authorized team.

### Notes

- The current officer check uses guild rank ID 0 for the guild leader and rank ID 1 for officers; guilds with more officer ranks need configuration.
- Notes map one primary team. Additional team memberships remain addon data.
- Automatic yes/no whisper invitations for people without the addon are still pending; managers can add them directly.
- Multi-client deletion, permissions, privacy, guild-note changes, and Trade posting still need in-game validation.

## 0.2.0 — 2026-09-26

### Added

- Attunements tab with per-raid team readiness sorted by Missing, In progress, No report, and Complete.
- Automatic self-checks against quest completion and key items, plus compact guild-message synchronization so each participating character reports its own status.
- Launch raid entries for Barrow Deeps, Hyjal Summit, and Onyxia's Lair; unpublished custom requirements are explicitly marked instead of guessed.
- Reference entries for the known Classic Molten Core, Blackwing Lair, and Naxxramas requirements, labeled later/unconfirmed for Forever.
- Dungeon quests tab with all 66 quests currently exposed across 10 Forever beta dungeons, pickup directions, restrictions, paging, and live completion/quest-log status.
- Pending-data entries for seven announced Forever dungeons whose quest IDs are not yet public.

### Changed

- Expanded the dashboard to three pages while retaining all existing team-management features.
- Added `Data.lua` so raid and dungeon progress definitions can be updated independently from synchronization and UI code.

### Known limitations

- WoW exposes quest completion only for the current character. Each team member must log in with EXIN Teams 0.2.0 to provide their own attunement report.
- Forever beta quest and raid requirements can change; the included dataset reflects build 1.60.1.70009.

## 0.1.0 — 2026-09-26

Initial public beta of **EXIN Teams** for the Ex Inferno guild.

### Added

- Create teams with a focus, message of the day, color, and leader/officer/member roles.
- Join multiple teams; apply, invite, accept, leave, and remove members.
- Save pending applications and invitations through logout and replay them to online addon users.
- Application form for usual availability and PvE, PvP, or Both interest; show answers to officers and on roster hover after acceptance.
- Detect each addon's player's two primary professions and skill ranks, share them with other addon users, and show them on roster hover.
- Select main and off dungeon roles: Tank, Healer, or DPS.
- Show guild online status, team events, and event RSVPs.
- Dark Ex Inferno dashboard styling with team-colored accents and application buttons.
- `/exin` and `/teams` chat commands.

### Fixed

- Corrected the input popup's edit-box access for WoW Forever (`EditBox`), which had caused a Lua error when creating or editing teams.

### Known limitations

- Multi-client guild synchronization has not yet been validated in game.
- Team ownership transfer, team deletion, and scrolling through longer lists are not yet implemented.
- Profession details appear only after the character runs the addon and shares them.
