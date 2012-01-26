function featureSearchFrameLinks() {
    $('#tag_list_link').click(function() {
        toggleSearchFrame(this, relpath + 'tag_list.html');
    });
}

$(featureSearchFrameLinks);
