/*
  Simetrik Agéntico — shared shell behavior (sidebar, nav, microinteracciones)
  Compartido entre flujos (home, y futuros: agents, apps).
*/

document.addEventListener('DOMContentLoaded', () => {
  if (window.lucide) lucide.createIcons();

  initSidebarCollapse();
  initProjectExpand();
  initNavActive();
  initSectionCollapse();
  initSidebarProjectActions();
});

function initSidebarCollapse() {
  const sidebar = document.getElementById('sidebar');
  const collapseBtn = document.getElementById('sidebarToggle'); // header icon, visible when expanded — "Close Side Panel"
  const expandBtn = document.getElementById('sidebarLogoExpand'); // logo, visible when collapsed — "Open Side Panel"
  if (!sidebar) return;

  function toggleSidebar() {
    sidebar.classList.toggle('is-collapsed');
  }

  if (collapseBtn) collapseBtn.addEventListener('click', toggleSidebar);
  if (expandBtn) expandBtn.addEventListener('click', toggleSidebar);
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
  document.querySelectorAll('.sidebar-section-header').forEach((header) => {
    header.addEventListener('click', () => {
      const section = header.closest('.sidebar-section--collapsible');
      if (section) section.classList.toggle('is-expanded');
    });
  });
}

// Per-project ellipsis in the sidebar's Pinned section: opens a popover with
// Unpin/Invite members/Archive/Edit info. Scoped to each .project-item via
// .closest() (not by project id) because none of these actions are wired to
// real behavior yet — they're placeholders added ahead of defining what each
// one actually triggers (see docs/sidebar.md → Pendiente/abierto). Static
// markup (not re-rendered like the Projects view's cards), so plain
// addEventListener per element is enough — no delegation needed.
function initSidebarProjectActions() {
  const menus = Array.from(document.querySelectorAll('.sidebar-project-actions-menu'));
  if (!menus.length) return;

  function closeAllSidebarActionMenus() {
    document.querySelectorAll('.sidebar-project-actions-menu.is-open').forEach((menu) => menu.classList.remove('is-open'));
    document.querySelectorAll('.sidebar-project-actions-btn.is-open').forEach((btn) => btn.classList.remove('is-open'));
  }

  menus.forEach((menu) => {
    const wrap = menu.closest('.sidebar-project-actions-wrap');
    const trigger = wrap && wrap.querySelector('.sidebar-project-actions-btn');
    if (!trigger) return;

    trigger.addEventListener('click', (e) => {
      // .project-row lives next to this button (not around it, to keep
      // markup valid — no nested <button>s), so this isn't strictly needed
      // for the expand toggle, but it stops the click from immediately
      // re-closing the menu via the document listener below.
      e.stopPropagation();
      const isOpen = menu.classList.contains('is-open');
      closeAllSidebarActionMenus();
      if (!isOpen) {
        menu.classList.add('is-open');
        trigger.classList.add('is-open');
      }
    });

    // Clicking an option doesn't do anything real yet — just closes the
    // popover, same as every other not-yet-wired action in this prototype.
    menu.addEventListener('click', (e) => {
      e.stopPropagation();
      if (e.target.closest('[data-sidebar-action]')) closeAllSidebarActionMenus();
    });
  });

  document.addEventListener('click', closeAllSidebarActionMenus);
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
