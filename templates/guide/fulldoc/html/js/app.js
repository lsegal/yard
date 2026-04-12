function generateTOC() {
  var fileContents = document.getElementById("filecontents");
  var tocRoot = document.getElementById("toc");
  var topLevel = document.createElement("ol");
  var currentList = topLevel;
  var lastLevel = 1;
  var currentItem = null;
  var counter = 0;
  var headings;
  var hasEntries = false;

  if (!fileContents || !tocRoot) return;

  topLevel.className = "top";
  headings = fileContents.querySelectorAll(
    ":scope > h1, :scope > h2, :scope > h3, :scope > h4, :scope > h5, :scope > h6"
  );

  Array.prototype.forEach.call(headings, function(heading) {
    var level;
    var item;
    var link;

    if (heading.id === "filecontents") return;
    hasEntries = true;
    level = parseInt(heading.tagName.substring(1), 10);

    if (!heading.id) {
      var proposedId = heading.textContent.replace(/[^a-z0-9-]/gi, "_");
      if (document.getElementById(proposedId)) proposedId += counter++;
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

    item = document.createElement("li");
    link = document.createElement("a");
    link.href = "#" + heading.id;
    link.textContent = heading.textContent;
    item.appendChild(link);
    currentList.appendChild(item);
    currentItem = item;
  });

  if (!hasEntries) return;
  tocRoot.appendChild(topLevel);
}
