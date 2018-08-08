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

	// select the target node
	var target = document.querySelector('table');

	// create an observer instance
	var observer = new MutationObserver(function(mutations) {
		mutations.forEach(function(mutation) {
			if ( mutation.type === 'childList' ) {
				console.log( "mutate" );
				var $listingTable  = $( '.object-listing-table' );
				var $selectAllCBox = $listingTable.find( "th input:checkbox" );
				$selectAllCBox.click();
			}
		});
	});

	// configuration of the observer:
	var config = { attributes: true, childList: true, characterData: true }

	// pass in the target node, as well as the observer options
	observer.observe(target, config);

} )( presideJQuery );