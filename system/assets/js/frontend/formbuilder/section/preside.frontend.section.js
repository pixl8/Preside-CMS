( function( $ ) {

	$( ".formbuilder-section" ).each( function( i ) {
		var $section  = $( this )
		  , $formGroups = $section.nextUntil( ".formbuilder-section", ".form-group:not(:last-child)" );

		sectionToggle( $( ".formbuilder-section-heading",  $section ), $formGroups );

		$( ".formbuilder-section-heading", $section ).on( "click", function() {
			sectionToggle( $( this ), $formGroups );
		} );

		function sectionToggle( $heading, $formGroups ) {
			var isVisible = $heading.hasClass( "formbuilder-section-heading-active" );

			if ( isVisible ) {
				$heading.removeClass( "formbuilder-section-heading-active" );
			} else {
				$heading.addClass( "formbuilder-section-heading-active" );
			}

			$formGroups.each( function() {
				$( this ).toggle( !isVisible );
			} );
		}
	} );

} )( jQuery );