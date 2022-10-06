( function( $ ) {

	$( ".formbuilder-accordion" ).each( function( i ) {
		var $accordion  = $( this )
		  , $formGroups = $accordion.nextUntil( ".formbuilder-accordion", ".form-group:not(:last-child)" );

		accordionToggle( $( ".formbuilder-accordion-heading",  $accordion ), $formGroups );

		$( ".formbuilder-accordion-heading", $accordion ).on( "click", function() {
			accordionToggle( $( this ), $formGroups );
		} );

		function accordionToggle( $heading, $formGroups ) {
			var isVisible = $heading.hasClass( "formbuilder-accordion-heading-active" );

			if ( isVisible ) {
				$heading.removeClass( "formbuilder-accordion-heading-active" );
			} else {
				$heading.addClass( "formbuilder-accordion-heading-active" );
			}

			$formGroups.each( function() {
				$( this ).toggle( !isVisible );
			} );
		}
	} );

} )( jQuery );