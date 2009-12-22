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
    $('#full_list li:even:visible').removeClass('r2').addClass('r1');
    $('#full_list li:odd:visible').removeClass('r1').addClass('r2');
    
    if ($('#full_list li:visible').size() == 0) {
      $('#noresults').fadeIn();
    }
    else {
      $('#noresults').hide();
    }
  });
  
  $('#search input').focus();
  $('#full_list').after("<div id='noresults'>No results were found.</div>")
}

function linkList() {
  $('#full_list li, #full_list li a').click(function() {
    var win = window.parent;
    if (window.top.frames.main) {
      win = window.top.frames.main;
      var title = $('html head title', win.document).text();
      $('html head title', window.parent.document).text(title);
    }
    if (this.tagName.toLowerCase() == "a") {
      win.location = this.href;
    }
    else {
      win.location = $(this).find('a').attr('href');
    }
    return false;
  });
}

function framesInit() {
  if (window.top.frames.main) {
    document.getElementById('base_target').target = 'main';
    document.body.className = 'frames';
    $('li small').each(function() {
      $(this).text($(this).text().replace(/^\(|\)$/g, ''))
    });
  }
}

$(framesInit);
$(fullListSearch);
$(linkList);
