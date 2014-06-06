( function( $ ){
	$.fn.dataTableExt.oApi.fnSetFilteringDelay = function ( settings, iDelay ) {
		var $dt = this;

		iDelay = iDelay || 250;

		return this.each( function ( i ) {
			var $searchBox      = $( 'input', $dt.fnSettings().aanFeatures.f )
			  , oTimerId        = null
			  , sPreviousSearch = $searchBox.val();

			$.fn.dataTableExt.iApiIndex = i;

			$searchBox.unbind( 'keyup' ).bind( 'keyup', function() {
				if ( sPreviousSearch === null || sPreviousSearch != $searchBox.val() ) {
					sPreviousSearch = $searchBox.val();

					window.clearTimeout( oTimerId );
					oTimerId = window.setTimeout( function() {
						$.fn.dataTableExt.iApiIndex = i;
						$dt.fnFilter( $searchBox.val() );
					}, iDelay );
				}
			});
		} );
	};
} )( presideJQuery );