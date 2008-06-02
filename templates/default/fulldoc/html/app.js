$(document).ready(function() {
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