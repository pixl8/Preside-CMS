( function( $ ) {

	$( '[name="redirect_type"]' ).on( 'change', function( e ) {
		var $this      = $( this )
		  , $formGroup = $this.closest( '.form-group' )
		  , $form      = $this.closest( 'form' )
		  , $validator = $form.validate()
		;

		$formGroup.removeClass( "has-warning" );

		if ( $this.val() != "302" ) {
			$formGroup.addClass( "has-warning" );

			$validator.showErrors( {
				[ "redirect_type" ]: cfrequest.redirectType301Warning
			} );
		}
	} ).trigger( 'change' );

	$( '[name="exact_match_only"]' ).on( 'change', function( e ) {
		var $this      = $( this )
		  , $formGroup = $this.closest( '.form-group' )
		  , $form      = $this.closest( 'form' )
		  , $validator = $form.validate()
		;

		$formGroup.removeClass( "has-warning" );

		if ( !$this.is( ":checked" ) ) {
			$formGroup.addClass( "has-warning" );

			$validator.showErrors( {
				[ "redirect_type" ]: cfrequest.exactMatchOnlyfalseWarning
			} );
		}
	} ).trigger( 'change' );


} )( presideJQuery );