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
        navmenu.classList.remove("kiln-navmenu-open");
        if (navmenuToggle) navmenuToggle.setAttribute("aria-expanded", "false");
        syncBackdrop();
    }
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

    // --- Theme picker: light / dark / system ----------------------------
    // Replaces the shared light/dark toggle. "system" follows the OS and is
    // stored by removing the key (matching the head inline-script default).
    (function () {
        var KEY = "theme";
        var mq = window.matchMedia("(prefers-color-scheme: dark)");
        function stored() { try { return localStorage.getItem(KEY); } catch (e) { return null; } }
        function current() { return stored() || "system"; }
        function apply(pref) {
            var dark = pref === "dark" || ((pref === "system" || !pref) && mq.matches);
            document.documentElement.classList.toggle("dark", dark);
            var meta = document.querySelector('meta[name="theme-color"]');
            if (meta) meta.setAttribute("content", dark ? "#141416" : "#ffffff");
        }
        function refreshLabels() {
            var c = current();
            var label = c.charAt(0).toUpperCase() + c.slice(1);
            document.querySelectorAll(".kiln-theme-name").forEach(function (el) { el.textContent = label; });
            document.querySelectorAll(".kiln-theme-nav .dropdown-item[data-theme]").forEach(function (a) {
                a.classList.toggle("active", a.getAttribute("data-theme") === c);
            });
            // Mirror the active option's icon onto the toggle so it reflects the
            // current choice (sun / moon / monitor) at a glance.
            var opt = document.querySelector('.kiln-theme-nav .dropdown-item[data-theme="' + c + '"] .kiln-theme-opt-icon');
            if (opt) {
                document.querySelectorAll(".kiln-theme-toggle-icon").forEach(function (el) {
                    el.innerHTML = opt.innerHTML;
                });
            }
        }
        function setTheme(pref) {
            try {
                if (pref === "system") localStorage.removeItem(KEY);
                else localStorage.setItem(KEY, pref);
            } catch (e) {}
            apply(pref);
            refreshLabels();
        }
        document.querySelectorAll(".kiln-theme-nav .dropdown-item[data-theme]").forEach(function (a) {
            a.addEventListener("click", function (e) { e.preventDefault(); setTheme(a.getAttribute("data-theme")); });
        });
        mq.addEventListener("change", function () { if (current() === "system") apply("system"); });
        refreshLabels();
    })();

    // --- Search: shortcuts + empty-state prompt -------------------------
    // `/` or ⌘K / Ctrl+K focuses the body search; Esc blurs it. When the field
    // is focused but empty (e.g. opened via the shortcut) we show a dropdown
    // prompt so it's obvious search is ready. Kiln's search.js owns the results
    // once you type; docs.js loads after it, so our `input` handler re-shows the
    // prompt after Kiln hides the (now empty) results.
    var searchInput = document.getElementById("kiln-search-input");
    var searchResults = document.getElementById("kiln-search-results");
    if (searchInput) {
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
})();
