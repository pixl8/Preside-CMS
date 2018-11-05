( function( $ ){

	$( ".preview-recipient-picker-link" ).each( function(){
		var $link = $( this )
		  , target = $( this ).attr( "href" )
		  , title = $( this ).attr( "title" )
		  , browserIframeModal;


		browserIframeModal = new PresideIframeModal( target, "100%", "100%", {}, {
			title      : title,
			className  : "full-screen-dialog",
			buttonList : [ "cancel" ]
		} );

		$link.on( "click", function( e ){
			e.preventDefault();

			browserIframeModal.open();
		} );
	} );

} )( presideJQuery );