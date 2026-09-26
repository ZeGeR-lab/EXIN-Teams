# EXIN Teams

A guild team manager addon for **Ex Inferno** on WoW Forever. Guild members can belong to multiple teams, apply or accept invitations, choose dungeon roles, and see team rosters, events, and messages.

## Install

1. Copy the `ForeverTeams` folder into your WoW Forever `Interface/AddOns` directory. Replace the old folder if updating.
2. Keep the folder name `ForeverTeams` and the `ForeverTeamsDB` SavedVariables name to retain your existing team data.
3. Enable **EXIN Teams** on the AddOns screen and type `/exin` or `/teams` in game.

Each participating guild member needs the addon for live updates. Character professions are reported by that character's own addon when they log in. Team events are addon data and do not appear in the native WoW calendar.

## Features

- Multiple teams per character; eight selectable team colors.
- Team leader and officer permissions; invitations, applications, member removal, team focus, and message of the day.
- Application questions for usual availability and PvE/PvP/Both interest, shown on application and roster hover text.
- Automatic capture of the character's primary professions and skill ranks when the game API supplies them; roster hover text includes professions and main/off dungeon roles.
- Team events with RSVP, guild roster online status, and guild addon-message sync.
- Pending applications and invitations saved through logout and reannounced on reconnect.

## Current limitations

This is a beta prototype. Live synchronization and profession sharing need two-client in-game testing. Team leaders currently cannot transfer ownership or delete a team. The UI shows up to 12 teams, 9 roster members, 3 applications, and 3 events at a time. Team data is stored in each client's SavedVariables and synchronized by guild addon messages; do not rely on it as the only permanent record of guild organization.

See [CHANGELOG.md](CHANGELOG.md) for changes and [ForeverTeams/README.txt](ForeverTeams/README.txt) for in-game usage notes.
