function createSourceLinks() {
    $('#method_details .source_code, #constructor_details .source_code, #method_missing_details .source_code').
        before("<span class='showSource'>[<a href='#' class='toggleSource'>View source</a>]</span>");
    $('.toggleSource').toggle(function() {
       $(this).parent().next().slideDown(100);
       $(this).text("Hide source");
    },
    function() {
        $(this).parent().next().slideUp(100);
        $(this).text("View source");
    });
}

function createDefineLinks() {
    var tHeight = 0;
    $('.defines').after(" <a href='#' class='toggleDefines'>more...</a>");
    $('.toggleDefines').toggle(function() {
        tHeight = $(this).parent().prev().height();
        $(this).prev().show();
        $(this).parent().prev().height($(this).parent().height());
        $(this).text("(less)");
    },
    function() {
        $(this).prev().hide();
        $(this).parent().prev().height(tHeight);
        $(this).text("more...")
    });
}

function createFullTreeLinks() {
    var tHeight = 0;
    $('.inheritanceTree').toggle(function() {
        tHeight = $(this).parent().prev().height();
        $(this).prev().prev().hide();
        $(this).prev().show();
        $(this).text("(hide)");
        $(this).parent().prev().height($(this).parent().height());
    },
    function() {
        $(this).prev().prev().show();
        $(this).prev().hide();
        $(this).parent().prev().height(tHeight);
        $(this).text("show all")
    });
}

function fixBoxInfoHeights() {
    $('dl.box dd.r1, dl.box dd.r2').each(function() {
       $(this).prev().height($(this).height()); 
    });
}

function searchFrameLinks() {
  $('#method_list_link').click(function() {
    toggleSearchFrame(relpath + 'method_list.html');
  });

  $('#class_list_link').click(function() {
    toggleSearchFrame(relpath + 'class_list.html');
  });

  $('#file_list_link').click(function() {
    toggleSearchFrame(relpath + 'file_list.html');
  });
}

function toggleSearchFrame(link) {
  var frame = $('#search_frame');
  if (frame.attr('src') == link && frame.css('display') != "none") frame.slideUp(100);
  else frame.attr('src', link).slideDown(100);
}

$(createSourceLinks);
$(createDefineLinks);
$(createFullTreeLinks);
$(fixBoxInfoHeights);
$(searchFrameLinks);