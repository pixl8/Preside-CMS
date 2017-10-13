component extends="coldbox.system.Plugin" output="false" singleton="true" {

	public any function init( controller ) output=false {
		super.init( arguments.controller );

		setpluginName("JQuery Datatables Helper");
		setpluginVersion("1.0");
		setpluginDescription( "Provides methods for easy client-server interactivity with jQuery datatables" );
		setPluginAuthor("Pixl8 Interactive");
		setPluginAuthorURL("www.pixl8.co.uk");

	}

	public struct function queryToResult( required query qry, array columns=ListToArray( arguments.qry.columnList ), numeric totalRecords = arguments.qry.recordCount ) output=false {
		var event  = getRequestContext();
		var row    = "";
		var col    = "";
		var record = "";
		var result = {
			  aaData               = []
			, sEcho                = event.getValue( name="sEcho", defaultValue="1" )
			, iTotalRecords        = arguments.totalRecords
			, iTotalDisplayRecords = arguments.totalRecords
		};

		for( row in arguments.qry ){
			record = {};
			for( col in arguments.columns ){
				record[ col ] = row[ col ];
			}
			ArrayAppend( result.aaData, record );
		}

		return result;
	}

	public numeric function getStartRow() output=false {
		return Val( getRequestContext().getValue( name="iDisplayStart", defaultValue="0" ) ) + 1;
	}

	public numeric function getMaxRows() output=false {
		var maxRows = Val( getRequestContext().getValue( name="iDisplayLength", defaultValue="10" ) );
		if ( maxRows lte 0 ) {
			return 0;
		}

		return maxRows;
	}

	public string function getSortOrder() output=false {
		var event        = getRequestContext();
		var nSortingCols = Val( event.getValue( name="iSortingCols", default="0" ) );
		var i            = 0;
		var sortOrder    = "";
		var sortColIx    = "";
		var sortCol      = "";
		var sortDir      = "";
		var isSortable   = "";

		for( i=0; i lt nSortingCols; i++ ){
			sortColIx = Val( event.getValue( name="iSortCol_#i#", defaultValue=0 ) );
			isSortable = event.getValue( name="bSortable_#sortColIx#", defaultValue=false );

			if ( isSortable eq "true" ) {
				sortCol    = event.getValue( name="mDataProp_#sortColIx#", defaultValue="" );
				sortDir    = event.getValue( name="sSortDir_#i#", defaultValue="asc" );
				if ( Len( Trim( sortCol ) ) ) {
					sortOrder = ListAppend( sortOrder, sortCol & " " & ( sortDir eq "desc" ? "desc" : "asc" ) );
				}

			}
		}

		return sortOrder;
	}

	public string function getSearchQuery() output=false {
		return getRequestContext().getValue( name="sSearch", defaultValue="" );
	}
}