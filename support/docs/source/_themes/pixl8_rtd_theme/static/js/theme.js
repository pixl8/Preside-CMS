// $( document ).ready(function() {
//     // Shift nav in mobile when clicking the menu.
//     $(document).on('click', "[data-toggle='wy-nav-top']", function() {
//       $("[data-toggle='wy-nav-shift']").toggleClass("shift");
//       $("[data-toggle='rst-versions']").toggleClass("shift");
//     });
//     // Close menu when you click a link.
//     $(document).on('click', ".wy-menu-vertical .current ul li a", function() {
//       $("[data-toggle='wy-nav-shift']").removeClass("shift");
//       $("[data-toggle='rst-versions']").toggleClass("shift");
//     });
//     // Make tables responsive
//     $("table.docutils:not(.field-list)").wrap("<div class='wy-table-responsive'></div>");

//     // crazy TOC hack
//     var $pageToc   = $( '#page-toc' )
//       , $pageTitle = $pageToc.prev().find( "h1:first" );

//     $pageToc.insertAfter( $pageTitle );
// });

// window.SphinxRtdTheme = (function (jquery) {
//     var stickyNav = (function () {
//         var navBar,
//             win,
//             stickyNavCssClass = 'stickynav',
//             applyStickNav = function () {
//                 if (navBar.height() <= win.height()) {
//                     navBar.addClass(stickyNavCssClass);
//                 } else {
//                     navBar.removeClass(stickyNavCssClass);
//                 }
//             },
//             enable = function () {
//                 applyStickNav();
//                 win.on('resize', applyStickNav);
//             },
//             init = function () {
//                 navBar = jquery('nav.wy-nav-side:first');
//                 win    = jquery(window);
//             };
//         jquery(init);
//         return {
//             enable : enable
//         };
//     }());
//     return {
//         StickyNav : stickyNav
//     };
// }($));

// ( function( $ ){

//     function scroll_if_anchor( href ) {
//         href = typeof(href) == "string" ? href : $(this).attr("href");

//         var fromTop = 65;

//         if ( href.indexOf( "#" ) == 0 ) {
//             var $target = $(href);

//             if ( $target.length ) {
//                 $('html, body').animate( { scrollTop: $target.offset().top - fromTop } );
//                 if ( history && "pushState" in history ) {
//                     history.pushState( {}, document.title, window.location.pathname + href );
//                     return false;
//                 }
//             }
//         }
//     }

//     $( "body" ).on( "click", "a", scroll_if_anchor );

//     $( function(){
//         scroll_if_anchor( window.location.hash );
//     } );
// } )( jQuery );