# EXIN Teams Lite

**Current version: 0.5.31**

Lightweight guild team and roster management for Ex Inferno.

## Installation

1. Download the `EXINTeamsLite-install` artifact from the successful [GitHub Actions build](https://github.com/ZeGeR-lab/EXIN-Teams/actions).
2. Extract the `EXINTeamsLite` folder from the archive.
3. Place that folder in your World of Warcraft `_retail_/Interface/AddOns/` directory (or the equivalent AddOns directory used by your game client).
4. Enable **EXIN Teams Lite** from the AddOns list.
5. Log in with a guild character and type `/exin`.

## Current features

- Create and delete guild teams with the appropriate guild-wide permissions.
- Assign team owners and transfer ownership.
- Manage team members and team-specific roles.
- Support multiple team memberships per character.
- Use the guild public note as the primary team assignment. The expected note format is `TeamName - DiscordName`; role edits preserve primary membership provenance.
- Search and scroll the guild roster, Officer permissions list, team list, and team member list; team selection stays consistent with active search filters.
- Assign one of 33 temporary emblem placeholders to each team.
- Edit or clear the team message; clearing it synchronizes to other clients.
- Warn team managers that renaming a team does not automatically rewrite guild public notes.
- Synchronize team metadata, membership, permissions, and deletions between online guild clients.
- Scope every addon message to the active guild and realm; all guild clients must update to 0.5.30 together because this release uses a new synchronization prefix.
- Resolve simultaneous same-name team creation deterministically using the lexicographically smallest team ID, with a tombstone for the losing ID.

## Permissions

- The Guild Master has guild-wide administrative access.
- **Snoop Wharg** has permanent Guild Master-equivalent access in the addon.
- Guild-wide Officers can create and delete teams, transfer ownership, and manage any team's roster.
- Designated Officers can be granted addon permissions without changing their in-game guild rank.
- Team Leaders can manage their own team's metadata and roster, but cannot delete teams or change guild-wide Officer permissions.
- Primary membership derived from the guild public note must be changed in the guild note; it cannot be removed directly in the addon.

## Development and testing

The Lua 5.1 syntax check, Core synchronization/permission regression tests, multi-client synchronization tests, and Lite-only packaging run in GitHub Actions. These automated checks do not replace an in-game compatibility and multi-member guild test. The current emblem art is placeholder artwork pending the original image assets.

## Distribution scope

The installation archive contains only the `EXINTeamsLite/` directory. It does not include the separate `ForeverTeams/` Full edition source.
