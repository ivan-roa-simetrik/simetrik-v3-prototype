# Login

> Last updated: 2026-08-12
> Related file: `index.html`

## Purpose

Entry point of the journey. Communicates what Simetrik V3 is ("everything goes through the agent") and gets the user signed in. Rebuilt from a reference screenshot the user shared directly (light sign-in panel + dark value-prop panel with a floating product mockup).

## Decisions taken

- **Layout flipped from the original split-screen**: sign-in fields on the **left** (light), value proposition on the **right** (dark). This reverses the first version of this prototype (value-prop left, form right) — the user corrected it explicitly after reviewing the reference image.

- **Ley 6 exception, scoped to this screen only.** Simetrik's root law says light and dark never mix in the same view. This screen does it on purpose, matching the reference the user provided. This is *not* a precedent for the rest of the product — Home, sidebar and chat stay light-mode only. If this needs to generalize later, that's a deliberate follow-up decision, not an accident.

- **Full English copy, financial glossary translated.** The skill's mandatory glossary (Conciliación, Fuente, Asiento contable…) is normally never translated. The user explicitly instructed the whole prototype to move to English going forward, so glossary terms are now translated too (Reconciliation, Source, Journal entry, Accounting period). Recorded here as an explicit product decision, not an oversight.

- **`Cover.png` used as the dark panel's background image.** This asset was shared earlier without a stated purpose; it's a dark blue/black gradient that fits naturally behind the value-prop content. Inferred usage — flag if wrong.

- **Product naming shifted to match the reference**: "Simetrik Agéntico" (the working title from earlier sessions) is replaced by **"Simetrik V3"** / eyebrow "Simetrik as Code", with tagline "Everything goes through the agent." This now needs to be reconciled with Home/Sidebar/Chat copy, which still uses generic "Simetrik" branding (no direct conflict yet, but worth aligning in the next pass).

- **"Continue with Google" uses Google's real multi-color G mark.** This is a standard, expected pattern for OAuth buttons (Google publishes this asset for exactly this use) — different from the earlier concern about using Claude's logo out of context.

- **Floating "Workflow · Period close" mockup** is a static illustration (not interactive) representing the product's core loop: Dataset → Rule → Reconciliation → Output, with two floating badges ("Deterministic · Auditable" and a 92%-match ring). It exists purely to make the value proposition tangible on the dark panel, same spirit as the earlier chat→artifact mini-preview it replaces.

## Current implementation state

- ✅ Light/dark split matching the reference structure
- ✅ Google button (visual only — triggers the same simulated auth as email/password)
- ✅ Email/password fields, show/hide password toggle, loading state on submit
- ✅ Floating workflow mockup with gradient border + two floating badges
- ⛔ No real OAuth, no real validation — any input signs in
- ⛔ Pills in the dark panel ("Card reconciliation", "Accounting close"...) are static, non-interactive

## Centering pass (2026-08-12)

- **Left panel (`.login-access`)**: the logo is now `position: absolute` pinned to the panel's top-left corner (matching the panel's own padding, `top: 56px; left: 64px`), taken out of the flex flow. The form block (`.login-access-body`) is the panel's only flex child now, centered on **both axes** via `align-items: center; justify-content: center` on the parent — it no longer sits flush-left with a `margin-top` push, it's a true centered block regardless of viewport height.
- **Right panel (`.login-value`)**: added `justify-content: center` to the existing column flex, so the whole value-prop stack (eyebrow → headline → subhead → pills → mockup) is vertically centered as a group (symmetric top/bottom spacing) while every element keeps its natural left text alignment — no `align-items`/`text-align: center` was added, so nothing centers horizontally here, only vertically.
- These two panels are deliberately asymmetric in *how* they center (left = both axes as one block; right = vertical only, text stays left) — that was the explicit instruction, not an inconsistency.

## Revision (2026-08-12, same day): logo moved back inline + right panel now fully centered too

The absolute-positioning approach above created a problem the user caught: once the form block centers vertically, a fixed-at-top-left logo drifts far away from "Welcome to Simetrik V3" on tall viewports — no longer reads as "right above it". Fix:

