(function() {
  var appState = window.__yardAppState || (window.__yardAppState = {
    navigationListenerBound: false,
    navigationChangeBound: false,
    navResizerBound: false,
    searchFrameGlobalsBound: false
  });
  var safeLocalStorage = {};
  var safeSessionStorage = {};

  try {
    safeLocalStorage = window.localStorage;
  } catch (error) {}

  try {
    safeSessionStorage = window.sessionStorage;
  } catch (error) {}

  function query(selector, root) {
    return (root || document).querySelector(selector);
  }

  function queryAll(selector, root) {
    return Array.prototype.slice.call(
      (root || document).querySelectorAll(selector)
    );
  }

  function isVisible(element) {
    if (!element) return false;
    return window.getComputedStyle(element).display !== "none";
  }

  function toggleDisplay(element, visible, displayValue) {
    if (!element) return;
    element.style.display = visible ? (displayValue || "") : "none";
  }

  function firstNextMatchingSibling(element, selector) {
    var current = element;
    while (current) {
      current = current.nextElementSibling;
      if (current && current.matches(selector)) return current;
    }
    return null;
  }

  function ready(callback) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", callback, { once: true });
    } else {
      callback();
    }
  }

  function createSourceLinks() {
    queryAll(".method_details_list .source_code").forEach(function(sourceCode) {
      var toggleWrapper = document.createElement("span");
      var link = document.createElement("a");

      toggleWrapper.className = "showSource";
      toggleWrapper.appendChild(document.createTextNode("["));
      toggleWrapper.appendChild(link);
      toggleWrapper.appendChild(document.createTextNode("]"));

      link.href = "#";
      link.className = "toggleSource";
      link.textContent = "View source";

      link.addEventListener("click", function(event) {
        event.preventDefault();
        var expanded = isVisible(sourceCode);
        toggleDisplay(sourceCode, !expanded, "table");
        link.textContent = expanded ? "View source" : "Hide source";
      });

      sourceCode.parentNode.insertBefore(toggleWrapper, sourceCode);
    });
  }

  function createDefineLinks() {
    queryAll(".defines").forEach(function(defines) {
      var toggleLink = document.createElement("a");
      var summary = defines.parentElement.previousElementSibling;

      toggleLink.href = "#";
      toggleLink.className = "toggleDefines";
      toggleLink.textContent = "more...";
      defines.insertAdjacentText("afterend", " ");
      defines.insertAdjacentElement("afterend", toggleLink);

      toggleLink.addEventListener("click", function(event) {
        event.preventDefault();
        var expanded = toggleLink.dataset.expanded === "true";

        if (!expanded) {
          toggleLink.dataset.height = String(summary.offsetHeight);
          defines.style.display = "inline";
          summary.style.height = toggleLink.parentElement.offsetHeight + "px";
          toggleLink.textContent = "(less)";
          toggleLink.dataset.expanded = "true";
        } else {
          defines.style.display = "none";
          if (toggleLink.dataset.height) {
            summary.style.height = toggleLink.dataset.height + "px";
          }
          toggleLink.textContent = "more...";
          toggleLink.dataset.expanded = "false";
        }
      });
    });
  }

  function createFullTreeLinks() {
    queryAll(".inheritanceTree").forEach(function(toggleLink) {
      var container = toggleLink.parentElement;
      var tree = container.previousElementSibling;

      toggleLink.addEventListener("click", function(event) {
        event.preventDefault();
        var expanded = toggleLink.dataset.expanded === "true";

        if (!expanded) {
          toggleLink.dataset.height = String(tree.offsetHeight);
          container.classList.add("showAll");
          toggleLink.textContent = "(hide)";
          tree.style.height = container.offsetHeight + "px";
          toggleLink.dataset.expanded = "true";
        } else {
          container.classList.remove("showAll");
          if (toggleLink.dataset.height) {
            tree.style.height = toggleLink.dataset.height + "px";
          }
          toggleLink.textContent = "show all";
          toggleLink.dataset.expanded = "false";
        }
      });
    });
  }

  function resetSearchFrame() {
    var frame = query("#nav");

    if (frame) frame.removeAttribute("style");
    queryAll("#search a").forEach(function(link) {
      link.classList.remove("active");
      link.classList.remove("inactive");
    });
    window.focus();
  }

  function toggleSearchFrame(linkElement, link) {
    var frame = query("#nav");

    if (!frame) return;

    queryAll("#search a").forEach(function(searchLink) {
      searchLink.classList.remove("active");
      searchLink.classList.add("inactive");
    });

    if (frame.getAttribute("src") === link && isVisible(frame)) {
      frame.style.display = "none";
      queryAll("#search a").forEach(function(searchLink) {
        searchLink.classList.remove("active");
        searchLink.classList.remove("inactive");
      });
    } else {
      linkElement.classList.add("active");
      linkElement.classList.remove("inactive");
      if (frame.getAttribute("src") !== link) frame.setAttribute("src", link);
      frame.style.display = "block";
    }
  }

  function searchFrameButtons() {
    queryAll(".full_list_link").forEach(function(link) {
      if (link.dataset.yardSearchFrameBound === "true") return;

      link.addEventListener("click", function(event) {
        event.preventDefault();
        toggleSearchFrame(link, link.getAttribute("href"));
      });

      link.dataset.yardSearchFrameBound = "true";
    });

    if (appState.searchFrameGlobalsBound) return;

    window.addEventListener("message", function(event) {
      if (event.data === "navEscape") resetSearchFrame();
    });

    window.addEventListener("resize", function() {
      if (!isVisible(query("#search"))) resetSearchFrame();
    });

    appState.searchFrameGlobalsBound = true;
  }

  function linkSummaries() {
    queryAll(".summary_signature").forEach(function(signature) {
      signature.addEventListener("click", function(event) {
        if (event.target.closest("a")) return;
        var link = signature.querySelector("a");
        if (link) document.location = link.getAttribute("href");
      });
    });
  }

  function toggleSummaryCollection(toggleSelector, listSelector, cloneBuilder) {
    queryAll(toggleSelector).forEach(function(toggleLink) {
      toggleLink.addEventListener("click", function(event) {
        event.preventDefault();
        safeLocalStorage.summaryCollapsed = toggleLink.textContent;

        queryAll(toggleSelector).forEach(function(link) {
          link.textContent =
            link.textContent === "collapse" ? "expand" : "collapse";

          var container = link.parentElement.parentElement;
          var next = firstNextMatchingSibling(container, listSelector);

          if (!next) return;

          if (next.classList.contains("compact")) {
            var fullList = firstNextMatchingSibling(next, listSelector);
            toggleDisplay(next, !isVisible(next));
            toggleDisplay(fullList, !isVisible(fullList));
          } else {
            var compactList = cloneBuilder(next.cloneNode(true));
            next.parentNode.insertBefore(compactList, next);
            toggleDisplay(next, false);
          }
        });
      });
    });
  }

  function buildCompactSummary(list) {
    list.className = "summary compact";

    queryAll(".summary_desc, .note", list).forEach(function(node) {
      node.remove();
    });

    queryAll("a", list).forEach(function(link) {
      var strong = link.querySelector("strong");
      if (strong) link.innerHTML = strong.innerHTML;
      if (link.parentElement) link.parentElement.outerHTML = link.outerHTML;
    });

    return list;
  }

  function buildCompactConstants(list) {
    list.className = "constants compact";

    queryAll("dt", list).forEach(function(node) {
      var deprecated = !!node.querySelector(".deprecated");
      node.classList.add("summary_signature");
      node.textContent = node.textContent.split("=")[0];
      if (deprecated) node.classList.add("deprecated");
    });

    queryAll("pre.code", list).forEach(function(pre) {
      var dtElement = pre.parentElement.previousElementSibling;
      var tooltip = pre.textContent;
      if (dtElement.classList.contains("deprecated")) {
        tooltip = "Deprecated. " + tooltip;
      }
      dtElement.setAttribute("title", tooltip);
    });

    queryAll(".docstring, .tags, dd", list).forEach(function(node) {
      node.remove();
    });

    return list;
  }

  function summaryToggle() {
    toggleSummaryCollection(".summary_toggle", "ul.summary", buildCompactSummary);

    if (safeLocalStorage.summaryCollapsed === "collapse") {
      var toggle = query(".summary_toggle");
      if (toggle) toggle.click();
    } else {
      safeLocalStorage.summaryCollapsed = "expand";
    }
  }

  function constantSummaryToggle() {
    toggleSummaryCollection(
      ".constants_summary_toggle",
      "dl.constants",
      buildCompactConstants
    );

    if (safeLocalStorage.summaryCollapsed === "collapse") {
      var toggle = query(".constants_summary_toggle");
      if (toggle) toggle.click();
    } else {
      safeLocalStorage.summaryCollapsed = "expand";
    }
  }

  function generateTOC() {
    var fileContents = query("#filecontents");
    var content = query("#content");

    if (!fileContents || !content) return;

    var topLevel = document.createElement("ol");
    var currentList = topLevel;
    var currentItem;
    var counter = 0;
    var headings = ["h2", "h3", "h4", "h5", "h6"];
    var hasEntries = false;

    topLevel.className = "top";

    if (queryAll("#filecontents h1").length > 1) headings.unshift("h1");

    var selectors = headings.map(function(tagName) {
      return "#filecontents " + tagName;
    });

    var lastLevel = parseInt(headings[0].substring(1), 10);

    queryAll(selectors.join(", ")).forEach(function(heading) {
      var level;
      var title;
      var item;

      if (heading.closest(".method_details .docstring")) return;
      if (heading.id === "filecontents") return;

      hasEntries = true;
      level = parseInt(heading.tagName.substring(1), 10);

      if (!heading.id) {
        var proposedId = heading.getAttribute("toc-id");
        if (!proposedId) {
          proposedId = heading.textContent.replace(/[^a-z0-9-]/gi, "_");
          if (query("#" + proposedId)) {
            proposedId += counter;
            counter += 1;
          }
        }
        heading.id = proposedId;
      }

      if (level > lastLevel) {
        while (level > lastLevel) {
          if (!currentItem) {
            currentItem = document.createElement("li");
            currentList.appendChild(currentItem);
          }
          var nestedList = document.createElement("ol");
          currentItem.appendChild(nestedList);
          currentList = nestedList;
          currentItem = null;
          lastLevel += 1;
        }
      } else if (level < lastLevel) {
        while (level < lastLevel && currentList.parentElement) {
          currentList = currentList.parentElement.parentElement;
          lastLevel -= 1;
        }
      }

      title = heading.getAttribute("toc-title") || heading.textContent;
      item = document.createElement("li");
      item.innerHTML = '<a href="#' + heading.id + '">' + title + "</a>";
      currentList.appendChild(item);
      currentItem = item;
    });

    if (!hasEntries) return;

    var toc = document.createElement("div");
    toc.id = "toc";
    toc.innerHTML =
      '<p class="title hide_toc"><a href="#"><strong>Table of Contents</strong></a></p>';
    content.insertBefore(toc, content.firstChild);
    toc.appendChild(topLevel);

    var hideLink = query("#toc .hide_toc");
    if (hideLink) {
      hideLink.addEventListener("click", function(event) {
        event.preventDefault();
        var list = query("#toc .top");
        var hidden = query("#toc").classList.toggle("hidden");
        toggleDisplay(list, !hidden);
        queryAll("#toc .title small").forEach(function(node) {
          toggleDisplay(node, hidden);
        });
      });
    }
  }

  function navResizer() {
    var resizer = document.getElementById("resizer");

    if (!resizer) return;

    if (!appState.navResizerBound) {
      resizer.addEventListener(
        "pointerdown",
        function(event) {
          resizer.setPointerCapture(event.pointerId);
          event.preventDefault();
          event.stopPropagation();
        },
        false
      );
      resizer.addEventListener(
        "pointerup",
        function(event) {
          resizer.releasePointerCapture(event.pointerId);
          event.preventDefault();
          event.stopPropagation();
        },
        false
      );
      resizer.addEventListener(
        "pointermove",
        function(event) {
          if ((event.buttons & 1) === 0) return;

          safeSessionStorage.navWidth = String(event.pageX);
          queryAll(".nav_wrap").forEach(function(node) {
            node.style.width = Math.max(200, event.pageX) + "px";
          });
          event.preventDefault();
          event.stopPropagation();
        },
        false
      );

      appState.navResizerBound = true;
    }

    if (safeSessionStorage.navWidth) {
      queryAll(".nav_wrap").forEach(function(node) {
        node.style.width =
          Math.max(200, parseInt(safeSessionStorage.navWidth, 10)) + "px";
      });
    }
  }

  function navExpander() {
    if (typeof pathId === "undefined") return;

    var done = false;
    var timer = setTimeout(postMessage, 500);

    function postMessage() {
      var frame;
      if (done) return;
      clearTimeout(timer);
      frame = document.getElementById("nav");
      if (!frame || !frame.contentWindow) return;
      frame.contentWindow.postMessage({ action: "expand", path: pathId }, "*");
      done = true;
    }
  }

  function focusHashTarget() {
    var hash = window.location.hash;
    if (!hash) return;

    var targetId = hash.slice(1);
    var decodedTargetId = targetId;

    try {
      decodedTargetId = decodeURIComponent(targetId);
    } catch (error) {}

    var target =
      document.getElementById(decodedTargetId) ||
      document.getElementById(targetId);

    if (target) target.scrollIntoView();
  }

  function mainFocus() {
    focusHashTarget();
    setTimeout(function() {
      var main = query("#main");
      if (main) main.focus();
    }, 10);
  }

  function navigationChange() {
    if (appState.navigationChangeBound) return;

    window.onpopstate = focusHashTarget;
    appState.navigationChangeBound = true;
  }

  window.__app = function() {
    ready(function() {
      navResizer();
      navExpander();
      createSourceLinks();
      createDefineLinks();
      createFullTreeLinks();
      searchFrameButtons();
      linkSummaries();
      summaryToggle();
      constantSummaryToggle();
      generateTOC();
      mainFocus();
      navigationChange();
    });
  };

  window.__app();

  if (!appState.navigationListenerBound) {
    window.addEventListener(
      "message",
      async function(event) {
        if (!event.data || event.data.action !== "navigate") return;

        var response = await fetch(event.data.url);
        var text = await response.text();
        var parser = new DOMParser();
        var doc = parser.parseFromString(text, "text/html");
        var classListLink = document.getElementById("class_list_link");
        var content = doc.querySelector("#main").innerHTML;

        document.querySelector("#main").innerHTML = content;
        document.title = doc.head.querySelector("title").innerText;

        queryAll("script", document.head).forEach(function(script) {
          if (
            !script.type ||
            (script.type.indexOf("text/javascript") !== -1 && !script.src)
          ) {
            script.remove();
          }
        });

        queryAll("script", doc.head).forEach(function(script) {
          if (
            !script.type ||
            (script.type.indexOf("text/javascript") !== -1 && !script.src)
          ) {
            var newScript = document.createElement("script");
            newScript.type = "text/javascript";
            newScript.textContent = script.textContent;
            document.head.appendChild(newScript);
          }
        });

        window.__app();

        if (classListLink && document.getElementById("class_list_link")) {
          document.getElementById("class_list_link").className =
            classListLink.className;
        }

        var url = new URL(event.data.url, "http://localhost");
        var hash = decodeURIComponent(url.hash || "");
        if (hash) {
          var target = document.getElementById(hash.substring(1));
          if (target) target.scrollIntoView();
        }
        history.pushState({}, document.title, event.data.url);
      },
      false
    );

    appState.navigationListenerBound = true;
  }
})();
