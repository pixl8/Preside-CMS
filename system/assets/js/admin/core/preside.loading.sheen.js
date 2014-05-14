( function( $ ){

	var showSheen, hideSheen;

	showSheen = function( $container ){
		var $sheen = $( '<div class="preside-loading-sheen"></div>' );

		$container.append( $sheen );
		$sheen.hide();
		$sheen.fadeIn( "fast" );
	};

	hideSheen = function( $container ){
		var $sheen = $container.find( ".preside-loading-sheen" );

		if ( $sheen.length ) {
			$sheen.fadeOut( "fast", function(){
				$sheen.remove();
			} );
		}
	}


	$.fn.presideLoadingSheen = function( show ){
		return this.each( function(){
			var $container = $(this);
			show ? showSheen( $container ) : hideSheen( $container );
		} );
	};

} )( presideJQuery );