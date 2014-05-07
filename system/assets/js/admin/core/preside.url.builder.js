var buildAjaxLink = ( function(){
	var endpoint = ( cfrequest || {} ).ajaxEndpoint || "";

	return function( action, options ){
		var link = endpoint + "?action=" + action
		  , option;

		if ( options ) {
			for ( option in options ) {
				link += ( "&" + option + "=" + options[ option ] );
			}
		}

		return link;
	};
} )();

var buildAdminLink = ( function(){
	var endpoint = ( cfrequest || {} ).adminBaseUrl || "/";

	return function( handler, action, options ){
		var link = endpoint
		  , option, delim="?";

		if ( handler ) {
			link += handler.replace( /\./g, "/" ) + "/";
			if ( action ) {
				link += action + "/";
			}
		}

		if ( options ) {
			for ( option in options ) {
				link += ( delim + option + "=" + options[ option ] );
				delim = "&";
			}
		}

		return link;
	};
} )();