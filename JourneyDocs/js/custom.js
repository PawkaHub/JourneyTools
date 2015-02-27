$(document).ready(function () {
    $('.aj-nav').click(function (e) {
        e.preventDefault();
        $(this).addClass("opened");
        var text = $(this).text().replace(/\s+/g, '-').toLowerCase();
        if (localStorage.getItem(text + "-opened") === "true") {
            //It's already opened, set it's flag to disabled for page reloads
            localStorage.setItem(text + "-opened","false");
        } else {
            //Otherwise, set it to open
            localStorage.setItem(text + "-opened","true");
        }
        $(this).next().slideToggle();
    });

    //Get all nav items and reopen them based on local storage
    ajNav = $('.aj-nav');
    ajNav.each(function(){
        var text = $(this).text().replace(/\s+/g, '-').toLowerCase();
        if (localStorage.getItem(text + "-opened") === "true") {
            console.log(text);
            //If it exists in local storage, open it
            //$(this).next().slideToggle();
        }
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
        if (toggleCodeBlockBtn)
            toggleCodeBlockBtn.classList.add('hidden');
    }
    //setCodeBlockStyle(codeBlockState);
});