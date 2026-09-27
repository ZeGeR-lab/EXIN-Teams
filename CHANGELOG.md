# Changelog

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
