/*
  Simetrik Agéntico — shared shell behavior (sidebar, nav, microinteracciones)
  Compartido entre flujos (home, y futuros: agents, apps).
*/

// Set by initSidebarCollapsedPinnedPopover() below — initSidebarCollapse()
// calls it (if defined by the time a click actually happens) so expanding
// the sidebar never leaves the collapsed-only Pinned popover floating next
// to a header that just moved/disappeared.
let closeSidebarPinnedPopover = null;

document.addEventListener('DOMContentLoaded', () => {
  if (window.lucide) lucide.createIcons();

  initSidebarCollapse();
  initProjectExpand();
  initNavActive();
  initSectionCollapse();
  initSidebarProjectActions();
  initSidebarCollapsedPinnedPopover();
});

function initSidebarCollapse() {
  const sidebar = document.getElementById('sidebar');
  const collapseBtn = document.getElementById('sidebarToggle'); // header icon, visible when expanded — "Close Side Panel"
  const expandBtn = document.getElementById('sidebarLogoExpand'); // logo, visible when collapsed — "Open Side Panel"
  if (!sidebar) return;

  function toggleSidebar() {
    sidebar.classList.toggle('is-collapsed');
    if (closeSidebarPinnedPopover) closeSidebarPinnedPopover();
  }

  if (collapseBtn) collapseBtn.addEventListener('click', toggleSidebar);
  if (expandBtn) expandBtn.addEventListener('click', toggleSidebar);

  // Cmd/Ctrl+B → toggle sidebar collapse/expand, global (explicit user
  // request). Well-established convention for exactly this action across
  // real products (VSCode, Notion, Linear, Slack all bind Cmd/Ctrl+B to
  // "toggle sidebar") — and safe to intercept, unlike Cmd+N: plain Cmd+B
  // is only special-cased by browsers *inside* an editable rich-text
  // context (execCommand('bold')), not reserved at the browser-chrome
  // level the way "new window"/"new tab" are, so a page-level keydown
  // listener can freely claim it. Lives here (not in the page script's
  // keydown listener with ⌘K/⌘⇧⌥N) because toggling the sidebar is 100%
  // this function's own responsibility — shell.js, not flow-specific code.
  document.addEventListener('keydown', (e) => {
    const isToggleSidebar = (e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'b';
    if (isToggleSidebar) { e.preventDefault(); toggleSidebar(); }
  });
}

function initProjectExpand() {
  document.querySelectorAll('.project-row').forEach((row) => {
    row.addEventListener('click', () => {
      const item = row.closest('.project-item');
      if (item) item.classList.toggle('is-expanded');
    });
  });
}

function initSectionCollapse() {
  const sidebar = document.getElementById('sidebar');
  document.querySelectorAll('.sidebar-section-header').forEach((header) => {
    header.addEventListener('click', () => {
      // Collapsed sidebar: the Pinned header opens a popover instead (see
      // initSidebarCollapsedPinnedPopover below), not the normal
      // expand/collapse toggle — toggling .is-expanded here too would
      // silently flip the section's own expand state on every click,
      // surprising the user with a collapsed Pinned section once they
      // expand the sidebar again.
      const isCollapsedPinnedHeader = sidebar
        && sidebar.classList.contains('is-collapsed')
        && header.getAttribute('aria-label') === 'Pinned';
      if (isCollapsedPinnedHeader) return;
      const section = header.closest('.sidebar-section--collapsible');
      if (section) section.classList.toggle('is-expanded');
    });
  });
}

// Collapsed sidebar: clicking the Pinned section's icon opens a portal
// popover to its right, listing every pinned project (+ its chats nested
// directly underneath, no extra expand click) and every standalone pinned
// chat, with a live search filter. Pinned's own list is unreadable at
// 52px (no room for a nested tree) — this gives collapsed users the same
// access without forcing the whole sidebar back open.
//
// Reads the live DOM of the Pinned list on every open/keystroke instead of
// keeping a second copy of the data — that list is already the single
// source of truth other features (Projects view, Chats and Tasks) write
// into via ensureSidebarPinnedItem/ensureSidebarPinnedChatItem, so cloning
// their rendered output here can't drift the way a second hardcoded list
// would (this codebase has hit that exact "two mock lists disagree" bug
// more than once — see docs/home.md and docs/sidebar.md).
function initSidebarCollapsedPinnedPopover() {
  const sidebar = document.getElementById('sidebar');
  const pinnedHeader = document.querySelector('.sidebar-section-header[aria-label="Pinned"]');
  const popover = document.getElementById('sidebarPinnedPopover');
  const searchInput = document.getElementById('sidebarPinnedPopoverSearch');
  const results = document.getElementById('sidebarPinnedPopoverResults');
  if (!sidebar || !pinnedHeader || !popover || !searchInput || !results) return;

  const VIEWPORT_MARGIN = 8;
  const POPOVER_GAP = 6;

  // Walks the actual <ul class="project-list"> markup rather than assuming
  // shape — .project-item (project + its nested .chat-row chats) and
  // .sidebar-pinned-chat-item (a chat pinned on its own, no project) are
  // the two row types that mechanism produces; `hidden` rows (unpinned/
  // archived) are skipped, same as the sidebar itself already does visually.
  // Also captures each project's current .is-expanded state, used to seed
  // the popover's own open/close state the same as the real row shows.
  function readPinnedEntries() {
    const list = pinnedHeader.closest('.sidebar-section')?.querySelector('.project-list');
    if (!list) return [];
    const entries = [];
    Array.from(list.children).forEach((li) => {
      if (li.hidden) return;
      if (li.classList.contains('project-item')) {
        const name = li.querySelector('.project-name')?.textContent.trim();
        if (!name) return;
        const chats = Array.from(li.querySelectorAll('.chat-sublist .chat-row')).map((a) => a.textContent.trim());
        entries.push({ type: 'project', name, chats, expanded: li.classList.contains('is-expanded') });
      } else if (li.classList.contains('sidebar-pinned-chat-item')) {
        const name = li.querySelector('.sidebar-pinned-chat-name')?.textContent.trim();
        if (!name) return;
        entries.push({ type: 'chat', name });
      }
    });
    return entries;
  }

  function escapeHtml(str) {
    return str.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  }

  // Which projects are open in THIS popover — separate from (but seeded
  // from) the real sidebar's own .is-expanded, see openPopover(). Purely
  // local to the popover session; toggling here never writes back to the
  // real Pinned row.
  let expandedProjects = new Set();

  // Reuses the real sidebar's own classes (.project-item/.project-row-wrap/
  // .project-row/.folder-icon/.chat-sublist/.chat-row for projects,
  // .sidebar-pinned-chat-row-wrap/-row/-icon/-name for standalone chats)
  // instead of inventing parallel ones — that's what makes open/close and
  // hover behave *exactly* like the real Pinned rows (same crossfade, same
  // unified hover-the-whole-row treatment) for free, with zero drift risk.
  // The one thing intentionally NOT reused is .sidebar-project-actions-*
  // (the ellipsis) — this popover is a read/select shortcut, not a place to
  // manage projects.
  function renderResults(term) {
    const q = term.trim().toLowerCase();
    const entries = readPinnedEntries();
    let html = '';
    entries.forEach((entry) => {
      if (entry.type === 'chat') {
        if (q && !entry.name.toLowerCase().includes(q)) return;
        html += `<div class="sidebar-pinned-chat-row-wrap">
          <button type="button" class="sidebar-pinned-chat-row">
            <i data-lucide="message-circle-more" class="sidebar-pinned-chat-icon"></i>
            <span class="sidebar-pinned-chat-name">${escapeHtml(entry.name)}</span>
          </button>
        </div>`;
        return;
      }
      const projectMatches = !q || entry.name.toLowerCase().includes(q);
      const matchingChats = projectMatches ? entry.chats : entry.chats.filter((c) => c.toLowerCase().includes(q));
      if (!projectMatches && !matchingChats.length) return;
      // While searching, a project with only some matching chats shows
      // those results directly (no point making the user also click to
      // expand something they just searched for) — otherwise honor
      // whatever this popover session has open/closed.
      const isExpanded = q ? true : expandedProjects.has(entry.name);
      html += `<li class="project-item${isExpanded ? ' is-expanded' : ''}" data-pinned-popover-project="${escapeHtml(entry.name)}">
        <div class="project-row-wrap">
          <button type="button" class="project-row">
            <span class="folder-icon">
              <i data-lucide="folder" class="folder-icon-closed"></i>
              <i data-lucide="folder-open" class="folder-icon-open"></i>
            </span>
            <span class="project-name">${escapeHtml(entry.name)}</span>
          </button>
        </div>
        <div class="chat-sublist"><div class="chat-sublist-inner">
          ${matchingChats.map((c) => `<a class="chat-row" href="#">${escapeHtml(c)}</a>`).join('')}
        </div></div>
      </li>`;
    });
    results.innerHTML = html ? `<ul class="project-list">${html}</ul>` : '<div class="sidebar-pinned-popover-empty">No pinned items match your search.</div>';
    if (window.lucide) lucide.createIcons();
  }

  function closePopover() {
    popover.classList.remove('is-open');
  }
  closeSidebarPinnedPopover = closePopover;

  // The popover's height now tracks its content (min 200px / max 300px,
  // see tokens.css) instead of being fixed — so unlike its initial open
  // (which does a full clamp, including the left/right flip), content that
  // grows AFTER opening (clearing the search term, expanding a project)
  // can push its bottom edge past the viewport. This only ever nudges it
  // back up when that actually happens; it never repositions horizontally
  // (width is constant, so left/right never goes stale) and never moves it
  // down (a shrinking popover collapsing from a fixed top is expected, not
  // a bug).
  function repositionPopover() {
    if (!popover.classList.contains('is-open')) return;
    const rect = popover.getBoundingClientRect();
    if (rect.bottom > window.innerHeight - VIEWPORT_MARGIN) {
      const top = Math.max(VIEWPORT_MARGIN, window.innerHeight - VIEWPORT_MARGIN - rect.height);
      popover.style.top = `${Math.round(top)}px`;
    }
  }

  function openPopover() {
    searchInput.value = '';
    // Fresh snapshot of the real sidebar's open/closed projects every time
    // the popover opens, so it starts looking like the Pinned section
    // actually does right now — toggling inside the popover afterward only
    // affects this local Set, never writes back to the real row.
    expandedProjects = new Set(readPinnedEntries().filter((e) => e.type === 'project' && e.expanded).map((e) => e.name));
    renderResults('');
    popover.classList.add('is-open');

    const rect = pinnedHeader.getBoundingClientRect();
    let left = rect.right + POPOVER_GAP;
    let top = rect.top;
    const popRect = popover.getBoundingClientRect(); // safe to measure now, display:flex already applied via .is-open
    if (left + popRect.width > window.innerWidth - VIEWPORT_MARGIN) {
      left = rect.left - popRect.width - POPOVER_GAP; // not enough room to the right — flip to the left instead
    }
    if (top + popRect.height > window.innerHeight - VIEWPORT_MARGIN) {
      top = window.innerHeight - VIEWPORT_MARGIN - popRect.height;
    }
    top = Math.max(VIEWPORT_MARGIN, top);

    popover.style.left = `${Math.round(left)}px`;
    popover.style.top = `${Math.round(top)}px`;
    searchInput.focus();
  }

  pinnedHeader.addEventListener('click', (e) => {
    if (!sidebar.classList.contains('is-collapsed')) return; // expanded: let the normal section toggle above handle it
    e.stopPropagation();
    const isOpen = popover.classList.contains('is-open');
    closePopover();
    if (!isOpen) openPopover();
  });

  popover.addEventListener('click', (e) => e.stopPropagation());

  // Two different behaviors inside the results, matching the real Pinned
  // section exactly: clicking a project's .project-row only opens/closes
  // its chats (same as the real row — never navigates, never closes
  // anything above it); clicking an actual chat (nested under a project,
  // or a standalone pinned one) is the real "selection" — same no-op-on-
  // select convention already used by the Search modal and the chat side
  // panel's open picker (nothing in this prototype has a real destination
  // behind it yet), so it just closes the popover.
  results.addEventListener('click', (e) => {
    const projectRow = e.target.closest('.project-row');
    if (projectRow) {
      const item = projectRow.closest('.project-item');
      const name = item?.dataset.pinnedPopoverProject;
      if (name) {
        if (expandedProjects.has(name)) expandedProjects.delete(name);
        else expandedProjects.add(name);
      }
      item?.classList.toggle('is-expanded');
      // .chat-sublist grows/shrinks via an animated grid-template-rows
      // (--dur-base, 200ms) — reposition once immediately (handles the
      // collapse case, and any overflow already present) and once after
      // the transition settles (handles the expand case, once its final
      // height is actually in the layout).
      repositionPopover();
      setTimeout(repositionPopover, 210);
      return;
    }
    if (e.target.closest('.chat-row')) { e.preventDefault(); closePopover(); return; }
    if (e.target.closest('.sidebar-pinned-chat-row')) closePopover();
  });

  searchInput.addEventListener('input', () => {
    renderResults(searchInput.value);
    repositionPopover(); // filtering can grow the box (e.g. clearing the term) past where it fit before
  });
  searchInput.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') { closePopover(); searchInput.blur(); }
  });

  document.addEventListener('click', closePopover);
  // Bug fix (2026-08-14): scrolling the popover's own results list
  // (#sidebarPinnedPopoverResults has overflow-y:auto) closed the popover —
  // capture-phase scroll listeners on `document` also receive scroll events
  // fired by descendants, including the popover's own scrollable content,
  // not just the Pinned list's scroll it was meant to catch. Only close for
  // scrolls whose target is actually outside the popover.
  document.addEventListener('scroll', (e) => {
    if (popover.contains(e.target)) return;
    closePopover();
  }, true);
  window.addEventListener('resize', closePopover);
}

