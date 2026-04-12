(function() {
  var clicked = null;
  var searchTimeout = null;
  var searchCache = [];
  var caseSensitiveMatch = false;
  var ignoreKeyCodeMin = 8;
  var ignoreKeyCodeMax = 46;
  var commandKey = 91;

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
    if (window.getComputedStyle(element).display === "none") return false;
    if (element.parentElement && element.parentElement !== document.body) {
      return isVisible(element.parentElement);
    }
    return true;
  }

  RegExp.escape = function(text) {
    return text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");
  };

  function ready(callback) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", callback, { once: true });
    } else {
      callback();
    }
  }

  function escapeShortcut() {
    document.addEventListener("keydown", function(event) {
      if (event.key === "Escape") {
        window.parent.postMessage("navEscape", "*");
      }
    });
  }

  function clearSearchTimeout() {
    clearTimeout(searchTimeout);
    searchTimeout = null;
  }

  function setClicked(item) {
    queryAll("#full_list li.clicked").forEach(function(node) {
      node.classList.remove("clicked");
    });
    clicked = item;
    if (clicked) clicked.classList.add("clicked");
  }

  function enableLinks() {
    queryAll("#full_list li").forEach(function(item) {
      item.addEventListener("click", function(event) {
        var targetLink;
        var mouseEvent;
        var url;

        setClicked(item);
        event.stopPropagation();

        if (window.origin === "null") {
          if (event.target.tagName === "A") return true;

          targetLink = item.querySelector(":scope > .item .object_link a");
          if (!targetLink) return false;
          mouseEvent = new MouseEvent("click", {
            bubbles: true,
            cancelable: true,
            view: event.view || window,
            detail: event.detail,
            screenX: event.screenX,
            screenY: event.screenY,
            clientX: event.clientX,
            clientY: event.clientY,
            ctrlKey: event.ctrlKey,
            shiftKey: event.shiftKey,
            altKey: event.altKey,
            metaKey: event.metaKey,
            button: event.button,
            buttons: event.buttons,
            relatedTarget: event.relatedTarget
          });
          targetLink.dispatchEvent(mouseEvent);
          event.preventDefault();
        } else {
          url = item.querySelector(".object_link a").getAttribute("href");
          try {
            url = new URL(url, window.location.href).href;
          } catch (error) {}
          window.top.postMessage({ action: "navigate", url: url }, "*");
        }
        return false;
      });
    });
  }

  function toggleItem(toggle) {
    var item = toggle.parentElement.parentElement;
    var expanded = item.classList.contains("collapsed");

    item.classList.toggle("collapsed");
    toggle.setAttribute("aria-expanded", expanded ? "true" : "false");
    highlight();
  }

  function enableToggles() {
    queryAll("#full_list a.toggle").forEach(function(toggle) {
      toggle.addEventListener("click", function(event) {
        event.stopPropagation();
        event.preventDefault();
        toggleItem(toggle);
      });

      toggle.addEventListener("keypress", function(event) {
        if (event.key !== "Enter") return;
        event.stopPropagation();
        event.preventDefault();
        toggleItem(toggle);
      });
    });
  }

  function populateSearchCache() {
    queryAll("#full_list li .item").forEach(function(node) {
      var link = query(".object_link a", node);
      if (!link) return;

      searchCache.push({
        node: node,
        link: link,
        name: link.textContent,
        fullName: link.getAttribute("title").split(" ")[0]
      });
    });
  }

  function enableSearch() {
    var input = query("#search input");
    var fullList = query("#full_list");

    if (!input || !fullList) return;

    input.addEventListener("keyup", function(event) {
      if (ignoredKeyPress(event)) return;
      if (input.value === "") {
        clearSearch();
      } else {
        performSearch(input.value);
      }
    });

    fullList.insertAdjacentHTML(
      "afterend",
      "<div id='noresults' role='status' style='display: none'></div>"
    );
  }

  function ignoredKeyPress(event) {
    return (
      (event.keyCode > ignoreKeyCodeMin && event.keyCode < ignoreKeyCodeMax) ||
      event.keyCode === commandKey
    );
  }

  function clearSearch() {
    clearSearchTimeout();
    queryAll("#full_list .found").forEach(function(node) {
      var link = query(".object_link a", node);
      node.classList.remove("found");
      link.textContent = link.textContent;
    });
    query("#full_list").classList.remove("insearch");
    query("#content").classList.remove("insearch");
    if (clicked) {
      var current = clicked.parentElement;
      while (current) {
        if (current.tagName === "LI") current.classList.remove("collapsed");
        if (current.id === "full_list") break;
        current = current.parentElement;
      }
    }
    highlight();
  }

  function performSearch(searchString) {
    clearSearchTimeout();
    query("#full_list").classList.add("insearch");
    query("#content").classList.add("insearch");
    query("#noresults").textContent = "";
    query("#noresults").style.display = "none";
    partialSearch(searchString, 0);
  }

  function partialSearch(searchString, offset) {
    var lastRowClass = "";
    var i;

    for (i = offset; i < Math.min(offset + 50, searchCache.length); i += 1) {
      var item = searchCache[i];
      var searchName =
        searchString.indexOf("::") !== -1 ? item.fullName : item.name;
      var matchRegexp = new RegExp(
        buildMatchString(searchString),
        caseSensitiveMatch ? "" : "i"
      );

      if (!searchName.match(matchRegexp)) {
        item.node.classList.remove("found");
        item.link.textContent = item.link.textContent;
      } else {
        item.node.classList.add("found");
        if (lastRowClass) item.node.classList.remove(lastRowClass);
        item.node.classList.add(lastRowClass === "r1" ? "r2" : "r1");
        lastRowClass = item.node.classList.contains("r1") ? "r1" : "r2";
        item.link.innerHTML = item.name.replace(matchRegexp, "<strong>$&</strong>");
      }
    }

    if (i === searchCache.length) {
      searchDone();
    } else {
      searchTimeout = setTimeout(function() {
        partialSearch(searchString, i);
      }, 0);
    }
  }

  function searchDone() {
    var found = queryAll("#full_list li").filter(isVisible).length;

    searchTimeout = null;
    highlight();

    if (found === 0) {
      query("#noresults").textContent = "No results were found.";
    } else {
      query("#noresults").textContent = "There are " + found + " results.";
    }
    query("#noresults").style.display = "block";
    query("#content").classList.remove("insearch");
  }

  function buildMatchString(searchString) {
    var regexSearchString;

    caseSensitiveMatch = /[A-Z]/.test(searchString);
    regexSearchString = RegExp.escape(searchString);
    if (caseSensitiveMatch) {
      regexSearchString +=
        "|" +
        searchString
          .split("")
          .map(function(character) {
            return RegExp.escape(character);
          })
          .join(".+?");
    }
    return regexSearchString;
  }

  function highlight() {
    queryAll("#full_list li")
      .filter(isVisible)
      .forEach(function(item, index) {
        item.classList.remove("even");
        item.classList.remove("odd");
        item.classList.add(index % 2 === 0 ? "odd" : "even");
      });
  }

  function isInView(element) {
    var rect = element.getBoundingClientRect();
    var windowHeight =
      window.innerHeight || document.documentElement.clientHeight;
    return rect.left >= 0 && rect.bottom <= windowHeight;
  }

  function expandTo(path) {
    var target = document.getElementById("object_" + path);

    if (!target) return;

    target.classList.add("clicked");
    target.classList.remove("collapsed");

    var current = target.parentElement;
    while (current && current.id !== "full_list") {
      if (current.tagName === "LI") current.classList.remove("collapsed");
      current = current.parentElement;
    }

    queryAll("a.toggle", target).forEach(function(toggle) {
      toggle.setAttribute("aria-expanded", "true");
    });

    current = target.parentElement;
    while (current && current.id !== "full_list") {
      if (current.tagName === "LI") {
        var toggle = current.querySelector(":scope > div > a.toggle");
        if (toggle) toggle.setAttribute("aria-expanded", "true");
      }
      current = current.parentElement;
    }

    if (!isInView(target)) {
      window.scrollTo(
        window.scrollX,
        target.getBoundingClientRect().top + window.scrollY - 250
      );
      highlight();
    }
  }

  function windowEvents(event) {
    var msg = event.data;
    if (msg.action === "expand") {
      expandTo(msg.path);
    }
    return false;
  }

  window.addEventListener("message", windowEvents, false);

  ready(function() {
    escapeShortcut();
    enableLinks();
    enableToggles();
    populateSearchCache();
    enableSearch();
  });
})();
