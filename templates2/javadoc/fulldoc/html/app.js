$(document).ready(function() {
    // Set the title of this page as the index title
    if (parent && parent.document) {
        $('html head title', parent.document).text($('html head title').text());
    }
    
    // Setup the view source links
    $(".section.source a.source_link").toggle(
        function() {
            $(this).text('Hide source');
            $(this).parent().next().show();
        },
        function() {
            $(this).text('View source');
            $(this).parent().next().hide();
        }
    );
});