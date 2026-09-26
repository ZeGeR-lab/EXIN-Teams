# Changelog

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
