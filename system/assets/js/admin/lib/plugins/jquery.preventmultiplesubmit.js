( function( $ ){

	$.fn.preventMultipleSubmit = function(){
		return this.each( function(){
			var $form = $( this )
			  , disableSubmitButtons = function(){
					$( "button[type=submit], input[type=submit]", $form ).prop( "disabled", true );
				};

			$form.on( "submit", function(){
				if ( $form.data( "validator" ) && !$form.valid() ) {
					return;
				}
				setTimeout( disableSubmitButtons, 0 ); // let the submission start before disabling
			} );

			$form.on( "reset", function(){
				$( "button[type=submit], input[type=submit]", $form ).prop( "disabled", false );
			} );
		} );
	};

	$( "form[data-prevent-multiple-submit]" ).preventMultipleSubmit();

} )( presideJQuery );
