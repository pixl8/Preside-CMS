( function( $ ) {

	$( '[name="redirect_type"]' ).on( 'change', function( e ) {
		var $this      = $( this )
		  , $formGroup = $this.closest( '.form-group' )
		;

		$formGroup.removeClass( "has-warning has-error" );
		$( '.help-block', $formGroup ).remove();

		if ( $this.val() != "302" ) {
			$formGroup.addClass( "has-warning" );

			$( '.clearfix', $formGroup ).after( '<div class="help-block">' + cfrequest.redirectType301Warning + '</div>' );
		}
	} ).trigger( 'change' );

	$( '[name="exact_match_only"]' ).on( 'change', function( e ) {
		var $this      = $( this )
		  , $formGroup = $this.closest( '.form-group' )
		;

		$formGroup.removeClass( "has-warning" );
		$( '.help-block', $formGroup ).remove();

		if ( !$this.is( ":checked" ) ) {
			$formGroup.addClass( "has-warning" );

			$( '.clearfix', $formGroup ).after( '<div class="help-block">' + cfrequest.exactMatchOnlyfalseWarning + '</div>' );
		}
	} ).trigger( 'change' );


} )( presideJQuery );