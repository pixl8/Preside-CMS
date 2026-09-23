/**
 * @presideService true
 * @singleton      true
 * @feature        admin
 */
component {

	public any function init() {
		return this;
	}

	public struct function queryToResult( required query qry, array columns=ListToArray( arguments.qry.columnList ), numeric totalRecords = arguments.qry.recordCount ) {
		var event  = $getRequestContext();
		var row    = "";
		var col    = "";
		var record = "";
		var echo   = _getRequestValue( "sEcho", _getRequestValue( "draw", "1" ) );
		var result = {
			  aaData               = []
			, sEcho                = echo
			, iTotalRecords        = arguments.totalRecords
			, iTotalDisplayRecords = arguments.totalRecords
			, data                 = []
			, draw                 = echo
			, recordsTotal         = arguments.totalRecords
			, recordsFiltered      = arguments.totalRecords
		};

		for( row in arguments.qry ){
			record = {};
			for( col in arguments.columns ){
				record[ ListLast( col, "." ) ] = ReReplace( row[ ListLast( col, "." ) ], "\s+", " ", "all" );
			}

			ArrayAppend( result.aaData, record );
			ArrayAppend( result.data, record );
		}

		return result;
	}

	public numeric function getStartRow() {
		return Val( _getRequestValue( "iDisplayStart", _getRequestValue( "start", "0" ) ) ) + 1;
	}

	public numeric function getMaxRows() {
		var maxRows = Val( _getRequestValue( "iDisplayLength", _getRequestValue( "length", "10" ) ) );
		if ( maxRows lte 0 ) {
			return 0;
		}

		return maxRows;
	}

	public string function getSortOrder() {
		var event        = $getRequestContext();
		var nSortingCols = Val( _getRequestValue( "iSortingCols", "0" ) );
		var i            = 0;
		var sortOrder    = "";
		var sortColIx    = "";
		var sortCol      = "";
		var sortDir      = "";
		var isSortable   = "";

		if ( !nSortingCols ) {
			return _getCamelCaseSortOrder();
		}

		for( i=0; i lt nSortingCols; i++ ){
			sortColIx  = Val( event.getValue( name="iSortCol_#i#", defaultValue=0 ) );
			isSortable = event.getValue( name="bSortable_#sortColIx#", defaultValue=false );

			if ( isSortable eq "true" ) {
				sortCol = event.getValue( name="mDataProp_#sortColIx#", defaultValue="" );
				sortDir = event.getValue( name="sSortDir_#i#", defaultValue="asc" );
				if ( Len( Trim( sortCol ) ) ) {
					sortOrder = ListAppend( sortOrder, sortCol & " " & ( sortDir eq "desc" ? "desc" : "asc" ) );
				}
			}
		}

		return sortOrder;
	}

	public string function getSearchQuery() {
		return _getRequestValue( "sSearch", _getRequestValue( "search[value]", "" ) );
	}

	private string function _getCamelCaseSortOrder() {
		var event     = $getRequestContext();
		var sortOrder = "";
		var i         = 0;
		var sortColIx = "";
		var sortCol   = "";
		var sortDir   = "";

		for( i=0; i<10; i++ ) {
			sortColIx = event.getValue( name="order[#i#][column]", defaultValue="" );
			if ( !Len( Trim( sortColIx ) ) && sortColIx !== 0 && sortColIx !== "0" ) {
				break;
			}
			sortCol = event.getValue( name="columns[#Val( sortColIx )#][data]", defaultValue="" );
			sortDir = event.getValue( name="order[#i#][dir]", defaultValue="asc" );
			if ( Len( Trim( sortCol ) ) ) {
				sortOrder = ListAppend( sortOrder, sortCol & " " & ( sortDir eq "desc" ? "desc" : "asc" ) );
			} else {
				break;
			}
		}

		return sortOrder;
	}

	private string function _getRequestValue( required string name, string defaultValue="" ) {
		var value = $getRequestContext().getValue( name=arguments.name, defaultValue="" );
		if ( Len( Trim( value ) ) || value === 0 || value === "0" ) {
			return value;
		}
		return arguments.defaultValue;
	}
}
