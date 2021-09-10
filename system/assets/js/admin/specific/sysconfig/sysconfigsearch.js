/**
 * This script controls the behaviour of the object listing table
 */
( function( $ ){

	$.fn.sysconfigTable = function(){
		return this.each( function(){
			var $sysconfigTable  = $( this )
			  , $categories = $(this).find(".config-category")
			  , tableSettings = $(this).data()
			  , $searchInput     = $sysconfigTable.find( "input" ).first()
			  , noRecordMessage  = tableSettings.noRecordMessage   || i18n.translateResource( "cms:datatables.emptyTable" );

			$searchInput.bind( 'keyup', function() {
				var search = $searchInput.val().toLowerCase();
				$categories.each( function() {
					var $this = $(this);
					if ( $this.text().toLowerCase().indexOf( search ) === -1 ) {
						$this.fadeOut();
					} else {
						$this.fadeIn();
					}
				});
			});
		} );
	};

	$( '.sysconfig-table' ).sysconfigTable();

} )( presideJQuery );