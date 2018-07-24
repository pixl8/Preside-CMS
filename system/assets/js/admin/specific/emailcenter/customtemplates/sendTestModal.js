( function( $ ){

	$( ".send-test-email-link" ).each( function(){
		var $link = $( this )
		  , target = $( this ).attr( "href" )
		  , title = $( this ).attr( "title" )
		  , browserIframeModal, callbacks;

		callbacks = {
			onLoad : function( iframe ) {
				configModalIframe = iframe;
			},
			onok : function(){
				$( configModalIframe.document ).find( ".send-test-email-form" ).get( 0 ).submit();

				return false;
			}
		};

		browserIframeModal = new PresideIframeModal( target, "100%", "100%", callbacks, {
			title      : title,
			className  : "full-screen-dialog",
			buttonList : [ "ok", "cancel" ]
		} );

		$link.on( "click", function( e ){
			e.preventDefault();

			browserIframeModal.open();
		} );
	} );

} )( presideJQuery );