( function( $ ){
	var $tables = $( "table" )
	  , updateTableSizes
	  , tableNeedsResizing;

	tableNeedsResizing = function( $tbl ){
		var prevParentWidth    = $tbl.data( "_previousParentWidth" )
		  , currentParentWidth = $tbl.parent().width()
		  , widthDiff          = typeof prevParentWidth === "undefined" ? 0 : Math.abs( currentParentWidth - prevParentWidth )
		  , needsResizing      = $tbl.DataTable().fnIsOpen() && typeof prevParentWidth === "undefined" || prevParentWidth !== currentParentWidth;

		if ( needsResizing ) {
			if ( typeof prevParentWidth === "undefined" || widthDiff < 100 ) {
				if ( typeof prevParentWidth !== "undefined" ) {
					return false;
				}

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