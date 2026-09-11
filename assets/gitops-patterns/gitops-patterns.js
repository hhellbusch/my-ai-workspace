/**
 * GitOps pattern explorer.
 * Runs only when #gitops-patterns-app is present.
 * Re-inits on Material instant navigation via document$.
 */
(function () {
  const CONCERNS = [
    {
      id: "review-yaml",
      label: "The PR should show the objects that will land",
      detail: "Reviewers should not have to mentally evaluate Helm or Go templates.",
      favors: { factory: 3, helm: 0, appset: 1 },
    },
    {
      id: "audit",
      label: "Change record must survive without re-rendering",
      detail: "Bisect, revert, and prove what was applied from Git alone.",
      favors: { factory: 3, helm: 0, appset: 1 },
    },
    {
      id: "catalog",
      label: "Platform is a component catalog driven by values",
      detail: "Addons are selected and parameterized per cluster profile.",
      favors: { factory: 3, helm: 1, appset: 2 },
    },
    {
      id: "inventory",
      label: "Cluster inventory changes often",
      detail: "New clusters should pick up apps from labels without a dedicated render PR.",
      favors: { factory: 0, helm: 1, appset: 3 },
    },
    {
      id: "acm-labels",
      label: "ACM already owns cluster labels and placements",
      detail: "The cluster list should come from the hub, not a shadow YAML list.",
      favors: { factory: 1, helm: 0, appset: 3 },
    },
    {
      id: "tenant-drop",
      label: "Tenant onboard is a folder (or repo) drop",
      detail: "A new directory should become a namespace package without editing generators.",
      favors: { factory: 1, helm: 0, appset: 3 },
    },
    {
      id: "chart-is-product",
      label: "The Helm chart is the product",
      detail: "Stable values contract; Argo should track chart versions.",
      favors: { factory: 1, helm: 3, appset: 2 },
    },
    {
      id: "cluster-scoped",
      label: "MachineConfig, OAuth, SCC, API servers",
      detail: "Small values deltas explode into high-blast-radius cluster objects.",
      favors: { factory: 3, helm: 1, appset: 1 },
    },
    {
      id: "no-controller",
      label: "Prefer fewer in-cluster generators",
      detail: "Git should already contain the Application list for platform addons.",
      favors: { factory: 3, helm: 2, appset: 0 },
    },
    {
      id: "helm-magic",
      label: "Charts use hooks, lookup, or non-determinism",
      detail: "Sync-time Helm has produced surprises.",
      favors: { factory: 3, helm: 0, appset: 1 },
    },
    {
      id: "policy-gate",
      label: "Policy must run on final Kubernetes objects",
      detail: "Kyverno / OPA / Pluto against rendered YAML in CI, before reconcile.",
      favors: { factory: 3, helm: 0, appset: 1 },
    },
  ];

  const LAYER_BIAS = {
    all: { factory: 0, helm: 0, appset: 0 },
    cluster: { factory: 2, helm: 0, appset: 2 },
    "tenant-platform": { factory: 1, helm: 0, appset: 2 },
    "tenant-apps": { factory: 0, helm: 2, appset: 1 },
  };

  const LAYER_LABEL = {
    all: "Whole fleet",
    cluster: "Cluster settings",
    "tenant-platform": "Tenant contract",
    "tenant-apps": "Tenant apps",
  };

  const PATTERN_LABEL = {
    factory: "Values factory → Applications",
    helm: "Argo App + Helm payload",
    appset: "ApplicationSet",
  };

  const WHY = {
    factory:
      "Lean this way for a component catalog and a reviewed Application list. In this repo that is helm-component-pattern. Payload can still be Helm when the chart is the product.",
    helm:
      "Lean this way when teams already ship charts and the Application CR is not the thing multiplying. Pair with a factory or ApplicationSet so you do not clone Application YAML per cluster.",
    appset:
      "Lean this way when ACM labels or a tenant folder tree is the inventory. In this repo that is the fleet framework. For platform addons, generating Applications into Git still helps reviewers.",
  };

  const FITS = [
    ["cluster", "Cluster settings / addons", "strong", "ok", "strong"],
    ["tenant-platform", "Tenant contract (ns package)", "ok", "weak", "strong"],
    ["tenant-apps", "Tenant applications", "weak", "strong", "ok"],
  ];

  function el(tag, className, text) {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (text != null) node.textContent = text;
    return node;
  }

  function scorePatterns(checked, layer) {
    const scores = { ...LAYER_BIAS[layer] };
    for (const c of CONCERNS) {
      if (!checked[c.id]) continue;
      scores.factory += c.favors.factory;
      scores.helm += c.favors.helm;
      scores.appset += c.favors.appset;
    }
    return scores;
  }

  function ranked(scores) {
    return Object.keys(scores).sort((a, b) => scores[b] - scores[a] || a.localeCompare(b));
  }

  function fitClass(value) {
    return "gitops-patterns__fit is-" + value;
  }

  function fitWord(value) {
    return value === "strong" ? "Strong" : value === "ok" ? "Usable" : "Poor";
  }

  function init() {
    const mount = document.getElementById("gitops-patterns-app");
    if (!mount || mount.dataset.bound === "1") return;
    mount.dataset.bound = "1";
    mount.innerHTML = "";

    const state = {
      layer: "all",
      checked: Object.fromEntries(CONCERNS.map((c) => [c.id, false])),
    };

    const root = el("div", "gitops-patterns");
    mount.appendChild(root);

    function render() {
      root.replaceChildren();

      root.appendChild(el("h3", null, "Where are you looking?"));
      const chips = el("div", "gitops-patterns__chips");
      for (const id of Object.keys(LAYER_LABEL)) {
        const chip = el("button", "gitops-patterns__chip", LAYER_LABEL[id]);
        chip.type = "button";
        if (state.layer === id) chip.classList.add("is-active");
        chip.addEventListener("click", () => {
          state.layer = id;
          render();
        });
        chips.appendChild(chip);
      }
      root.appendChild(chips);

      root.appendChild(el("h3", null, "Two questions, four cells"));
      const intro = el(
        "p",
        null,
        "Helm-in-Argo, ApplicationSet, and a values-driven factory are not substitutes. Columns are when templates expand. Rows are what they expand."
      );
      root.appendChild(intro);

      const grid = el("div", "gitops-patterns__grid");
      grid.appendChild(el("div", "gitops-patterns__label", ""));
      grid.appendChild(el("div", "gitops-patterns__label", "Expand at sync (in cluster)"));
      grid.appendChild(el("div", "gitops-patterns__label", "Expand in Git / CI (rendered)"));

      const control = el("div", "gitops-patterns__rowlabel", "Control plane");
      control.appendChild(el("span", null, "Which Applications exist, on which clusters"));
      grid.appendChild(control);

      const liveApps = el("div", "gitops-patterns__cell");
      liveApps.appendChild(el("strong", null, "ApplicationSet, or a live Helm app-of-apps"));
      liveApps.appendChild(
        document.createTextNode(
          "A controller or parent Application templates Application CRs at reconcile time. New clusters appear without a render commit."
        )
      );
      grid.appendChild(liveApps);

      const gitApps = el("div", "gitops-patterns__cell is-accent");
      gitApps.appendChild(el("strong", null, "Values factory or argocd appset generate"));
      gitApps.appendChild(
        document.createTextNode(
          "CI renders Application YAML into Git. The PR shows every Application that will exist. Hub Argo syncs directories of Applications."
        )
      );
      grid.appendChild(gitApps);

      const payload = el("div", "gitops-patterns__rowlabel", "Payload");
      payload.appendChild(el("span", null, "What those Applications actually apply"));
      grid.appendChild(payload);

      const helmPayload = el("div", "gitops-patterns__cell");
      helmPayload.appendChild(el("strong", null, "Helm chart + values, or Kustomize"));
      helmPayload.appendChild(
        document.createTextNode(
          "The Application points at a chart. Argo runs helm template at sync. Git stores inputs. The cluster receives the expansion."
        )
      );
      grid.appendChild(helmPayload);

      const hydrated = el("div", "gitops-patterns__cell");
      hydrated.appendChild(el("strong", null, "Hydrated Kubernetes YAML"));
      hydrated.appendChild(
        document.createTextNode(
          "CI writes the final objects. Policy and reviewers see MachineConfigs and Subscriptions — not values."
        )
      );
      grid.appendChild(hydrated);
      root.appendChild(grid);

      root.appendChild(el("h3", null, "Fit as a primary tool for that job"));
      const table = document.createElement("table");
      const thead = document.createElement("thead");
      const hr = document.createElement("tr");
      for (const h of ["Layer", "Factory → Apps", "App + Helm payload", "ApplicationSet"]) {
        hr.appendChild(el("th", null, h));
      }
      thead.appendChild(hr);
      table.appendChild(thead);
      const tbody = document.createElement("tbody");
      for (const [id, label, a, b, c] of FITS) {
        const tr = document.createElement("tr");
        if (state.layer !== "all" && state.layer !== id) tr.className = "is-dim";
        tr.appendChild(el("td", null, label));
        for (const v of [a, b, c]) {
          const td = document.createElement("td");
          td.appendChild(el("span", fitClass(v), fitWord(v)));
          tr.appendChild(td);
        }
        tbody.appendChild(tr);
      }
      table.appendChild(tbody);
      root.appendChild(table);
      root.appendChild(
        el("p", "gitops-patterns__hint", "Composition across columns is expected. Poor as a primary tool is not a ban.")
      );

      root.appendChild(el("h3", null, "Score a choice"));
      const layout = el("div", "gitops-patterns__layout");
      const left = document.createElement("fieldset");
      left.appendChild(el("p", null, "Check the constraints that already hurt."));
      for (const c of CONCERNS) {
        const row = el("label", "gitops-patterns__concern");
        const input = document.createElement("input");
        input.type = "checkbox";
        input.checked = Boolean(state.checked[c.id]);
        input.addEventListener("change", () => {
          state.checked[c.id] = input.checked;
          render();
        });
        row.appendChild(input);
        row.appendChild(el("span", null, c.label));
        row.appendChild(el("small", null, c.detail));
        left.appendChild(row);
      }
      layout.appendChild(left);

      const right = el("div", null);
      const any = CONCERNS.some((c) => state.checked[c.id]);
      const scores = scorePatterns(state.checked, state.layer);
      const order = ranked(scores);
      const max = Math.max(1, ...order.map((id) => scores[id]));

      if (!any) {
        right.appendChild(
          el(
            "p",
            "gitops-patterns__hint",
            "Nothing checked yet. Layer bias is still on: " +
              LAYER_LABEL[state.layer].toLowerCase() +
              ". A greenfield fleet still splits: factory or AppSet for cluster addons, git generator for tenants, Helm-in-Argo for app teams."
          )
        );
      } else {
        right.appendChild(el("p", null, "Heuristic fit for " + LAYER_LABEL[state.layer].toLowerCase() + "."));
        const bars = el("div", "gitops-patterns__bars");
        for (const id of order) {
          const row = el("div", "gitops-patterns__bar-row");
          const meta = el("div", "gitops-patterns__bar-meta");
          meta.appendChild(el("span", null, PATTERN_LABEL[id]));
          meta.appendChild(el("span", null, String(scores[id])));
          row.appendChild(meta);
          const track = el("div", "gitops-patterns__bar-track");
          const fill = el("div", "gitops-patterns__bar-fill");
          fill.style.width = Math.round((scores[id] / max) * 100) + "%";
          track.appendChild(fill);
          row.appendChild(track);
          bars.appendChild(row);
        }
        right.appendChild(bars);
        const winner = order[0];
        const call = el("div", "gitops-patterns__callout");
        call.appendChild(el("strong", null, "Leading: " + PATTERN_LABEL[winner]));
        call.appendChild(document.createTextNode(WHY[winner]));
        right.appendChild(call);
        right.appendChild(
          el(
            "p",
            "gitops-patterns__hint",
            "Runner-up " +
              PATTERN_LABEL[order[1]] +
              " is often the other axis — a control-plane tool plus a payload tool, not a single winner."
          )
        );
      }

      const clear = el("button", "gitops-patterns__clear", "Clear constraints");
      clear.type = "button";
      clear.addEventListener("click", () => {
        for (const id of Object.keys(state.checked)) state.checked[id] = false;
        render();
      });
      right.appendChild(clear);
      layout.appendChild(right);
      root.appendChild(layout);
    }

    render();
  }

  if (typeof window.document$ !== "undefined" && window.document$.subscribe) {
    window.document$.subscribe(init);
  } else {
    init();
  }
})();
