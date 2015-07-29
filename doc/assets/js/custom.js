/*
 * Makes the footer responsive.
 */
$(document).ready(function() {

  $('.menu-button').click(function() {
    var menu = $('div.navbar ul');

    if(menu.css('display') === 'none') {
      menu.css({'display': 'block'});
    } else {
      menu.css({'display': 'none'});
    }
  });

  $(window).resize(function() {
    var footerHeight = $('.footer').outerHeight();

    $('body').css({
      'marginBottom': footerHeight + 'px'
    });
  });   

  $(window).resize();
});
