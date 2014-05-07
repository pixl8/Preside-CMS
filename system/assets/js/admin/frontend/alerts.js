( function( $ ){

	$.alert = function( options ) {
		var defaults = {
			  type : "success"
			, message : ""
			, sticky : false
		};

		options = $.extend( defaults, options );
		options.type = options.type.toLowerCase();

		if ( typeof options.title === "undefined" ) {
			options.title = i18n.translateResource( "cms:frontendadmin." + options.type + ".alert.title" )
		}

		$.gritter.add({
			  title      : options.title
			, text       : options.message
			, class_name : "gritter-" + options.type + " preside-frontend-msgbox"
			, sticky     : options.sticky
		});
	}

} )( presideJQuery );