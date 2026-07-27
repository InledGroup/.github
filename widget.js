/**
 * InledGroup Contributors Widget
 *
 * Usage:
 *   <script src="https://inledgroup.github.io/inled-profile/widget.js"></script>
 *   <div class="inled-contributors" data-limit="10"></div>
 *
 * Options (data attributes):
 *   data-limit   - Max contributors to show (default: all)
 *   data-format  - "grid" (default) or "row"
 */
(function () {
  "use strict";

  var BASE = "https://inledgroup.github.io/inled-profile";
  var JSON_URL = BASE + "/contributors.json";

  var CSS = [
    ".inled-contributors{display:flex;flex-wrap:wrap;gap:16px;justify-content:center;padding:0;margin:0;list-style:none}",
    ".inled-contributors[data-format=row]{flex-wrap:nowrap;overflow-x:auto}",
    ".inled-contributor{display:flex;flex-direction:column;align-items:center;gap:6px;text-decoration:none;color:inherit;min-width:80px}",
    ".inled-contributor img{width:64px;height:64px;border-radius:50%;border:2px solid #e1e4e8;transition:border-color .2s,transform .2s}",
    ".inled-contributor:hover img{border-color:#0969da;transform:scale(1.05)}",
    ".inled-contributor-name{font-size:13px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:90px;color:#1a1a1a}",
    ".inled-contributor-count{font-size:11px;color:#666}",
    ".inled-contributors-error{color:#666;font-style:italic;text-align:center;width:100%}",
  ].join("\n");

  function injectStyles() {
    if (document.getElementById("inled-contributors-css")) return;
    var style = document.createElement("style");
    style.id = "inled-contributors-css";
    style.textContent = CSS;
    document.head.appendChild(style);
  }

  function createContributor(c) {
    var link = document.createElement("a");
    link.className = "inled-contributor";
    link.href = c.profile;
    link.target = "_blank";
    link.rel = "noopener";
    link.title = "@" + c.login + " (" + c.contributions + " contributions)";

    var img = document.createElement("img");
    img.src = c.avatar_url + "?s=128&v=4";
    img.alt = "@" + c.login;
    img.loading = "lazy";
    img.width = 64;
    img.height = 64;

    var name = document.createElement("span");
    name.className = "inled-contributor-name";
    name.textContent = "@" + c.login;

    var count = document.createElement("span");
    count.className = "inled-contributor-count";
    count.textContent = c.contributions + " contributions";

    link.appendChild(img);
    link.appendChild(name);
    link.appendChild(count);

    return link;
  }

  function render(el, data) {
    var limit = parseInt(el.getAttribute("data-limit"), 10);
    var contributors = data.contributors || [];

    contributors.sort(function (a, b) {
      return b.contributions - a.contributions;
    });

    if (limit > 0) contributors = contributors.slice(0, limit);

    el.innerHTML = "";

    if (!contributors.length) {
      var error = document.createElement("span");
      error.className = "inled-contributors-error";
      error.textContent = "No contributors found";
      el.appendChild(error);
      return;
    }

    for (var i = 0; i < contributors.length; i++) {
      el.appendChild(createContributor(contributors[i]));
    }
  }

  function loadAll() {
    var containers = document.querySelectorAll(".inled-contributors");
    if (!containers.length) return;

    injectStyles();

    var xhr = new XMLHttpRequest();
    xhr.open("GET", JSON_URL, true);
    xhr.onload = function () {
      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          var data = JSON.parse(xhr.responseText);
          for (var i = 0; i < containers.length; i++) {
            render(containers[i], data);
          }
        } catch (e) {
          console.error("InledContributors: invalid JSON", e);
        }
      } else {
        console.error("InledContributors: HTTP " + xhr.status);
      }
    };
    xhr.onerror = function () {
      console.error("InledContributors: network error");
    };
    xhr.send();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", loadAll);
  } else {
    loadAll();
  }
})();
