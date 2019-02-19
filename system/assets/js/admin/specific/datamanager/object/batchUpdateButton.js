/**
 * Behaviour for selecting a field to batch edit
 *
 */
( function( $ ){

	$( ".batch-update-menu" ).each( function(){
		$batchUpdateMenu = $( this );

		var $form             = $batchUpdateMenu.closest( "form" )
		  , $multiActionField = $form.find( "[name=multiAction]" )
		  , target            = $form.find( ".object-listing-table" ).get( 0 );

		$batchUpdateMenu.on( "click", ".field", function( e ){
			var field = $( this ).data( "field" );

			e.preventDefault();

			$multiActionField.val( "batchUpdate" );
			$form.append( '<input type="hidden" name="field" value="' + field + '">' );
			$form.submit();
		} );


		var observer = new MutationObserver(function(mutations) {
			mutations.forEach(function(mutation) {
				if ( mutation.type === 'childList' ) {
					var $listingTable  = $form.find( '.object-listing-table' );
					var $selectAllCBox = $listingTable.find( "th input:checkbox" );
					if( $selectAllCBox. prop("checked") == true ){
						$selectAllCBox.click();
					}
				}
			});
		});

		var config = { attributes: true, childList: true, characterData: true }

		observer.observe(target, config);
	} );

} )( presideJQuery );