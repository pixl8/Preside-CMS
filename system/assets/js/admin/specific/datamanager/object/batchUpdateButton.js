/**
 * Behaviour for selecting a field to batch edit
 *
 */
( function( $ ){

	var $batchUpdateMenu = $( ".batch-update-menu" );

	if ( $batchUpdateMenu.length ) {
		var $form             = $batchUpdateMenu.closest( "form" )
		  , $multiActionField = $form.find( "[name=multiAction]" );

		$batchUpdateMenu.on( "click", ".field", function( e ){
			var field = $( this ).data( "field" );

			e.preventDefault();

			$multiActionField.val( "batchUpdate" );
			$form.append( '<input type="hidden" name="field" value="' + field + '">' );
			$form.submit();
		} );
	}

} )( presideJQuery );