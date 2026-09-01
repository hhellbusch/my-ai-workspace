---
review:
  status: unreviewed
  notes: "New companion guide from a 2026-09-01 session looking for a shared timer for remote mobbing. Author review pending."
---

# Mobbing — One Keyboard, a Shared Clock

> **Audience:** Engineers about to run or join a mob session — especially remote or hybrid groups who need everyone on the same rotation.
> **Purpose:** Name the practice, start a session, and pick a timer the whole group can open from a link. The timer this note recommends is [mobti.me](https://mobti.me/).

---

## What it is

A mob is the whole group working on the same problem, at the same time, at the same keyboard.

Woody Zuill's phrasing: *all the brilliant people working on the same thing, at the same time, in the same space, and on the same computer* ([mobprogramming.org](https://mobprogramming.org/)).

One person *drives* (types). Everyone else *navigates* (decides what happens next). Rotate on a short clock so the keyboard doesn't belong to anyone.

Pair programming is two people; a mob is the team. The product is shared understanding, not parallel tickets.

This is not a status meeting with a screen share. If only one person is thinking and the rest are watching, it isn't a mob.

---

## How a session runs

**Driver.** At the keyboard (or sharing the editor). Types what the group has agreed. Does not silently freelance the design.

**Navigators.** Speak in intention, not keystrokes — "extract this validation into its own function," not "click the third menu." The driver translates intention into input.

**The clock.** Rotation is the facilitator. Common range is 5–15 minutes — shorter than a pomodoro. When the timer rings, the next person drives. No debate about whether this is a good stopping point; the clock already decided.

Remote: one shared editor or screen, everyone else on voice, **and** a shared timer URL so nobody is watching a private countdown.

A written goal for the session (one sentence) beats a vague "let's look at the bug." Change the goal when the work changes; don't keep driving under a stale one.

---

## The timer: [mobti.me](https://mobti.me/)

Solo pomodoro apps ([Pomofocus](https://pomofocus.io/) and the like) keep the clock on one person's machine.

A mob needs a named URL everyone can open and operate.

[mobti.me](https://mobti.me/) is built for that:

- Pick a room name, share `https://mobti.me/your-room`
- Anyone with the link can add names, start or stop the timer, and update the session goal
- No accounts
- Free for the basic timer; [source is public](https://github.com/mrozbarry/mobtime) and self-hostable if the hosted instance's retention isn't acceptable (idle rooms on the public host are dropped after a few days)

**To start:** open [mobti.me](https://mobti.me/), name the room, paste the link in the call chat, add who's here, hit start.

### Adjacent tools

These are not replacements for rotation; they solve a slightly different job.

| Tool | When it fits |
|---|---|
| [timer.team](https://timer.team/) | Shared 25/5 pomodoro from a URL, if the group wants a focus/break cycle *in addition* to driver rotation |
| [mobtime.hadrienmp.fr](https://mobtime.hadrienmp.fr) | Synced turn timer plus pomodoro; FOSS ([HadrienMP/mobtime](https://github.com/HadrienMP/mobtime)) |
| [timer.mob.sh](https://timer.mob.sh/) | Shared room that pairs with the [`mob`](https://mob.sh/) CLI for git handoff |

---

## With AI in the room

[The Shift](the-shift.md) names a trap: AI substituting for the conversations that build shared understanding.

A mob is a structural counter. The conversation *is* the work. If someone is prompting an assistant, the rest of the group still navigates — what to ask, whether the output holds, when to throw it away. Don't let the model become a second driver that only one person can see.

This is a different practice from [sparring and shoshin](sparring-and-shoshin.md), which are human–AI disciplines. A mob is human–human. They compose: the group can spar an AI draft together, or check the session's framing before anyone starts prompting.

---

## Related Reading

- [The Shift — Engineering Skills in the Age of AI](the-shift.md) — why human collaboration gets more important as AI handles implementation
- [Sparring and Shoshin](sparring-and-shoshin.md) — adversarial review and beginner's mind as human–AI practices; complementary, not a substitute for a mob
- [Woody Zuill — Mob Programming](https://mobprogramming.org/) — origin and practice write-ups
- [awesome-mobbing](https://github.com/mobtimeapp/awesome-mobbing) — timers, primers, and session formats

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
