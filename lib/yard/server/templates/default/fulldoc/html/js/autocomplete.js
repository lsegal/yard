(function() {
  function query(selector, root) {
    return (root || document).querySelector(selector);
  }

  function ready(callback) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", callback, { once: true });
    } else {
      callback();
    }
  }

  function createAutocomplete(input) {
    var form = input.form;
    var results = document.createElement("div");
    var list = document.createElement("ul");
    var requestTimer = null;
    var controller = null;
    var items = [];
    var activeIndex = -1;
    var blurTimer = null;

    if (!form) return;

    results.className = "ac_results";
    results.hidden = true;
    results.setAttribute("role", "listbox");
    results.id = input.id + "_results";
    list.setAttribute("role", "presentation");
    results.appendChild(list);
    input.setAttribute("autocomplete", "off");
    input.setAttribute("aria-autocomplete", "list");
    input.setAttribute("aria-controls", results.id);
    input.setAttribute("aria-expanded", "false");
    form.appendChild(results);

    function syncResultsWidth() {
      results.style.width = input.offsetWidth + "px";
    }

    function hideResults() {
      results.hidden = true;
      input.setAttribute("aria-expanded", "false");
      input.removeAttribute("aria-activedescendant");
      activeIndex = -1;
      items = [];
      list.innerHTML = "";
    }

    function setActive(index) {
      if (!items.length) return;
      activeIndex = (index + items.length) % items.length;
      items.forEach(function(item, itemIndex) {
        item.element.classList.toggle("ac_over", itemIndex === activeIndex);
      });
      input.setAttribute("aria-activedescendant", items[activeIndex].element.id);
    }

    function selectItem(item) {
      input.value = item.values[1];
      window.location.href = item.values[3];
    }

    function renderItems(lines) {
      syncResultsWidth();
      list.innerHTML = "";
      items = lines.map(function(line, index) {
        var values = line.split(",");
        var element = document.createElement("li");
        var label = document.createElement("span");
        var namespace = document.createElement("small");

        element.id = results.id + "_item_" + index;
        element.setAttribute("role", "option");
        element.className = index % 2 === 0 ? "ac_even" : "ac_odd";
        label.textContent = values[0];
        element.appendChild(label);

        if (values[1] !== "") {
          namespace.textContent = "(" + values[1] + ")";
          element.appendChild(document.createTextNode(" "));
          element.appendChild(namespace);
        }

        element.addEventListener("mouseenter", function() {
          setActive(index);
        });
        element.addEventListener("mousedown", function(event) {
          event.preventDefault();
          selectItem(items[index]);
        });

        list.appendChild(element);

        return { element: element, values: values };
      });

      if (items.length) {
        results.hidden = false;
        input.setAttribute("aria-expanded", "true");
        setActive(0);
      } else {
        hideResults();
      }
    }

    function fetchResults(term) {
      if (controller) controller.abort();
      controller = new AbortController();
      input.classList.add("ac_loading");

      fetch(
        form.action +
          "?q=" +
          encodeURIComponent(term) +
          "&_=" +
          new Date().getTime(),
        {
          headers: {
            "X-Requested-With": "XMLHttpRequest"
          },
          signal: controller.signal
        }
      )
        .then(function(response) {
          return response.text();
        })
        .then(function(text) {
          var lines = text
            .split("\n")
            .map(function(line) {
              return line.trim();
            })
            .filter(Boolean);

          renderItems(lines);
        })
        .catch(function(error) {
          if (error.name !== "AbortError") hideResults();
        })
        .finally(function() {
          input.classList.remove("ac_loading");
        });
    }

    input.addEventListener("input", function() {
      clearTimeout(requestTimer);
      if (blurTimer) clearTimeout(blurTimer);

      if (!input.value.trim()) {
        hideResults();
        return;
      }

      requestTimer = setTimeout(function() {
        fetchResults(input.value.trim());
      }, 200);
    });

    input.addEventListener("keydown", function(event) {
      if (results.hidden && (event.key === "ArrowDown" || event.key === "ArrowUp")) {
        if (!input.value.trim()) return;
        fetchResults(input.value.trim());
        return;
      }

      if (event.key === "ArrowDown") {
        event.preventDefault();
        setActive(activeIndex + 1);
      } else if (event.key === "ArrowUp") {
        event.preventDefault();
        setActive(activeIndex - 1);
      } else if (event.key === "Enter") {
        if (activeIndex >= 0 && items[activeIndex]) {
          event.preventDefault();
          selectItem(items[activeIndex]);
        }
      } else if (event.key === "Escape") {
        hideResults();
      }
    });

    input.addEventListener("blur", function() {
      blurTimer = setTimeout(hideResults, 150);
    });

    input.addEventListener("focus", function() {
      syncResultsWidth();
      if (items.length) {
        results.hidden = false;
        input.setAttribute("aria-expanded", "true");
      }
    });

    document.addEventListener("click", function(event) {
      if (!form.contains(event.target)) hideResults();
    });

    window.addEventListener("resize", syncResultsWidth);
    syncResultsWidth();
  }

  ready(function() {
    var input = query("#search_box");
    if (input) createAutocomplete(input);
  });
})();
