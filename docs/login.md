# Login

> Last updated: 2026-08-18
> Related file: `index.html`

## Purpose

Entry point of the journey. Communicates what Simetrik V3 is ("everything goes through the agent") and gets the user signed in. Rebuilt from a reference screenshot the user shared directly (light sign-in panel + dark value-prop panel with a floating product mockup).

## Decisions taken

- **Layout flipped from the original split-screen**: sign-in fields on the **left** (light), value proposition on the **right** (dark). This reverses the first version of this prototype (value-prop left, form right) — the user corrected it explicitly after reviewing the reference image.

- **Ley 6 exception, scoped to this screen only.** Simetrik's root law says light and dark never mix in the same view. This screen does it on purpose, matching the reference the user provided. This is *not* a precedent for the rest of the product — Home, sidebar and chat stay light-mode only. If this needs to generalize later, that's a deliberate follow-up decision, not an accident.

- **Full English copy, financial glossary translated.** The skill's mandatory glossary (Conciliación, Fuente, Asiento contable…) is normally never translated. The user explicitly instructed the whole prototype to move to English going forward, so glossary terms are now translated too (Reconciliation, Source, Journal entry, Accounting period). Recorded here as an explicit product decision, not an oversight.

- **`Cover.png` used as the dark panel's background image.** This asset was shared earlier without a stated purpose; it's a dark blue/black gradient that fits naturally behind the value-prop content. Inferred usage — flag if wrong. **Superseded 2026-08-13**: the panel background is now flat `#000000`, no image — see "Right panel: flat black background + animated perimeter border" below.

- **Product naming shifted to match the reference**: "Simetrik Agéntico" (the working title from earlier sessions) is replaced by **"Simetrik V3"** / eyebrow "Simetrik as Code", with tagline "Everything goes through the agent." This now needs to be reconciled with Home/Sidebar/Chat copy, which still uses generic "Simetrik" branding (no direct conflict yet, but worth aligning in the next pass).

- **"Continue with Google" uses Google's real multi-color G mark.** This is a standard, expected pattern for OAuth buttons (Google publishes this asset for exactly this use) — different from the earlier concern about using Claude's logo out of context. **Update 2026-08-18**: the button now triggers a real `signInWithOAuth({ provider: 'google' })` call, not a simulated one — see "Real authentication wired" below.

- **Floating "Workflow · Period close" mockup** represents the product's core loop: Dataset → Rule → Reconciliation → Output, with two floating badges ("Deterministic · Auditable" and a 92%-match ring). It exists purely to make the value proposition tangible on the dark panel, same spirit as the earlier chat→artifact mini-preview it replaces. **Note:** described as "static" here originally, but it has run as a self-playing looping demo since "Demo animation loop on the mockup card (2026-08-12)" below — this line was stale even before today's changes, corrected now.

## Current implementation state

- ✅ Light/dark split matching the reference structure
- ✅ **Real authentication (2026-08-18)**: `signInWithPassword` on submit, `signInWithOAuth({ provider: 'google' })` on the Google button, inline error message (`#loginError`, e.g. "Incorrect email or password.") instead of silently failing, automatic redirect to `flows/home/index.html` if a session already exists (`getSession()` on load) — skips the login screen entirely for a returning user. Full backend/schema story lives in `docs/supabase.md`, not duplicated here; this file only tracks how it shows up on *this screen*.
- ✅ Email/password fields, show/hide password toggle, loading state on submit
- ✅ Right panel: flat black background, floating workflow mockup with an animated rotating gradient border + colored ambient glow, self-playing demo loop (typed prompt → typing indicator → pipeline steps → two floating badges)
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
- **Superseded 2026-08-13**: this avatar was removed — see "Mockup animation reconciled with real chat conventions" below. The real chat never gives the human sender an avatar, only the agent does; this was the inverse of that rule.

## Right panel horizontal padding reduced (2026-08-13)

- `.login-value` padding changed from `56px 224px` to `56px 140px` (left/right only, vertical 56px untouched). Content column reads wider than the 224px pass above, less inset from the panel edges.

## Mockup animation reconciled with real chat conventions (2026-08-13)

The "Workflow · Period close" demo simulates a chat exchange, but it had drifted from the actual behaviors defined in `docs/chat.md` for the real chat (`flows/home/index.html`). Brought back in line:

