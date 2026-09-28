( function( $ ){
	$.fn.dataTableExt.oApi.fnSetFilteringDelay = function ( settings, iDelay ) {
		var $dt = this;

		iDelay = iDelay || 250;

		return this.each( function ( i ) {
			$.fn.dataTableExt.iApiIndex = i;
			var $filterContainer = $dt.fnSettings().aanFeatures.f;

			if ( ( typeof $filterContainer !== "undefined" ) && $filterContainer.length ) {
				var $searchBox      = $( 'input', $filterContainer )
				  , oTimerId        = null
				  , sPreviousSearch = $searchBox.val();


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
			}
		} );
	};
} )( presideJQuery );