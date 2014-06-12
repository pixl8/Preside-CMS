var i18n = ( function(){

	var bundle = typeof cfrequest.resourceBundle === "undefined" ? {} : cfrequest.resourceBundle
	  , translateResource;

	translateResource = function( uri, args ) {
		var defaultValue = ( args || {} ).defaultValue || uri
		  , resource     = bundle[ uri ] || defaultValue
 		  , i, regex;

		if ( resource.length && ( args || {} ).data ) {
			for( i=0; i < args.data.length; i++ ){
				regex = new RegExp( "\\{" + (i+1) + "\\}", "g" );
				resource = resource.replace( regex, args.data[i] );
			}
		}

		return resource;
	};

	return {
		translateResource : translateResource
	};

} )();