- **Removed the person avatar next to the user's message.** The real chat gives the human sender no avatar at all — right-alignment of the bubble is the only identifier (see chat.md → "Mensajes y microinteracciones": "Los mensajes del usuario no llevan avatar"). The mockup had added a dark-circle `user` icon avatar (2026-08-12 pass); that was the inverse of the real rule and is gone now.
- **User bubble color fixed.** Text was `--color-primary-ink` (blue); real chat uses `--color-ink` (black) on a `--color-primary-tint` background precisely so the user's own message doesn't compete visually with the agent's. Matched.
- **Bubble corner fixed.** Was `border-radius: 10px 10px 2px 10px` (bottom-right cut). Real chat's user bubble is `var(--radius-md)` with only `border-top-right-radius: 4px` overridden — the "tail" reads on the top-right, not the bottom-right. Matched (`var(--radius-md)` + `border-top-right-radius: 4px`).
- **Added the missing typing indicator.** The real chat always shows a pulsing agent icon + 3-dot bubble (`.typing-indicator`) between the user's message and the agent's response — the pedagogical "agent is thinking" beat. The mockup jumped straight from the typed message to the pipeline lighting up, skipping this. Added `#mockupTyping` (same visual language: pulsing `simetrik-agent-icon.png`, sunken 3-dot bubble with `border-top-left-radius: 4px`), shown for 900ms after the message finishes typing — same duration as the real chat's first-response `showTyping()` (see chat.md → "Typing indicator de 3 puntos... 900ms en el primer mensaje"), then it disappears and the pipeline (Dataset → Rule → Reconciliation → Output) begins.
- **Scope note, unchanged from before:** the agent's actual "reply" in this mockup is still represented by the pipeline lighting up + the two badges, not a literal AI text bubble — that abstraction was a deliberate choice (see the pre-existing scope note above under "Right panel horizontal padding + chat avatar") and stays as-is. Only the surrounding mechanics (avatar rules, bubble styling, typing beat) were reconciled with chat.md.

## Right panel: flat black background + animated perimeter border (2026-08-13)

Two changes, both explicit user requests:

