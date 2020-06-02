( function( $ ){

	var $statusControls = $( ".formbuilder-status-controls .status-item.enabled" );

	$statusControls.on( "click", function( e ){
		var $statusControl = $( this )
		  , prompt         = $statusControl.data( "prompt" )
		  , toggleEndpoint = $statusControl.data( "endpoint" );

		e.preventDefault();

		presideBootbox.confirm( prompt, function( confirmed ) {
			if ( confirmed ) {
				document.location = toggleEndpoint;
			}
		});
	} );

} )( presideJQuery );