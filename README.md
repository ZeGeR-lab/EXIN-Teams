# EXIN Teams

A guild team manager addon for **Ex Inferno** on WoW Forever. Guild members can belong to multiple teams, apply or accept invitations, choose dungeon roles, review raid attunement readiness, and track Forever dungeon quests.

Version 0.4.4 shows the installed version at the bottom-right of EXIN Teams and adds an in-panel Rank check button. Download the latest addon from this repository or use the versioned ZIP. Version 0.4.3 fixes guild master and officer permissions when the guild roster is still loading or an officer rank has a custom position. Type `/exin rankcheck` to open the rank popup. Version 0.4.2 styles the calendar and raid planner to match the EXIN Teams panels. Version 0.4.1 fixes calendar dialogs drawing behind date buttons. Version 0.4.0 adds an addon calendar for personal, team, and guild events, attendance responses, private personal invitations, and a 20/40-player raid planner. Click Calendar in the top bar. The planner's live party invites and subgroup placement depend on Forever's in-game API and raid permissions; they still need an in-game test.

## Install

1. Copy the `ForeverTeams` folder into your WoW Forever `Interface/AddOns` directory. Replace the old folder if updating.
2. Keep the folder name `ForeverTeams` and the `ForeverTeamsDB` SavedVariables name to retain your existing team data.
3. Enable **EXIN Teams** on the AddOns screen and type `/exin` or `/teams` in game.

Each participating guild member needs the addon for live updates. Character professions are reported by that character's own addon when they log in. Team events are addon data and do not appear in the native WoW calendar.

## Features

- Multiple teams per character; nine selectable team colors.
- Team leader and officer permissions; invitations, applications, member removal, team focus, and message of the day.
- Application questions for usual availability and PvE/PvP/Both interest, shown on application and roster hover text.
- Automatic capture of the character's primary professions and skill ranks when the game API supplies them; roster hover text includes professions and main/off dungeon roles.
- Team events with RSVP, guild roster online status, and guild addon-message sync.
- Pending applications and invitations saved through logout and reannounced on reconnect.
- Guild leader (rank 0) and officers (rank 1) create, delete, and manage any team. The in-game Team Leader rank may create and manage its own team when its public note identifies the team color or name. The owner chooses whether to participate on the active roster.
- Public guild notes such as `Black - Sicnus` assign a primary team; team managers can add guild members without the addon.
- Professions, roles, preferences, and attunement reports are shared privately with team members and guild officers. The Recruitment button saves a message and posts it to Trade only when clicked.
- **Attunements tab:** shows Complete, In progress, Missing, or No report for authorized members of the selected team. Each character checks its own quest history and shares a compact readiness report with their team and guild officers running EXIN Teams.
- **Dungeon quests tab:** covers all 66 dungeon quests currently exposed by the Forever beta across 10 dungeons, including pickup directions, faction/class restrictions, and automatic Completed/In quest log/Not completed status for the current character.
- Placeholders for the seven announced later-level Forever dungeons whose quest IDs and pickup locations have not yet been published.

## Current limitations

This is a beta prototype. Live synchronization, profession sharing, and attunement reporting need two-client in-game testing. A member's raid status is unavailable until that character logs in with the same EXIN Teams data version; WoW does not let one client inspect another character's quest history directly. Barrow Deeps and Hyjal Summit remain marked "not published" until Blizzard reveals their requirements. Molten Core, Blackwing Lair, and Naxxramas use their known Classic requirements as later/unconfirmed references and may change for Forever.

Dungeon quest data reflects the Forever beta quest cache for build `1.60.1.70009`. Forever is still changing, so new or revised quest IDs will require an addon update. Team leaders currently cannot transfer ownership or delete a team. The Teams page shows up to 12 teams, 9 roster members, 3 applications, and 3 events at a time; the Attunements page shows up to 17 members. Team data is stored in each client's SavedVariables and synchronized by guild addon messages; do not rely on it as the only permanent record of guild organization.

See [CHANGELOG.md](CHANGELOG.md) for changes and [ForeverTeams/README.txt](ForeverTeams/README.txt) for in-game usage notes.
