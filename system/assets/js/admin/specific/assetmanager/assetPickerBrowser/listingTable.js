( function( $ ){

	var $listingTable = $( '#asset-listing-table' )
	  , multiSelect   = $listingTable.data( 'multiple' );

	$listingTable.on( 'click', 'tr.asset', function(e){
		var $tr = $(this);

		if ( !multiSelect ) {
			$tr.siblings().removeClass( "selected" );
		}
		$tr.toggleClass( "selected" );
	} );

	window.assetBrowser = {
		getSelected : function(){
			var selected = [];
			$listingTable.find( "tr.selected" ).each( function(){
				var $tr = $(this)
				  , id  = $tr.data( 'id' );

				if ( typeof id !== "undefined" ) {
					selected.push( id );
				}
			} );

			return selected;
		}
	};

} )( presideJQuery );