$(function () {
    $('.aj-nav').click(function (e) {
        e.preventDefault();
        $(this).parent().siblings().find('ul').slideUp();
        $(this).next().slideToggle();
    });

    $('table').addClass('table');
    $('#menu-spinner-button').click(function () {
        $('#sub-nav-collapse').slideToggle();
    });

    $(window).resize(function () {
        // Remove transition inline style on large screens
        if ($(window).width() >= 768)
            $('#sub-nav-collapse').removeAttr('style');
    });
});

function toggleCodeBlocks() {
    codeBlockState = (codeBlockState + 1) % 3;
    localStorage.setItem("codeBlockState", codeBlockState);
    setCodeBlockStyle(codeBlockState);
}

//Initialize CodeBlock Visibility Settings
$(function () {
    toggleCodeBlockBtn = $('#toggleCodeBlockBtn')[0];
    codeBlockView = $('.right-column');
    codeBlocks = $('.content-page article > pre');
    codeBlockState = localStorage.getItem("codeBlockState");
    if (!codeBlockState) {
        codeBlockState = 0;
        localStorage.setItem("codeBlockState", codeBlockState);
    } else codeBlockState = parseInt(codeBlockState);
    if (!codeBlockView.size()) return;
    if (!codeBlocks.size()) {
        codeBlockState = 2;
        toggleCodeBlockBtn.classList.add('hidden');
    }
    setCodeBlockStyle(codeBlockState);
});