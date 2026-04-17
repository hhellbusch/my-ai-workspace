# Using AI to Work Outside Your Expertise — A Practical Example

> **Audience:** Engineers, tech leads, and anyone curious about what AI coding assistants are actually good for.
> **Purpose:** A real, unedited example of using an AI assistant to solve a problem outside your domain expertise — image processing — through iterative conversation. This case study demonstrates the engineering skills described in [The Shift](the-shift.md) — problem decomposition, systematic debugging, verification discipline, and clear communication — applied to an unfamiliar domain.

---

## The Problem

You have a red siren GIF. You need the same animation in amber, green, blue, and white.

This is a simple-sounding task, but actually doing it requires knowledge most infrastructure or platform engineers don't have:

- How animated GIFs store frames, palettes, and transparency
- How color spaces work (RGB vs. HSV) and how hue rotation differs from simple channel swapping
- How to detect "red" pixels programmatically (it's not just `R > 0`) — red wraps around the hue circle, and pink/magenta glows near the light source sit at different hue angles
- How GIF palette quantization works and why naive approaches break transparency

Before AI assistants, your options were:
1. **Learn image processing from scratch** — read Pillow/ImageMagick docs, understand color theory, write code, debug edge cases (hours to days)
2. **Find a specific tool or web service** — maybe one exists, maybe it handles animated GIFs, maybe it preserves transparency (research time, uncertain outcome)
3. **Ask a colleague who knows this domain** — if you have one, and they're available
4. **Manually edit each frame in GIMP/Photoshop** — 17 frames × 5 colors = 85 manual edits

With an AI assistant, the entire process took about 15 minutes of conversation.

---

## What Actually Happened (The Full Iteration)

This section walks through the real conversation, including what went wrong and how it was fixed. This is the important part — AI doesn't produce perfect output on the first try. The value is in fast iteration.

### Iteration 1: Working Script, Wrong Transparency

**Prompt:** _"I'm trying to figure out how to take a gif of a red siren and create similar gifs but in different colors — I want to be able to change this red siren gif to an amber, green, blue and a white one."_

The AI produced a Python script that:
- Extracts all frames from the GIF
- Converts each frame to HSV color space
- Detects red pixels by hue angle and saturation
- Shifts the hue to the target color (or desaturates for white)
- Reassembles and saves the new GIF

The approach was correct. The first run hit two bugs:
- `MEDIANCUT` quantization doesn't support RGBA images in Pillow — needed `FASTOCTREE`
- A numpy division warning on fully-black pixels — needed safe division guards

Both were fixed and the script ran. The color shifts worked.

**Takeaway:** The AI got the architecture and algorithm right on the first pass. The bugs were library-specific edge cases — exactly the kind of thing you'd also hit writing this by hand, but the AI fixed them in seconds when shown the error output.

### Iteration 2: Pink Background on Some Frames

**Prompt:** _"There's some frames that have a pink background instead of transparent."_

The AI investigated and found the root cause: the original GIF used palette index 22 as its transparency color, which happened to map to RGB (153, 51, 102) — a pink. When each frame was independently quantized into a new palette, different frames assigned different palette indices to this pink. The single global `transparency=0` setting in the output only matched some frames.

**Fix:** Build a shared palette across all frames by compositing them into one image for quantization, then remap every frame to that same palette with a consistent transparency index.

**Takeaway:** This is a non-obvious GIF format detail. The AI diagnosed it from first principles — it understood the GIF spec well enough to reason about per-frame palette divergence. A human without GIF internals knowledge would have spent significant time figuring out why only *some* frames had the issue.

### Iteration 3: Pink Artifacts in the Light Source

**Prompt:** _"There is a pinkish/red artifact from the siren animation in the center where the light source is — it stands out most on green or white."_

The AI analyzed the pixel data in the siren's center and found the problem: the glow around the light source contains pink/magenta pixels with hues around 315–330° (HSV). The red detection filter only caught hues from 331–360° and 0–29°. These magenta glow pixels were left untouched, creating a visible pink spot in the recolored output.

**Fix:** Widen the hue detection range from `h > 0.92` to `h > 0.83` (capturing the full red-to-magenta spectrum) and lower the saturation floor from `0.15` to `0.05` (catching faint glows). Verification showed the updated filter caught 100% of red-family pixels with zero remaining artifacts.

**Takeaway:** This required domain knowledge about how light sources produce color gradients across the hue spectrum. The AI had that knowledge and could apply it when given a clear description of the visual symptom.

---

## The Pattern: Describe, Review, Correct

Every iteration followed the same loop:

```
Describe the problem or symptom
       ↓
AI investigates and proposes a fix
       ↓
Run it, observe the result
       ↓
Describe what's still wrong
       ↓
(repeat until done)
```

You never needed to know:
- That GIFs use palette-indexed color
- That red wraps around the hue circle at 0°/360°
- That pink is just desaturated red at a different hue angle
- That `MEDIANCUT` doesn't support RGBA in Pillow 11.x

The AI knew these things. Your job was to **describe what you saw** and **judge whether the output was correct**. That's a fundamentally different skill than knowing image processing — and one most engineers already have.

---

## When Does This Pattern Work?

This approach is effective when:

| Condition | Why it matters |
|---|---|
| **The domain is well-documented publicly** | AI training data covers image processing, audio, data formats, protocols thoroughly |
| **You can evaluate the output** | You can look at the GIF and see if it's right — you don't need domain expertise to judge results |
| **The task is bounded** | "Recolor this GIF" has a clear done state, unlike open-ended research |
| **Iteration is cheap** | Running a Python script takes seconds, so trial-and-error is fast |
| **The stakes are low** | A wrong color in a GIF won't cause an outage — iterate freely |

This pattern is **less effective** when:
- You can't evaluate correctness (e.g., cryptographic code — how do you know it's secure?)
- The domain is niche or proprietary (internal APIs, undocumented systems)
- The task requires real-world context the AI doesn't have (your network topology, your team's conventions)
- Mistakes are costly or hard to detect