- **Logo moved back in-flow**, now the first element inside the title block of `.login-access-body`, directly above "Welcome to Simetrik V3" with an 8px margin. It travels together with the rest of the form as one centered unit instead of being pinned independently. Still left-justified (not center-aligned) because it's a narrower auto-width image inside a flex column with no `text-align`/`align-items: center` forcing it otherwise.
- **Logo size increased**: `height: 24px → 36px`.
- **Right panel now also centered on both axes**: added `align-items: center` to `.login-value` (previously only `justify-content: center`, i.e. vertical-only, per the earlier explicit instruction to keep it left-justified). This is a deliberate reversal of that earlier decision — the user asked for symmetry between both panels. Each element (headline, subhead, pills row, mockup card) centers as its own block based on its own `max-width`; text inside each block still reads left-to-right normally, only the block's position centers.
- **Favicon added**: `<link rel="icon" type="image/png" href="assets/img/Simetrik_isologo.png">` in `<head>`. Scoped to `index.html` only per explicit instruction ("todo esto en el login") — not yet propagated to `flows/home/index.html`.

## Floating card treatment on the right panel (2026-08-12)

`.login-value` now has `padding` unchanged but gained `margin: 24px 24px 24px 0` + `border-radius: 24px`, so it reads as a floating rounded card inset from the top/right/bottom edges of the viewport, flush against the left panel (no gap on that side — kept the seam clean between the two panels rather than introducing a visible strip down the middle). `overflow: hidden` (already present) clips the background image and content to the new rounded corners.

## Demo animation loop on the mockup card (2026-08-12)

The "Workflow · Period close" card now runs a looping, self-playing demo instead of a static snapshot — reinforces "everything goes through the agent" pedagogically instead of decoratively:

1. Chat prompt types out character by character with a blinking cursor (`#mockupTypedText` / `#mockupCursor`).
2. The 4 pipeline steps (Dataset → Rule → Reconciliation → Output) light up in sequence, each staying highlighted (cumulative build-up, not a moving single highlight) — `.mockup-step.is-active .mockup-step-icon`.
3. The two floating badges ("Deterministic · Auditable", "92% Matches this cycle") fade/scale in afterward, staged as "the agent's response".
4. Holds for ~2.6s, then resets and loops indefinitely.

