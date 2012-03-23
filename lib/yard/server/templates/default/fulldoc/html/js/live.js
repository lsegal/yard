function methodPermalinks() {
  if ($($('#content h1')[0]).text().match(/^Method:/)) return;

  $('#method_details .signature, #constructor_details .signature, ' +
      '.method_details .signature, #method_missing_details .signature').each(function() {
    var id = this.id;
    var match = id.match(/^(.+?)-(class|instance)_method$/);
    if (match) {
      var name = match[1];
      var scope = match[2] == "class" ? "." : ":";
      var url = window.location.pathname + scope + escape(name);
      $(this).prepend('<a class="permalink" href="' + url + '">permalink</a>');
    }
  });
}

$(methodPermalinks);
