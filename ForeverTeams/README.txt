EXIN Teams — Ex Inferno guild prototype for WoW Forever

INSTALL
Replace the ForeverTeams folder in your Forever Interface/AddOns folder.
The AddOns screen now lists it as EXIN Teams. Type /exin or /teams in game.
The panel has a dark Ex Inferno theme; selecting a team changes the header
accent to that team's chosen color.
Keep the folder named ForeverTeams so existing SavedVariables are preserved.
Each participating guild member needs the addon installed for live sync.
Your Teams lists teams you belong to and teams you lead. Other Teams lists
the remaining guild teams; use the arrow buttons to browse more teams. Every
guild member can select a team, see its roster names and online status, and
apply to join. Private roster details require membership or guild officer rank.
The first of Your Teams opens automatically. The Activity log button on a team
records joins, leaves, member promotions, event creation, and team edits seen
by your addon. It retains 80 entries locally; changes made while your addon is
offline will not appear retrospectively. Refresh checks for another online
guild member running EXIN Teams. If none answers, chat shows one connection
status message rather than repeated offline whisper errors.

NEW IN 0.2.0
Use the Attunements tab to choose a raid and see who is Missing, In progress,
Complete, or has No report. Select a team on the Teams tab first to narrow the
readiness list to that team; with no team selected it uses the guild roster.
WoW only exposes quest history for the character being played, so every member
must log in with EXIN Teams 0.2.0 to share their own status. Barrow Deeps and
Hyjal Summit stay marked Not published until Blizzard reveals their rules.

Use the Dungeon quests tab to select a Forever dungeon. Each quest shows where
it starts and whether this character has completed it, has it in the quest log,
or has not completed it. Quests for another faction or class are dimmed instead
of counted as missing. The list contains the 66 quests currently exposed by the
Forever beta across 10 dungeons. Announced later dungeons remain marked Pending
until their quest IDs and locations are published.

START
Guild officers (rank 1) and the guild leader (rank 0) can create, delete, and
manage any team. A guild rank named Team Leader (or Team Leader Blue for a
specific color) can create and manage only teams owned by that character.
For development, Snoop Warg in Ex Inferno has full administrator access even
if that character's guild rank is lower. This is a temporary code override.
Their public guild note must identify the team color or exact team name in
the form "Blue - DiscordName"; rank alone or note alone does not grant access.
A
creator manages the team but is not automatically an active roster member.
The creator can use Join/Leave active roster to choose whether to participate.
The creator can delete their own team while their guild rank and note still
authorize it. Guild officers can delete any team. Deletions are saved and sent
to other addon users.
Create a team, set its focus and team message, then invite a guild member
by character name. The invitee opens /teams and clicks Join invite.
Alternatively, a guild member selects a team and clicks Apply; the team
leader or team officer clicks Accept beside their application.
Applying asks for usual availability (days and server time) and whether the
player prefers PvE, PvP, or both. Hover over a pending application to read
its answers. After acceptance, hover over their roster row for the same info.
The addon reads the current character's first two professions and skill ranks
from the game when available, then shares them privately with eligible addon
users. Hover over a roster member or applicant to see professions if you are
on that team or are a guild officer. Each player must
log in with the addon to provide their own profession data.
Leaders and officers can also click Accept beside a listed application.
The Apply button shows Pending after you apply, and Join invite is available
when you have an invitation for the selected team.
Pending applications and invitations are saved across logout. When an addon
user reconnects, their pending applications and the invitations they manage
are announced again to other online addon users.
The Add button lets a manager add a guild member who does not run the addon.
Guild public notes in the form "Team - DiscordName" (for example,
"Black - Sicnus") assign that member to the matching team color or name.
The text after the dash is the player's Discord name and appears on the
authorized team roster hover, helping identify their characters and alts.
The note provides one primary team; additional memberships use the addon.
Team roster names turn yellow if their character has no valid guild member
note. Hover over Notes needed to see every character awaiting a note, even
if they are below the visible roster rows. A note for another team still
counts as valid when someone participates in multiple teams.
The team creator can promote a member to team officer using Role. Team officers can
invite, accept, remove members, and edit team focus/message/events.
The team roster shows guild online status from the native guild roster.
The roster displays first and surname when Forever supplies both in the guild
roster. Type /exin namecheck to inspect the current character's name values
if a surname is still missing. Older saved first-name-only records migrate
when only one guild character has that first name.
Your team's message is also printed in chat when you log in.
Leaders/officers can add an event as "YYYY-MM-DD HH:MM ; Event title" using
server time. Members can click Join/Leave beside a listed event to RSVP.
Each character can choose a main dungeon role (Tank, Healer, or DPS) and an
optional off role with the buttons below the team list. Roles show on each
team roster and sync with other online guild members using the addon.

Characters may join multiple teams. Leaders and team officers cycle through
nine team colors with the Team color button. Team events and RSVPs are addon
data, not native WoW calendar events. Team roles and invites are addon data; they do
not change actual guild rank, actual guild membership, or calendar access.
Use Recruitment at the top of the window to paste a guild recruitment text,
save it locally, and post it to a joined Trade channel with one click. The
button has a one-minute cooldown. It does not post automatically on a timer.
Team ownership cannot currently transfer. Team structure uses GUILD addon
messages; personal roles, preferences, professions and attunement reports use
targeted whispers. People who were offline learn of a team when its leader
comes online and sends its data.
Do not use this version as the sole permanent record of guild organization.

Forever is beta software. Ask another guild member to install it and test
creation, application, invitation and online roster together before rolling
it out to your guild. Report any Lua error or missing sync.
