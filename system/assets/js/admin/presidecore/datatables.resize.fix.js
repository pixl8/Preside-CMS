( function( $ ){
	var $tables = $( "table" )
	  , updateTableSizes
	  , tableNeedsResizing;

	tableNeedsResizing = function( $tbl ){
		var prevParentWidth    = $tbl.data( "_previousParentWidth" )
		  , currentParentWidth = $tbl.parent().width()
		  , needsResizing      = $tbl.DataTable().fnIsOpen() && typeof prevParentWidth === "undefined" || prevParentWidth !== currentParentWidth;

		if ( needsResizing ) {
			if ( typeof prevParentWidth === "undefined" ) {
				needsResizing = false;
			}
			$tbl.data( "_previousParentWidth", currentParentWidth );
		}

		return needsResizing;
	};


	updateTableSizes = function() {
		$tables.filter( ".dataTable" ).each( function(){
			var $tbl = $( this );

			if ( tableNeedsResizing( $tbl ) ) {
				$tbl.css( { width: $tbl.parent().width() } );
				$tbl.DataTable().fnAdjustColumnSizing();
			}

		} );
	};

	setInterval( function(){ updateTableSizes(); }, 250 )

} )( presideJQuery );