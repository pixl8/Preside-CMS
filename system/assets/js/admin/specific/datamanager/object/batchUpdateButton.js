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

	var target = $( ".object-listing-table" ).get( 0 );
	var observer = new MutationObserver(function(mutations) {
		mutations.forEach(function(mutation) {
			if ( mutation.type === 'childList' ) {
				var $listingTable  = $( '.object-listing-table' );
				var $selectAllCBox = $listingTable.find( "th input:checkbox" );
				if( $selectAllCBox. prop("checked") == true ){
					$selectAllCBox.click();
				}
			}
		});
	});

	var config = { attributes: true, childList: true, characterData: true }

	observer.observe(target, config);

} )( presideJQuery );