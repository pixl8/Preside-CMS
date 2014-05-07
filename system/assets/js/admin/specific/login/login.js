( function( $ ){

	$( ".login-box-toggler" ).click( function( e ){
		var $this      = $( this )
		  , $parentBox = $this.parents( ".widget-box:first" )
		  , $targetBox = $( $this.get(0).hash );

		$parentBox.removeClass( "visible" );
		$targetBox.addClass( "visible" );

		e.preventDefault();

	} );

} )( presideJQuery );