For a contrast, consider the architecture decisions involved in [deploying LLMs on enterprise OpenShift infrastructure](https://jaredburck.me/blog/openshift-ai-llm-enterprise-deployment/). The same engineering skills apply (decomposition, verification, systematic reasoning), but the stakes and context-dependence are much higher — runtime selection, storage architecture, compliance posture, and cost modeling all require organizational context that AI doesn't have. AI can help you *implement* whatever architecture you choose, but selecting the right one remains a human judgment call.

---

## What the AI Actually Produced

The final script ([`recolor-gif.py`](../examples/gif-recoloring/recolor-gif.py)) is ~240 lines of Python that:

1. Extracts all frames from an animated GIF preserving timing metadata
2. Converts each frame to HSV color space using vectorized NumPy operations
3. Detects red-family pixels (red, pink, magenta) using hue angle and saturation thresholds
4. Shifts detected pixels to the target hue (or desaturates for white)
5. Builds a shared 256-color palette across all frames for consistency
6. Remaps each frame to the shared palette with a reserved transparency index
7. Saves the result as a properly-formatted animated GIF

Usage:

```bash
python3 recolor-gif.py siren.gif
# Outputs: siren_amber.gif, siren_green.gif, siren_blue.gif, siren_white.gif

python3 recolor-gif.py siren.gif --colors amber blue
# Only generate specific colors

python3 recolor-gif.py siren.gif --output-dir ./output/
# Save to a specific directory
```

Color tuning is available via the `COLOR_CONFIGS` dictionary at the top of the script.

---

## Lessons for Teams

### 1. AI lowers the barrier to adjacent domains

The person running this session is an infrastructure engineer, not an image processing specialist. The AI bridged that gap in 15 minutes. This isn't about replacing specialists — it's about unblocking yourself when the task is outside your primary expertise but still needs to get done.

### 2. Describing symptoms is the key skill

Notice the prompts weren't technical image processing requests. They were:
- _"Create GIFs in different colors"_ (goal)
- _"There's a pink background instead of transparent"_ (symptom)
- _"There's a pinkish artifact in the center"_ (symptom)

The AI translated symptoms into technical root causes. You don't need to know the domain — you need to clearly describe what you're seeing. This is the same skill as writing a good bug report or a clear incident description — **communication** is an engineering fundamental, not a soft skill. (See [The Shift](the-shift.md) for more on why communication and collaboration matter more now.)

### 3. Iteration beats perfection

The first version had bugs. The second had transparency issues. The third had color artifacts. Each fix took under a minute. The total time was still a fraction of what learning the domain from scratch would have taken.

Each iteration followed a structured pattern: observe the symptom, investigate the cause, implement a fix, verify the result. That's **systematic problem-solving** — the same methodology whether you're debugging a GIF or a production Kubernetes cluster.

### 4. Verify, don't trust

At each step, the output was validated — running the script, checking pixel values, counting transparent pixels across frames. AI-generated code needs the same scrutiny as code from any other source. The difference is you can also ask the AI to help you write the validation.

This is **quality assurance thinking** in practice: defining acceptance criteria (4,125 transparent pixels per frame, correct RGB values), designing verification checks, and running them at every iteration. The domain was unfamiliar, but the methodology is universal.

---

## Related Resources

| Resource | Where |
|---|---|
| The Shift — engineering skills in the age of AI | `docs/the-shift.md` |
| The recolor script | [`examples/gif-recoloring/recolor-gif.py`](../examples/gif-recoloring/recolor-gif.py) |
| AI-Assisted Development Workflows (general guide) | `docs/ai-assisted-development-workflows.md` |
| Cursor skills and commands | `.cursor/skills/`, `.cursor/commands/` |

---

*This document was written with AI assistance (Cursor). The conversation it describes was a real working session — the iterations, bugs, and fixes are presented as they occurred. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for full context on AI-generated content in this workspace.*
