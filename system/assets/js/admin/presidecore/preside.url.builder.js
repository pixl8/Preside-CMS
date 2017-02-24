var buildAjaxLink = ( function(){
	var endpoint = ( cfrequest || {} ).ajaxEndpoint || ""
	  , qsDelim  = endpoint.indexOf( "?" ) === -1 ? "?" : "&";

	return function( action, options ){
		var link = endpoint + qsDelim + "action=" + action
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
	var endpoint = ( cfrequest || {} ).adminBaseUrl || "/"
	  , siteId   = ( cfrequest || {} ).siteId || "";

	return function( handler, action, options ){
		var link = endpoint
		  , option, delim="?";


		if ( handler ) {
			link += handler.replace( /\./g, "/" ) + "/";
			if ( action ) {
				link += action + "/";
			}
		}

		options = options ? options : {};
		if ( siteId.length ) {
			options._sid = siteId;
		}
		for ( option in options ) {
			link += ( delim + option + "=" + options[ option ] );
			delim = "&";
		}

		return link;
	};
} )();

var buildLink = ( function(){
	var endpoint = "/";

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