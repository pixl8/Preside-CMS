( function( $ ){
	var $tables = $( "table" )
	  , updateTableSizes
	  , tableNeedsResizing;

	tableNeedsResizing = function( $tbl ){
		var prevParentWidth    = $tbl.data( "_previousParentWidth" )
		  , currentParentWidth = $tbl.parent().width()
		  , needsResizing      = typeof prevParentWidth === "undefined" || prevParentWidth !== currentParentWidth;

		if ( needsResizing ) {
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