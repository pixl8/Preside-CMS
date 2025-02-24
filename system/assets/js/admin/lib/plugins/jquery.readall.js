/*
 * jQuery.ReadAll ia a jQuery plugin to shrink large blocks of content and place a read more button below.
 * Created by Anders Fj�llstr�m - anders@morriz.net - http://www.morriz.net
 * For documentation see https://github.com/morriznet/jquery.readall
 * Released under MIT license
 * version 1.1
 */

(function ($) {
    $.fn.readall = function (options) {
        var settings = $.extend({
            // Default values
            showheight:       $(this).data( "read-all-height" ) || 96,                                 // height to show
            showrows:         $(this).data( "read-all-rows" )   || null,                                  // rows to show (overrides showheight)
            animationspeed:   $(this).data( "animation-speed" ) || 200,                                // speed of transition
            btnTextShowmore:  $(this).data( "show-more-text" )  || i18n.translateResource( "cms:show.more.btn" ), // text shown on button to show more
            btnTextShowless:  $(this).data( "show-less-text" )  || i18n.translateResource( "cms:show.less.btn" ), // text shown on button to show less
            btnClassShowmore: $(this).data( "show-more-class" ) || 'collapsible-content-btn btn-link', // class(es) on button to show more
            btnClassShowless: $(this).data( "show-less-class" ) || 'collapsible-content-btn btn-link'  // class(es) on button to show less

        }, options);
        $(this).each(function () {
            var $this = $(this),
                fullheight = function () { return $this[0].scrollHeight; },
                wrapperclass = 'readall-wrapper',
                hiddenclass = 'readall-hide';
            if (settings.showrows != null) {
                var lineHeight = Math.floor(parseFloat($this.css('font-size')) * 1.5);
                settings.showheight = lineHeight * settings.showrows;
            }
            $this.addClass('readall').css({ 'overflow': 'hidden' });

            var onResize = function (event) {
                // on resize check if readall is needed
                var _button = $this.parent().find('button.' + settings.btnClassShowmore.replace(/\s+/g, '.') + ', button.' + settings.btnClassShowless.replace(/\s+/g, '.'));
                if (fullheight() > settings.showheight + $(_button).outerHeight()) {
                    if (!$(_button).is(':visible') || event == null) {
                        $this.css({ 'height': settings.showheight + 'px', 'max-height': settings.showheight + 'px' });
                        $(_button).text(settings.btnTextShowmore);
                        $this.addClass(hiddenclass);
                        $(_button).removeClass(settings.btnClassShowless).addClass(settings.btnClassShowmore);
                        $(_button).show();
                    }
                } else {
                    if ($(_button).is(':visible') || event == null) {
                        $this.css({ 'height': '', 'max-height': '' });
                        $this.removeClass(hiddenclass);
                        $(_button).hide();
                    }
                }
            };

            if ($this.parent().not(wrapperclass)) {
                $this.wrap($('<div />').addClass(wrapperclass));
                var _button = $('<button />').addClass(settings.btnClassShowmore).text(settings.btnTextShowmore).on('click', function (e) {
                    e.preventDefault();
                    if ($this.hasClass(hiddenclass)) {
                        $this.css({ 'height': settings.showheight + 'px', 'max-height': '' }).animate({ height: fullheight() + 'px' }, settings.animationspeed, function () {
                            $this.css({ 'height': '' });
                            $(_button).text(settings.btnTextShowless);
                        });
                    } else {
                        $this.animate({ 'height': settings.showheight + 'px' }, settings.animationspeed, function () {
                            $this.css({ 'max-height': settings.showheight + 'px' });
                            $(_button).text(settings.btnTextShowmore);
                        });
                    }
                    $this.toggleClass(hiddenclass);
                    $(this).toggleClass(settings.btnClassShowmore).toggleClass(settings.btnClassShowless);
                });
                $this.after(_button);

                $(window).on('orientationchange resize', onResize);

                onResize(null);
            }
        });
        return this;
    };
}(presideJQuery));