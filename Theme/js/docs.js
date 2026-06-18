/*
 * Docs-specific interactions. The shared chrome (navbar dropdowns, dark-mode
 * toggle, syntax highlighting) is handled by design.vapor.codes/main.js; this
 * only covers the documentation body: the mobile sidebar drawer and the
 * on-this-page scroll-spy.
 */
(function () {
    "use strict";

    // --- Mobile drawers: left sidebar + right nav menu ------------------
    var sidebar = document.getElementById("kiln-sidebar");
    var sidebarToggle = document.getElementById("kiln-sidebar-toggle");
    var sidebarClose = document.getElementById("kiln-sidebar-close");
    var navmenu = document.getElementById("kiln-navmenu");
    var navmenuToggle = document.getElementById("kiln-navmenu-toggle");
    var navmenuClose = document.getElementById("kiln-navmenu-close");
    var backdrop = document.getElementById("kiln-doc-backdrop");

    function syncBackdrop() {
        var open = (sidebar && sidebar.classList.contains("kiln-open")) ||
            (navmenu && navmenu.classList.contains("kiln-navmenu-open"));
        if (backdrop) backdrop.classList.toggle("kiln-open", open);
    }
    function closeSidebar() {
        if (!sidebar) return;
        sidebar.classList.remove("kiln-open");
        if (sidebarToggle) sidebarToggle.setAttribute("aria-expanded", "false");
        syncBackdrop();
    }
    function closeNavmenu() {
        if (!navmenu) return;
        // Collapse any open picker dropdown so it doesn't float over the page as
        // the panel slides away. Removing `.show` keeps Bootstrap in sync (its
        // toggle reads the menu's class), so the next click still opens it.
        navmenu.querySelectorAll(".dropdown-menu.show").forEach(function (m) {
            m.classList.remove("show");
        });
        navmenu.querySelectorAll('[data-bs-toggle="dropdown"][aria-expanded="true"]').forEach(function (t) {
            t.setAttribute("aria-expanded", "false");
        });
        navmenu.classList.remove("kiln-navmenu-overflow", "kiln-navmenu-open");
        if (navmenuToggle) navmenuToggle.setAttribute("aria-expanded", "false");
        syncBackdrop();
    }

    // The language/version/theme picker dropdowns float over the mobile panel
    // (positioned + height-capped by CSS — shared design CSS for language/theme,
    // local CSS for the version picker). Bootstrap doesn't run Popper for navbar
    // dropdowns and the panel is a scroll container, so flip it to overflow:visible
    // while one is open, else it clips the floating menu.
    function inMobilePanel() { return window.matchMedia("(max-width: 991.98px)").matches; }
    function syncPanelOverflow() {
        if (!navmenu) return;
        var open = !!navmenu.querySelector(
            ".language-picker .dropdown-menu.show," +
            ".kiln-version-nav .dropdown-menu.show," +
            ".theme-picker .dropdown-menu.show"
        );
        navmenu.classList.toggle("kiln-navmenu-overflow", open && inMobilePanel());
    }
    document.addEventListener("shown.bs.dropdown", syncPanelOverflow);
    document.addEventListener("hidden.bs.dropdown", syncPanelOverflow);
    function openSidebar() {
        if (!sidebar) return;
        closeNavmenu();
        sidebar.classList.add("kiln-open");
        if (sidebarToggle) sidebarToggle.setAttribute("aria-expanded", "true");
        syncBackdrop();
    }
    function openNavmenu() {
        if (!navmenu) return;
        closeSidebar();
        navmenu.classList.add("kiln-navmenu-open");
        if (navmenuToggle) navmenuToggle.setAttribute("aria-expanded", "true");
        syncBackdrop();
    }
    function closeAll() { closeSidebar(); closeNavmenu(); }

    if (sidebarToggle) sidebarToggle.addEventListener("click", function () {
        if (sidebar && sidebar.classList.contains("kiln-open")) closeSidebar(); else openSidebar();
    });
    if (sidebarClose) sidebarClose.addEventListener("click", closeSidebar);
    if (navmenuToggle) navmenuToggle.addEventListener("click", function () {
        if (navmenu && navmenu.classList.contains("kiln-navmenu-open")) closeNavmenu(); else openNavmenu();
    });
    if (navmenuClose) navmenuClose.addEventListener("click", closeNavmenu);
    if (backdrop) backdrop.addEventListener("click", closeAll);
    document.addEventListener("keydown", function (e) {
        if (e.key === "Escape") closeAll();
    });
    // Close the sidebar drawer after following an in-page nav link on mobile.
    if (sidebar) {
        sidebar.addEventListener("click", function (e) {
            var link = e.target.closest("a.kiln-nav-link");
            if (link && window.matchMedia("(max-width: 800px)").matches) closeSidebar();
        });
    }

    // --- Sidebar: animate a section's contents in when expanded ----------
    // Native <details> can't transition its own height, and the `toggle` event
    // fires only on user interaction (not for sections rendered open on load),
    // so we restart a short reveal animation on the freshly-opened list.
    document.querySelectorAll("details.kiln-nav-section").forEach(function (section) {
        section.addEventListener("toggle", function () {
            if (!section.open) return;
            var list = section.querySelector(":scope > .kiln-nav-list");
            if (!list) return;
            list.classList.remove("kiln-nav-revealing");
            void list.offsetWidth; // reflow so the animation restarts
            list.classList.add("kiln-nav-revealing");
        });
    });

    // The theme picker (light / dark / system) now uses the shared `.theme-picker`
    // markup, so the shared themePicker.js (loaded via design.vapor.codes/main.js)
    // drives it. theme-init.js still applies the saved theme pre-paint. (Same
    // localStorage "theme" key + `.dark` class, so the two stay in sync.)

    // --- Search: shortcuts + empty-state prompt -------------------------
    // `/` or ⌘K / Ctrl+K focuses the body search; Esc blurs it. When the field
    // is focused but empty (e.g. opened via the shortcut) we show a dropdown
    // prompt so it's obvious search is ready. Kiln's search.js owns the results
    // once you type; docs.js loads after it, so our `input` handler re-shows the
    // prompt after Kiln hides the (now empty) results.
    var searchInput = document.getElementById("kiln-search-input");
    var searchResults = document.getElementById("kiln-search-results");
    if (searchInput) {
        // Discoverability: on desktop (precise pointer + room) append the
        // keyboard shortcut to the placeholder, with the platform-correct
        // modifier (⌘ on Apple, Ctrl elsewhere). The base text stays localised
        // (set by Kiln); the key combo itself is universal. Hidden on touch /
        // small screens, where there's no keyboard to hint at.
        var basePlaceholder = searchInput.getAttribute("placeholder") || "";
        var platform = (navigator.userAgentData && navigator.userAgentData.platform) ||
            navigator.platform || navigator.userAgent || "";
        var shortcutHint = /mac|iphone|ipad|ipod/i.test(platform) ? "⌘K" : "Ctrl+K";
        var desktopQuery = window.matchMedia("(min-width: 800px) and (pointer: fine)");
        function syncSearchPlaceholder() {
            searchInput.setAttribute(
                "placeholder",
                desktopQuery.matches ? basePlaceholder + " (" + shortcutHint + ")" : basePlaceholder
            );
        }
        syncSearchPlaceholder();
        desktopQuery.addEventListener("change", syncSearchPlaceholder);

        // "Enter your search…", localised by <html lang>. Kiln's Localisation
        // struct has no field for this, so these strings live here.
        var ENTER_SEARCH = {
            en: "Enter your search…",
            de: "Suchbegriff eingeben…",
            es: "Introduce tu búsqueda…",
            fr: "Saisissez votre recherche…",
            it: "Inserisci la tua ricerca…",
            ja: "検索キーワードを入力…",
            ko: "검색어를 입력하세요…",
            nl: "Voer je zoekopdracht in…",
            pl: "Wpisz wyszukiwane hasło…",
            zh: "输入搜索内容…"
        };
        function enterSearchText() {
            var lang = (document.documentElement.lang || "en").slice(0, 2).toLowerCase();
            return ENTER_SEARCH[lang] || ENTER_SEARCH.en;
        }
        function showSearchPrompt() {
            if (!searchResults || searchInput.value.trim()) return;
            var box = document.createElement("div");
            box.className = "kiln-search-empty kiln-search-prompt";
            box.textContent = enterSearchText();
            searchResults.innerHTML = "";
            searchResults.appendChild(box);
            searchResults.hidden = false;
        }
        searchInput.addEventListener("focus", showSearchPrompt);
        // Kiln hides the results when the query goes empty; re-show our prompt.
        searchInput.addEventListener("input", function () {
            if (!searchInput.value.trim()) showSearchPrompt();
        });

        document.addEventListener("keydown", function (e) {
            var typing = /^(INPUT|TEXTAREA|SELECT)$/.test(document.activeElement.tagName) ||
                document.activeElement.isContentEditable;
            if ((e.key === "k" || e.key === "K") && (e.metaKey || e.ctrlKey)) {
                e.preventDefault();
                searchInput.focus();
                searchInput.select();
                showSearchPrompt();
            } else if (e.key === "/" && !typing) {
                e.preventDefault();
                searchInput.focus();
                showSearchPrompt();
            } else if (e.key === "Escape" && document.activeElement === searchInput) {
                searchInput.blur();
            }
        });
    }

    // --- On-this-page scroll-spy ----------------------------------------
    var tocLinks = Array.prototype.slice.call(
        document.querySelectorAll(".kiln-toc a[href^='#']")
    );
    if (tocLinks.length && "IntersectionObserver" in window) {
        var byId = {};
        var headings = [];
        tocLinks.forEach(function (link) {
            var id = decodeURIComponent(link.getAttribute("href").slice(1));
            var el = document.getElementById(id);
            if (el) {
                byId[id] = link;
                headings.push(el);
            }
        });

        var current = null;
        function setActive(id) {
            if (current === id) return;
            current = id;
            tocLinks.forEach(function (l) { l.classList.remove("kiln-toc-active"); });
            if (byId[id]) byId[id].classList.add("kiln-toc-active");
        }

        var observer = new IntersectionObserver(function (entries) {
            // Pick the topmost heading currently intersecting the upper viewport.
            var visible = entries
                .filter(function (e) { return e.isIntersecting; })
                .sort(function (a, b) { return a.boundingClientRect.top - b.boundingClientRect.top; });
            if (visible.length) setActive(visible[0].target.id);
        }, { rootMargin: "0px 0px -70% 0px", threshold: 0 });

        headings.forEach(function (h) { observer.observe(h); });
    }

    // --- Carbon ads (desktop only, where the TOC sidebar is visible) -----
    // This custom theme doesn't load Kiln's bundled theme.js, so the carbon
    // loader it normally provides is reproduced here. CSP allows cdn.carbonads.com.
    var carbon = document.getElementById("kiln-carbon");
    if (carbon && carbon.dataset.serve && window.innerWidth > 1200) {
        var ad = document.createElement("script");
        ad.async = true;
        ad.type = "text/javascript";
        ad.id = "_carbonads_js";
        ad.src = "//cdn.carbonads.com/carbon.js?serve=" + encodeURIComponent(carbon.dataset.serve) +
            "&placement=" + encodeURIComponent(carbon.dataset.placement);
        carbon.appendChild(ad);
    }
})();
