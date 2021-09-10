/**
 * This script controls the behaviour of the object listing table
 */
( function( $ ){

	$.fn.sysconfigTable = function(){
		return this.each( function(){
			var $sysconfigTable  = $( this )
			  , $categories = $(this).find(".config-category")
			  , $searchInput     = $sysconfigTable.find( "input" ).first();

			$searchInput.focus();
			$searchInput.bind( 'keyup', function() {
				var search = $searchInput.val().toLowerCase();
				$categories.each( function() {
					var $this = $(this);
					if ( $this.text().toLowerCase().indexOf( search ) === -1 ) {
						$this.hide();
					} else {
						$this.show();
					}
				});
			});
		} );
	};

	$( '.sysconfig-table' ).sysconfigTable();

} )( presideJQuery );