( function( $ ){

	$.fn.formbuilderPreventMultipleSubmit = function(){
		return this.each( function(){
			var $form     = $( this )
			  , submitBtn = "button";

			$form.on( "submit", function( event ) {
				if ( $( this ).valid() ) {
					$( submitBtn, $form ).prop( "disabled", true );
				}
			} );

			$form.on( "reset", function( event ) {
				$( submitBtn, $form ).prop( "disabled", false );
			} );
		} );
	};

	$( ".formbuilder-form > form" ).formbuilderPreventMultipleSubmit();

} )( jQuery );