// Per-project ellipsis in the sidebar's Pinned section: opens a popover with
// Unpin/Invite members/Archive/Edit info. None of these actions are wired to
// real behavior yet — they're placeholders added ahead of defining what each
// one actually triggers (see docs/sidebar.md → Pendiente/abierto).
//
// The popover itself is a portal: it lives as a sibling of .app-shell near
// the end of <body> (matched to its trigger via data-sidebar-actions-menu /
// data-sidebar-actions-trigger, same project id), NOT nested inside the
// Pinned list. The Pinned list sits inside three nested overflow-clipping
// ancestors (.sidebar-section's own scroll, plus .sidebar-section-body/
// -body-inner's overflow:hidden for the collapse animation) — an
// overflow!=visible ancestor clips a descendant popover no matter what
// position value it uses, so portaling out of that subtree is the only
// reliable fix. Opens to the trigger's right (not below it), computed from
// getBoundingClientRect() since `position: fixed` needs real coordinates
// once the element isn't nested where CSS could anchor it with top/right.
function initSidebarProjectActions() {
  const triggers = Array.from(document.querySelectorAll('[data-sidebar-actions-trigger]'));
  if (!triggers.length) return;

  const POPOVER_GAP = 6; // space between the trigger's right edge and the popover
  const VIEWPORT_MARGIN = 8; // never render flush against the window edge

  function closeAllSidebarActionMenus() {
    document.querySelectorAll('.sidebar-project-actions-menu.is-open').forEach((menu) => menu.classList.remove('is-open'));
    document.querySelectorAll('.sidebar-project-actions-btn.is-open').forEach((btn) => btn.classList.remove('is-open'));
  }

  function openSidebarActionMenu(trigger, menu) {
    closeAllSidebarActionMenus();
    menu.classList.add('is-open');
    trigger.classList.add('is-open');

    const rect = trigger.getBoundingClientRect();
    let left = rect.right + POPOVER_GAP;
    let top = rect.top;

    // Clamp against the viewport, not against the sidebar — the popover
    // lives at <body> level now, so nothing about the sidebar's own width
    // constrains it, only the actual window edges do.
    const menuRect = menu.getBoundingClientRect(); // safe to measure now, display:block already applied via .is-open
    if (left + menuRect.width > window.innerWidth - VIEWPORT_MARGIN) {
      left = rect.left - menuRect.width - POPOVER_GAP; // not enough room to the right — flip to the left of the trigger instead
    }
    if (top + menuRect.height > window.innerHeight - VIEWPORT_MARGIN) {
      top = window.innerHeight - VIEWPORT_MARGIN - menuRect.height;
    }
    top = Math.max(VIEWPORT_MARGIN, top);

    menu.style.left = `${Math.round(left)}px`;
    menu.style.top = `${Math.round(top)}px`;
  }

  triggers.forEach((trigger) => {
    const id = trigger.getAttribute('data-sidebar-actions-trigger');
    const menu = document.querySelector(`.sidebar-project-actions-menu[data-sidebar-actions-menu="${id}"]`);
    if (!menu) return;

    trigger.addEventListener('click', (e) => {
      e.stopPropagation(); // stop this from immediately re-closing via the document listener below
      const isOpen = menu.classList.contains('is-open');
      closeAllSidebarActionMenus();
      if (!isOpen) openSidebarActionMenu(trigger, menu);
    });

    // Clicking an option doesn't do anything real yet — just closes the
    // popover, same as every other not-yet-wired action in this prototype.
    menu.addEventListener('click', (e) => {
      e.stopPropagation();
      if (e.target.closest('[data-sidebar-action]')) closeAllSidebarActionMenus();
    });
  });

  document.addEventListener('click', closeAllSidebarActionMenus);
  // The popover's position is a one-time snapshot of the trigger's
  // coordinates — if the Pinned list (or the page) scrolls or the window
  // resizes, that snapshot goes stale. Closing is simpler and safer here
  // than re-tracking position live for a menu whose actions are all no-ops
  // anyway. `true` = capture phase, since scroll doesn't bubble but this
  // still needs to hear about scrolls from inside .sidebar-section.
  document.addEventListener('scroll', closeAllSidebarActionMenus, true);
  window.addEventListener('resize', closeAllSidebarActionMenus);
}

function initNavActive() {
  document.querySelectorAll('.nav-item[data-nav]').forEach((item) => {
    item.addEventListener('click', (e) => {
      // el botón "+" interno maneja su propio click, no debe togglear el nav padre
      if (e.target.closest('.nav-item-add')) return;
      document.querySelectorAll('.nav-item[data-nav]').forEach((n) => n.classList.remove('is-active'));
      item.classList.add('is-active');
      const section = item.getAttribute('data-nav');
      if (typeof window.onNavSectionChange === 'function') {
        window.onNavSectionChange(section);
      }
    });
  });
}