- **`.login-value` background simplified to flat `#000000`.** Was `#08080B url('assets/img/Cover.png') center / cover no-repeat`. `Cover.png`'s usage here had been flagged since 2026-08-12 as "inferred, flag if wrong" — the user resolved that by dropping the image outright in favor of pure black. `Cover.png` stays in use elsewhere (the sidebar avatar background in `shared/tokens.css`), this only affects the login's right panel.
- **`.mockup-border` (the gradient frame around the "Workflow · Period close" card) now animates around the perimeter**, instead of sitting static. Technique: `@property --mockup-border-angle` registers the custom property as an interpolable `<angle>`, so `conic-gradient(from var(--mockup-border-angle), ...)` can be smoothly rotated via a `@keyframes` animation (`0deg → 360deg`, `4s linear infinite`) rather than snapping. Same 3-stop gradient as before (`#4B5CF5 → #7B4CF5 → #E24CC9`, repeating the first stop at the end for a seamless loop) — this is the existing "agent gradient" already used for this card's border, just set in motion instead of introducing a new palette.
- **Runs independently of the typed-message/pipeline/badge loop.** It's a plain CSS animation (`infinite`), not gated by the JS state machine — reads as an ambient "the agent is active" signal rather than a one-shot tied to the demo's discrete beats.
- **Browser note:** `@property` needs a reasonably modern engine (Chromium, Safari 16.4+, Firefox 128+). No fallback was added — if the custom property isn't registered, the conic-gradient still renders, it just won't animate smoothly (acceptable for a prototype, not a production concern per `simetrik-ui prototype`'s relaxed hardening rule).

## Border thickness doubled + badge reveal made more fluid (2026-08-13)

Direct feedback after seeing the animated border in motion — it read as barely visible, and the two result badges felt like they popped rather than revealed themselves:

- **`.mockup-border` padding doubled**: `1.5px → 3px`. This is the ring thickness (the padding-as-border technique), so the animated conic-gradient now reads as a clearly visible band instead of a hairline.
- **Badge fade-in slowed down and softened**, on both `.mockup-badge--top` ("Deterministic · Auditable") and `.mockup-badge--bottom` (the 92% match score): transition duration went from `var(--dur-slow)` (320ms, Simetrik's canonical slowest duration) to **650ms**, and the entrance transform grew slightly (`translateY(6px) scale(.96) → translateY(10px) scale(.94)`) so there's more distance to travel during that longer fade instead of just holding at the same subtle offset for longer. This is a deliberate, scoped exception to the canonical 120/200/320ms durations (see Ley 4 in the skill's root laws) — these two badges represent the payoff moment of the whole demo ("the agent finished and here's proof"), not a routine UI-state toggle, so they get their own slower pacing on purpose.
- **Stagger between the two badges increased**: `180ms → 400ms` in the JS loop, so the bottom badge now starts fading in only after the top one is most of the way through its own fade, instead of the two overlapping almost immediately. Reads as "first this, then that" rather than both surfacing at once.

## Colored glow added around the mockup card (2026-08-13)

Against the new flat `#000000` panel, the card read as a flat cutout with no depth. Added a `box-shadow` to `.mockup-border` using the same "agent gradient" colors already driving the rotating border (blue `#4B5CF5` + pink `#E24CC9`, at low opacity, two stacked blur radii for a soft layered halo) instead of introducing a new color. It's currently a static glow (not synced to the border's rotation) — if it should breathe/pulse or shift hue in step with `mockupBorderTravel`, that's a further pass, flagging here in case it comes up.

**Fix (same day, follow-up): glow was invisible in practice.** User reported not seeing it at all. Root cause: the original opacities (`.35`/`.22`) were sized for a shadow sitting on a lighter dark surface — against **true `#000000`** (not the old `Cover.png`, which had visible dark-navy/blue tones lifting the black), a low-alpha color composited over pure black is still almost black. `rgba(75,92,245,.35)` over `#000` resolves to roughly `rgb(26,32,86)`, barely distinguishable from the background once blurred/diffused further. Fixed by:
- Raising the existing blue layer's opacity (`.35 → .65`) and tightening its blur (`32px → 24px`) so it reads as a crisp rim right at the border, not a diffuse haze
- Adding a **new middle layer** in violet (`#7B4CF5`, the border gradient's own middle stop), `56px` blur, `.45` opacity, so the transition from blue to pink doesn't have a flat gap between them
- Widening the existing pink layer's blur (`64px → 100px`) and raising its opacity (`.22 → .35`) for a softer, farther-reaching outer glow
- Adding spread (`2px`/`6px`/`10px`) to all three layers so each has solid presence before it starts dissipating via blur

**Takeaway for future passes on this dark panel**: any translucent color effect (glows, tints, overlays) needs meaningfully higher alpha than it would on a lighter or colored dark background — `#000000` gives zero lift, so subtlety reads as absence.

## Right panel width capped, then reverted (2026-08-12)

Briefly added `max-width: 700px` to `.login-value` — user asked to revert it right after, so the panel is back to filling its full grid column (`1.15fr`) as before. Noting it here in case width-capping comes up again.

## Favicon confirmed (2026-08-12)

User shared the isologo image again to request it as the favicon. Verified no new file was added to `assets/img/` — it's the same asset as `Simetrik_isologo.png`, already wired as the favicon since the earlier "big logo + favicon" pass. No change needed.

## Logo spacing (2026-08-12)

`margin-bottom` on `.login-brand-logo` increased from 8px to 32px (+24px) for more breathing room between the logo and "Welcome to Simetrik V3".

## Prefilled credentials (2026-08-12)

Email and password fields ship prefilled for demo convenience: `ivan.roa@simetrik.com` (real, non-sensitive) and `demo1234` (**fictitious** — not the user's real password). The user initially asked for their real password to be hardcoded; flagged that a real credential in plaintext HTML is a bad idea if this folder ever gets shared, committed, or handed to a teammate for feedback, since the field doesn't validate anything anyway. User agreed to a fake value instead. If this ever needs the real value for some reason, don't just paste it back in without re-raising the same flag.

**Superseded 2026-08-18**: both fields are empty again (placeholder only, no `value`). With real auth in place, a hardcoded fake password no longer means anything — see "Real authentication wired" below and `docs/supabase.md` ("Login real reemplaza el prellenado de demo").

## Real authentication wired, prefilled demo credentials removed (2026-08-18)

The submit-and-redirect-after-650ms simulation is gone. `index.html` now does real auth via Supabase:

- **New script includes**: `shared/supabase-config.js` (project URL + publishable anon key) and `shared/auth.js` (`getSupabaseClient()` wrapper), loaded before the inline `<script>`, plus the `@supabase/supabase-js` CDN bundle in `<head>`.
- **Submit handler**: `client.auth.signInWithPassword({ email, password })`. On error, shows `#loginError` (new `.login-error` element under the password field) with a friendlier message for the common case (`'Invalid login credentials'` → "Incorrect email or password."), otherwise the raw Supabase error message. On success, redirects to `flows/home/index.html` same as before.
- **Google button**: now `client.auth.signInWithOAuth({ provider: 'google', options: { redirectTo: ... } })` instead of just re-triggering the email/password submit path.
- **Session skip**: `client.auth.getSession()` runs on page load; if a session already exists, redirects straight to Home without showing the login form at all.
- **Prefilled demo credentials removed** (see superseded note above) — fields are empty with placeholder text only.
- **Not this file's job to duplicate**: schema, RLS, migrations, the `mock-v3` precedent, and the full decision trail for the Supabase project itself all live in `docs/supabase.md`. This entry only exists so this screen's own doc doesn't contradict what the code actually does.

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
- `assets/img/simetrik-agent-icon.png` — agent mark, headline icon + mockup typing indicator avatar
- `docs/chat.md` — source of truth for the real chat conventions the mockup animation now mirrors (avatar rules, bubble styling, typing indicator)
- `shared/supabase-config.js` / `shared/auth.js` — real auth wiring this screen calls into (`getSupabaseClient()`)
- `docs/supabase.md` — **authoritative doc for the real authentication** (schema, RLS, project setup, full decision trail). This file only tracks how it behaves on this specific screen.

`assets/img/Cover.png` is no longer used by this screen (superseded 2026-08-13 by a flat `#000000` background) — it's still referenced from `shared/tokens.css` for the sidebar avatar in the Home flow.
