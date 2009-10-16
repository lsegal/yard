function fullListSearch() {
  $('#search input').keyup(function() {
    var value = this.value.toLowerCase();
    if (value == "") {
      $('#full_list li').show();
    }
    else {
      $('#full_list li').each(function() {
        if ($(this).children('a').text().toLowerCase().indexOf(value) == -1) {
          $(this).hide();
        }
        else {
          $(this).show();
        }
      });
    }
    $('#full_list li:even:visible').attr('class', 'r1');
    $('#full_list li:odd:visible').attr('class', 'r2');
  });
}

$(fullListSearch);