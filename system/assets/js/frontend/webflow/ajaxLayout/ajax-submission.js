( function( $ ){

	var $ajaxSubmitContainer = $( ".webflow-form-ajax-submit" );

	if ( $ajaxSubmitContainer.length > 0 ) {
		$ajaxSubmitContainer.on( "submit", "form", function(event) {
			event.preventDefault();

			const formData = $(this).serialize();

			$.ajax( {
				  url  : $(this).attr( "action" )
				, type : 'POST'
				, data : formData
			} )
			.success( function( response ) {
				$ajaxSubmitContainer.html( response );
			} );
		} );

		$ajaxSubmitContainer.on( "click", ".webflow-prev-btn", function(event) {
			event.preventDefault();

			$.ajax( {
				  url  : $(this).attr( "href" )
				, type : 'GET'
			} )
			.success( function( response ) {
				$ajaxSubmitContainer.html( response );
			} );
		});
	}

} )( jQuery || presideJQuery );