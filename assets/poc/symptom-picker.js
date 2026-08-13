/**
 * Symptom picker PoC — loads catalog.json, filters by category + search.
 * Only runs when #symptom-picker-app is present on the page.
 */
(function () {
  const mount = document.getElementById("symptom-picker-app");
  if (!mount) return;

  const catalogUrl = new URL(mount.dataset.catalog || "../assets/poc/catalog.json", window.location.href);

  const state = {
    guides: [],
    category: "all",
    query: "",
  };

  function el(tag, className, text) {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (text != null) node.textContent = text;
    return node;
  }

  function categories(guides) {
    return ["all", ...new Set(guides.map((g) => g.category))].sort((a, b) =>
      a === "all" ? -1 : b === "all" ? 1 : a.localeCompare(b)
    );
  }

  function scoreGuide(guide, query) {
    const q = query.toLowerCase();
    if (!q) return { score: 1, match: null };
    for (const symptom of guide.symptoms) {
      if (symptom.toLowerCase().includes(q)) {
        return { score: 3, match: symptom };
      }
    }
    if (guide.title.toLowerCase().includes(q)) {
      return { score: 2, match: guide.title };
    }
    for (const tag of guide.tags) {
      if (tag.toLowerCase().includes(q)) {
        return { score: 1, match: `tag: ${tag}` };
      }
    }
    return { score: 0, match: null };
  }

  function filteredGuides() {
    return state.guides
      .filter((g) => state.category === "all" || g.category === state.category)
      .map((g) => ({ guide: g, ...scoreGuide(g, state.query) }))
      .filter((row) => state.query === "" || row.score > 0)
      .sort((a, b) => b.score - a.score || a.guide.title.localeCompare(b.guide.title));
  }

  function render(root) {
    root.replaceChildren();
    const wrap = el("div", "symptom-picker");

    const header = el("div", "symptom-picker__header");
    const search = el("input", "symptom-picker__search");
    search.type = "search";
    search.placeholder = "Type a symptom, error, or tag…";
    search.value = state.query;
    search.setAttribute("aria-label", "Search troubleshooting guides");
    search.addEventListener("input", () => {
      state.query = search.value.trim();
      render(root);
      root.querySelector(".symptom-picker__search")?.focus();
    });
    header.appendChild(search);
    wrap.appendChild(header);

    const chips = el("div", "symptom-picker__chips");
    for (const cat of categories(state.guides)) {
      const chip = el("button", "symptom-picker__chip", cat === "all" ? "All" : cat.replace(/-/g, " "));
      chip.type = "button";
      if (state.category === cat) chip.classList.add("is-active");
      chip.addEventListener("click", () => {
        state.category = cat;
        render(root);
      });
      chips.appendChild(chip);
    }
    wrap.appendChild(chips);

    const rows = filteredGuides();
    const meta = el(
      "div",
      "symptom-picker__meta",
      `${rows.length} guide${rows.length === 1 ? "" : "s"} · category: ${state.category === "all" ? "any" : state.category}`
    );
    wrap.appendChild(meta);

    const results = el("div", "symptom-picker__results");
    if (rows.length === 0) {
      results.appendChild(
        el("div", "symptom-picker__empty", "No matches — try another symptom or clear the category filter.")
      );
    } else {
      for (const { guide, match } of rows.slice(0, 12)) {
        const card = el("article", "symptom-picker__card");
        const title = el("h3", "symptom-picker__card-title");
        const link = document.createElement("a");
        link.href = guide.readme;
        link.textContent = guide.title;
        title.appendChild(link);
        if (guide.quickRef) {
          const quick = document.createElement("a");
          quick.href = guide.quickRef;
          quick.className = "symptom-picker__quick";
          quick.textContent = "⚡ quick ref";
          title.appendChild(quick);
        }
        card.appendChild(title);
        if (match) {
          card.appendChild(el("p", "symptom-picker__match", `Matched: “${match}”`));
        }
        const tags = el("div", "symptom-picker__tags");
        for (const tag of guide.tags.slice(0, 5)) {
          tags.appendChild(el("span", "symptom-picker__tag", tag));
        }
        card.appendChild(tags);
        results.appendChild(card);
      }
    }
    wrap.appendChild(results);

    const status = el("div", "symptom-picker__status", "Data: catalog.json (generated at build time from devops/catalog.yaml)");
    wrap.appendChild(status);

    root.appendChild(wrap);
  }

  async function init() {
    mount.textContent = "Loading catalog…";
    try {
      const res = await fetch(catalogUrl);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      state.guides = data.guides || [];
      render(mount);
    } catch (err) {
      mount.replaceChildren();
      const errEl = el("div", "symptom-picker__status is-error", `Failed to load catalog: ${err.message}`);
      mount.appendChild(errEl);
    }
  }

  init();
})();
