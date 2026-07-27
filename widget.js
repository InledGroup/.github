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
    ".inled-contributor img{width:64px;height:64px;border-radius:50%;border:2px solid #30363d;transition:border-color .2s,transform .2s}",
    ".inled-contributor:hover img{border-color:#58a6ff;transform:scale(1.1)}",
    ".inled-contributor-name{font-size:13px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:90px}",
    ".inled-contributor-count{font-size:11px;color:#8b949e}",
    ".inled-contributors-error{color:#8b949e;font-style:italic;text-align:center;width:100%}",
  ].join("\n");

  function injectStyles() {
    if (document.getElementById("inled-contributors-css")) return;
    var style = document.createElement("style");
    style.id = "inled-contributors-css";
    style.textContent = CSS;
    document.head.appendChild(style);
  }

  function render(el, data) {
    var limit = parseInt(el.getAttribute("data-limit"), 10);
    var contributors = data.contributors || [];

    contributors.sort(function (a, b) {
      return b.contributions - a.contributions;
    });

    if (limit > 0) contributors = contributors.slice(0, limit);

    if (!contributors.length) {
      el.innerHTML =
        '<span class="inled-contributors-error">No contributors found</span>';
      return;
    }

    var html = "";
    for (var i = 0; i < contributors.length; i++) {
      var c = contributors[i];
      var avatar = c.avatar_url + "?s=128&v=4";
      html +=
        '<a class="inled-contributor" href="' +
        c.profile +
        '" target="_blank" rel="noopener" title="@" +
        c.login +
        " (" +
        c.contributions +
        ' contributions)">' +
        '<img src="' +
        avatar +
        '" alt="@' +
        c.login +
        '" loading="lazy" width="64" height="64">' +
        '<span class="inled-contributor-name">@' +
        c.login +
        "</span>" +
        '<span class="inled-contributor-count">' +
        c.contributions +
        " contributions</span>" +
        "</a>";
    }
    el.innerHTML = html;
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
