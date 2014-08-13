( function( $ ){

	if ( typeof cfrequest.downloadingVersion !== 'undefined' ) {
		var checkUrl = buildAjaxLink( "updateManager.downloadIsComplete" )
		  , checkMethod, checkResponseHandler;

		checkMethod = function(){
			$.ajax({
				  url     : checkUrl
				, method  : "GET"
				, data    : { version : cfrequest.downloadingVersion }
				, success : checkResponseHandler
			});
		};

		checkResponseHandler = function( resp ){
			if ( typeof resp.complete !== "undefined" && resp.complete ) {
				window.location.reload();
			}
		};

		window.setInterval( checkMethod, 5000 );
	}

} )( presideJQuery );