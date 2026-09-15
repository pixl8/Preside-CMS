( function( $ ){

	$.fn.formbuilderPreventMultipleSubmit = function(){
		return this.each( function(){
			var $form     = $( this )
			  , submitBtn = "button";

			$form.on( "submit", function( event ) {
				if ( $form.data( "formbuilderSubmitting" ) ) {
					event.preventDefault();
					return false;
				}

				if ( typeof $( this ).valid !== "function" || $( this ).valid() ) {
					$form.data( "formbuilderSubmitting", true );

					setTimeout( function() { // Allows the form submission to start before disabling the button.
						$( submitBtn, $form ).prop( "disabled", true );
					}, 0 );
				}
			} );

			$form.on( "reset", function( event ) {
				$( submitBtn, $form ).prop( "disabled", false );
			} );
		} );
	};

	$( ".formbuilder-form > form" ).formbuilderPreventMultipleSubmit();

} )( jQuery );