Implemented as a self-contained IIFE with `async/await` + `setTimeout`-based `wait()`, no external animation library. One full loop ≈ 6-7s. Runs regardless of user interaction (it's a passive marketing demo, not tied to real chat state).

## Left-justify correction (2026-08-12, same day)

Follow-up to "panel derecho también centrado en ambos ejes": the user clarified that only the **pills row** and the **mockup card** should stay centered (as they already were) — the eyebrow ("Simetrik as Code · V3"), the headline ("Everything goes through the agent."), and the subhead ("Build and operate...") go back to left-justified. Implemented with `align-self: flex-start` on those three elements only, so they override the parent's `align-items: center` without touching it for the pills/mockup (which still center via the parent). Net result: text block-left, decorative elements (pills, animated card) centered — matches the reference image's original asymmetry more closely than the fully-centered version did.

## Right panel horizontal padding + chat avatar (2026-08-12)

- `.login-value` padding changed from `56px 64px` to `56px 224px` (left/right only, per explicit request — vertical padding untouched). This makes the content column noticeably narrower/more inset than before, independent of the panel's own outer width (no `max-width` — that was reverted).
- Added a person avatar (`lucide: user`, dark circle) next to the chat bubble in the mockup animation, wrapped in a new `.mockup-msg-row` (flex, right-aligned) so it reads as an actual person chatting rather than a floating bubble with no sender. `.mockup-msg` itself lost its own `margin-left: auto`/`align-self` (now handled by the row's `justify-content: flex-end`).
- Scope note: only added an avatar to the human's message. Didn't add a distinct agent reply bubble — the "response" is still represented by the two badges appearing at the end of the loop. Flag if a literal agent chat-bubble reply (separate from the badges) is what's wanted instead.

## Right panel width capped, then reverted (2026-08-12)

Briefly added `max-width: 700px` to `.login-value` — user asked to revert it right after, so the panel is back to filling its full grid column (`1.15fr`) as before. Noting it here in case width-capping comes up again.

## Favicon confirmed (2026-08-12)

User shared the isologo image again to request it as the favicon. Verified no new file was added to `assets/img/` — it's the same asset as `Simetrik_isologo.png`, already wired as the favicon since the earlier "big logo + favicon" pass. No change needed.

## Logo spacing (2026-08-12)

`margin-bottom` on `.login-brand-logo` increased from 8px to 32px (+24px) for more breathing room between the logo and "Welcome to Simetrik V3".

## Prefilled credentials (2026-08-12)

Email and password fields ship prefilled for demo convenience: `ivan.roa@simetrik.com` (real, non-sensitive) and `demo1234` (**fictitious** — not the user's real password). The user initially asked for their real password to be hardcoded; flagged that a real credential in plaintext HTML is a bad idea if this folder ever gets shared, committed, or handed to a teammate for feedback, since the field doesn't validate anything anyway. User agreed to a fake value instead. If this ever needs the real value for some reason, don't just paste it back in without re-raising the same flag.

## Agent icon resolved (2026-08-12)

Earlier flagged as ambiguous (`simetrik-agent-icon.png` / `descarga.png`, same file, purpose unconfirmed). The user confirmed it's an official corporate asset representing **the agent** specifically (distinct from `Simetrik_isologo.png`, which represents the company/product mark). Applied to the headline icon in `.value-headline` — "Everything goes through the **agent**." now shows the agent icon instead of the generic isologo, sized up slightly (30px → 36px) since it's a more detailed multi-color mark. `descarga.png` (the duplicate) stays unused/unreferenced.

## Fix: mockup card shrank after centering the right panel (2026-08-12)

Adding `align-items: center` to `.login-value` changed how `.mockup-wrap` sizes itself: it only had `max-width: 560px` (no own `width`), which relied on the old default `stretch` behavior to fill up to that cap. Under `align-items: center`, flex items shrink-to-fit their content instead of stretching — so the card collapsed to whatever its narrowest content needed, reading as "contracted". Fixed by giving `.mockup-wrap` an explicit `width: 560px` (with `max-width: 100%` as a responsive fallback on narrow panels) so it renders at full size and centers as a fixed-size block, same as before.

## QA checklist (verify on every future edit to this screen)

- [x] **Logo position**: `Simetrik_logo.svg` sits above "Welcome to Simetrik V3", left-justified (not centered). This is a fixed requirement — don't center it even if other content gets centered later.
- [x] **Icon/label containers centered**: every flex row pairing an icon with text (Google button, divider, password-eye toggle, mockup header dots, floating badges, the 92% ring, the 4 workflow step icons) has an explicit `align-items: center` — not relying on flexbox's default. Verified 2026-08-12 by reading `index.html` directly; not yet confirmed against a live render (see caveat below).
- [ ] **Live visual confirmation** — code-level centering ≠ visual centering (icon glyphs can be optically off-center inside their own SVG viewBox regardless of container CSS). Couldn't capture a screenshot in this environment (Chrome extension not connected, `screencapture` blocked). Needs a human look when opened in a real browser.

## Open / pending

- Still waiting on: the "Belong" typeface (no file received yet — currently still Inter) and a reference for sidebar responsive behavior.
- Home/Sidebar/Chat now need a naming pass to align with "Simetrik V3" if that's the definitive product name going forward.
- Should the dark-panel exception extend to any other single-purpose screen (e.g., an onboarding intro), or stay unique to login?

## Related files

- `index.html` — full markup + styles + script
- `assets/img/Simetrik_logo.svg` — wordmark, left panel
- `assets/img/Simetrik_isologo.png` — icon mark, inline in the headline
- `assets/img/Cover.png` — dark panel background
