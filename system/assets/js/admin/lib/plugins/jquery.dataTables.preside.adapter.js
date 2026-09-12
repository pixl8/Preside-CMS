/**
 * Compatibility adapter for DataTables 3.x in Preside.
 *
 * Keeps the 1.9-era Hungarian AJAX protocol and a subset of the old
 * fn* API so existing listing endpoints and extension code keep working.
 */
( function( $ ){

	var DataTable = $.fn.dataTable;

	if ( !DataTable ) {
		return;
	}

	if ( window.moment && DataTable.use ) {
		DataTable.use( window.moment );
	}

	window.PresideDatatables = window.PresideDatatables || {};

	PresideDatatables.toHungarianAjaxData = function( dtRequest, extraParams ) {
		var params  = {}
		  , columns = dtRequest.columns || []
		  , order   = dtRequest.order   || []
		  , search  = dtRequest.search  || {}
		  , i, col, ord;

		params.sEcho          = dtRequest.draw;
		params.iDisplayStart  = dtRequest.start;
		params.iDisplayLength = dtRequest.length;
		params.sSearch        = search.value || "";
		params.bRegex         = search.regex ? "true" : "false";
		params.iColumns       = columns.length;
		params.iSortingCols   = order.length;

		for( i=0; i<columns.length; i++ ) {
			col = columns[ i ];
			params[ "mDataProp_" + i ]   = col.data;
			params[ "sColumns_" + i ]    = col.name || col.data || "";
			params[ "bSortable_" + i ]   = col.orderable ? "true" : "false";
			params[ "bSearchable_" + i ] = col.searchable ? "true" : "false";
			params[ "sSearch_" + i ]     = ( col.search && col.search.value ) ? col.search.value : "";
			params[ "bRegex_" + i ]      = ( col.search && col.search.regex ) ? "true" : "false";
		}

		for( i=0; i<order.length; i++ ) {
			ord = order[ i ];
			params[ "iSortCol_" + i ]  = ord.column;
			params[ "sSortDir_" + i ]  = ord.dir;
		}

		if ( typeof extraParams === "function" ) {
			extraParams( params, dtRequest );
		} else if ( extraParams && typeof extraParams === "object" ) {
			$.extend( params, extraParams );
		}

		return params;
	};

	PresideDatatables.fromHungarianResponse = function( json ) {
		if ( !json ) {
			return [];
		}

		if ( typeof json.sEcho !== "undefined" && typeof json.draw === "undefined" ) {
			json.draw = parseInt( json.sEcho, 10 ) || 1;
		}
		if ( typeof json.iTotalRecords !== "undefined" && typeof json.recordsTotal === "undefined" ) {
			json.recordsTotal = json.iTotalRecords;
		}
		if ( typeof json.iTotalDisplayRecords !== "undefined" && typeof json.recordsFiltered === "undefined" ) {
			json.recordsFiltered = json.iTotalDisplayRecords;
		}
		if ( typeof json.aaData !== "undefined" && typeof json.data === "undefined" ) {
			json.data = json.aaData;
		}

		return json.data || json.aaData || [];
	};

	PresideDatatables.hungarianAjax = function( url, extraParams ) {
		return {
			  url    : url
			, type   : "POST"
			, data   : function( d ) {
				var hungarian = PresideDatatables.toHungarianAjaxData( d, extraParams );
				$.extend( d, hungarian );
				return d;
			  }
			, dataSrc : function( json ) {
				return PresideDatatables.fromHungarianResponse( json );
			  }
		};
	};

	PresideDatatables.migrateLegacyCookieState = function( tableId ) {
		var cookieName, cookies, i, parts, name, value, decoded;

		if ( !tableId ) {
			return;
		}

		cookieName = "SpryMedia_DataTables_" + tableId;
		cookies    = document.cookie.split( ";" );

		for( i=0; i<cookies.length; i++ ) {
			parts = cookies[ i ].split( "=" );
			name  = $.trim( parts.shift() );
			if ( name.indexOf( cookieName ) === 0 ) {
				try {
					value   = decodeURIComponent( parts.join( "=" ) );
					decoded = JSON.parse( value );
					return PresideDatatables.hungarianStateToModern( decoded );
				} catch ( e ) {}
			}
		}
	};

	PresideDatatables.hungarianStateToModern = function( legacy ) {
		var state = {
			  time   : new Date().getTime()
			, start  : legacy.iStart || 0
			, length : legacy.iLength || 10
			, order  : []
			, search : { search : ( legacy.oSearch && legacy.oSearch.sSearch ) || "", smart : true, regex : false, caseInsensitive : true }
			, columns : []
		};
		var aaSorting = legacy.aaSorting || []
		  , i;

		for( i=0; i<aaSorting.length; i++ ) {
			state.order.push( [ aaSorting[ i ][ 0 ], aaSorting[ i ][ 1 ] ] );
		}

		if ( legacy.oFilter ) {
			state.oFilter = legacy.oFilter;
		}

		return state;
	};

	PresideDatatables.mapHungarianOptions = function( options ) {
		var mapped = $.extend( true, {}, options || {} )
		  , key;

		if ( mapped.bServerSide !== undefined ) { mapped.serverSide = !!mapped.bServerSide; delete mapped.bServerSide; }
		if ( mapped.bProcessing !== undefined ) { mapped.processing = !!mapped.bProcessing; delete mapped.bProcessing; }
		if ( mapped.bStateSave  !== undefined ) { mapped.stateSave  = !!mapped.bStateSave;  delete mapped.bStateSave;  }
		if ( mapped.bFilter     !== undefined ) { mapped.searching  = !!mapped.bFilter;     delete mapped.bFilter;     }
		if ( mapped.bAutoWidth  !== undefined ) { mapped.autoWidth  = !!mapped.bAutoWidth;  delete mapped.bAutoWidth;  }
		if ( mapped.bSort       !== undefined ) { mapped.ordering   = !!mapped.bSort;       delete mapped.bSort;       }
		if ( mapped.bPaginate   !== undefined ) { mapped.paging     = !!mapped.bPaginate;   delete mapped.bPaginate;   }
		if ( mapped.bLengthChange !== undefined ) { mapped.lengthChange = !!mapped.bLengthChange; delete mapped.bLengthChange; }
		if ( mapped.iDisplayLength !== undefined ) { mapped.pageLength = mapped.iDisplayLength; delete mapped.iDisplayLength; }
		if ( mapped.aLengthMenu !== undefined ) { mapped.lengthMenu = mapped.aLengthMenu; delete mapped.aLengthMenu; }
		if ( mapped.aaSorting !== undefined ) { mapped.order = mapped.aaSorting; delete mapped.aaSorting; }
		if ( mapped.aoColumns !== undefined ) { mapped.columns = PresideDatatables.mapHungarianColumns( mapped.aoColumns ); delete mapped.aoColumns; }
		if ( mapped.aoColumnDefs !== undefined ) { mapped.columnDefs = mapped.aoColumnDefs; delete mapped.aoColumnDefs; }
		if ( mapped.iDeferLoading !== undefined ) { mapped.deferLoading = mapped.iDeferLoading; delete mapped.iDeferLoading; }
		if ( mapped.sPaginationType !== undefined ) { delete mapped.sPaginationType; }
		if ( mapped.sDom !== undefined ) {
			if ( !mapped.layout ) {
				mapped.layout = PresideDatatables.domToLayout( mapped.sDom );
			}
			delete mapped.sDom;
		}
		if ( mapped.sAjaxSource ) {
			mapped.ajax = PresideDatatables.hungarianAjax( mapped.sAjaxSource, mapped.fnServerParams ? function( params ){
				var aoData = [];
				mapped.fnServerParams( aoData );
				aoData.forEach( function( item ){
					if ( item && item.name ) {
						params[ item.name ] = item.value;
					}
				} );
			} : null );
			delete mapped.sAjaxSource;
			delete mapped.sServerMethod;
			delete mapped.fnServerParams;
		}
		if ( mapped.fnRowCallback ) {
			mapped.createdRow = mapped.fnRowCallback;
			delete mapped.fnRowCallback;
		}
		if ( mapped.fnInitComplete ) {
			mapped.initComplete = mapped.fnInitComplete;
			delete mapped.fnInitComplete;
		}
		if ( mapped.fnDrawCallback ) {
			mapped.drawCallback = mapped.fnDrawCallback;
			delete mapped.fnDrawCallback;
		}
		if ( mapped.fnPreDrawCallback ) {
			mapped.preDrawCallback = mapped.fnPreDrawCallback;
			delete mapped.fnPreDrawCallback;
		}
		if ( mapped.fnFooterCallback ) {
			mapped.footerCallback = mapped.fnFooterCallback;
			delete mapped.fnFooterCallback;
		}
		if ( mapped.fnInfoCallback ) {
			mapped.infoCallback = mapped.fnInfoCallback;
			delete mapped.fnInfoCallback;
		}
		if ( mapped.oLanguage ) {
			mapped.language = PresideDatatables.mapHungarianLanguage( mapped.oLanguage );
			delete mapped.oLanguage;
		}

		for( key in mapped ) {
			if ( mapped.hasOwnProperty( key ) && key.indexOf( "fn" ) === 0 ) {
				delete mapped[ key ];
			}
		}

		return mapped;
	};

	PresideDatatables.mapHungarianColumns = function( columns ) {
		return ( columns || [] ).map( function( col ) {
			var mapped = $.extend( {}, col );

			if ( mapped.mData !== undefined ) { mapped.data = mapped.mData; delete mapped.mData; }
			if ( mapped.sClass !== undefined ) { mapped.className = mapped.sClass; delete mapped.sClass; }
			if ( mapped.bSortable !== undefined ) { mapped.orderable = mapped.bSortable; delete mapped.bSortable; }
			if ( mapped.sWidth !== undefined ) { mapped.width = mapped.sWidth; delete mapped.sWidth; }
			if ( mapped.sTitle !== undefined ) { mapped.title = mapped.sTitle; delete mapped.sTitle; }

			return mapped;
		} );
	};

	PresideDatatables.mapHungarianLanguage = function( oLanguage ) {
		var language = {};

		language.emptyTable     = oLanguage.sEmptyTable;
		language.info           = oLanguage.sInfo;
		language.infoEmpty      = oLanguage.sInfoEmpty;
		language.infoFiltered   = oLanguage.sInfoFiltered;
		language.infoThousands  = oLanguage.sInfoThousands;
		language.lengthMenu     = oLanguage.sLengthMenu;
		language.loadingRecords = oLanguage.sLoadingRecords;
		language.processing     = oLanguage.sProcessing;
		language.zeroRecords    = oLanguage.sZeroRecords;
		language.search         = oLanguage.sSearch;
		language.infoPostFix    = oLanguage.sInfoPostFix;

		if ( oLanguage.oPaginate ) {
			language.paginate = {
				  first    : oLanguage.oPaginate.sFirst
				, last     : oLanguage.oPaginate.sLast
				, next     : oLanguage.oPaginate.sNext
				, previous : oLanguage.oPaginate.sPrevious
			};
		}
		if ( oLanguage.oAria ) {
			language.aria = {
				  orderable     : oLanguage.oAria.sSortAscending
				, orderableReverse : oLanguage.oAria.sSortDescending
			};
		}

		return language;
	};

	PresideDatatables.domToLayout = function( sDom ) {
		if ( !sDom ) {
			return undefined;
		}

		return {
			  topStart    : null
			, topEnd      : null
			, bottomStart : "info"
			, bottomEnd   : [ "pageLength", "paging" ]
			, bottom      : null
		};
	};

	if ( DataTable.Api ) {
		DataTable.Api.register( "fnDraw()", function() {
			return this.draw();
		} );
		DataTable.Api.register( "fnPageChange()", function( action ) {
			return this.page( action ).draw( "page" );
		} );
		DataTable.Api.register( "fnAdjustColumnSizing()", function() {
			return this.columns.adjust();
		} );
		DataTable.Api.register( "fnIsOpen()", function() {
			return false;
		} );
		DataTable.Api.register( "fnFilter()", function( value ) {
			return this.search( value || "" ).draw();
		} );
		DataTable.Api.register( "fnPagingInfo()", function() {
			var info = this.page.info();
			return {
				  iStart         : info.start
				, iEnd           : info.end
				, iLength        : info.length
				, iTotal         : info.recordsTotal
				, iFilteredTotal : info.recordsDisplay
				, iPage          : info.page
				, iTotalPages    : info.pages
			};
		} );
	}

	var originalDt = $.fn.dataTable;
	$.fn.dataTable = function( options ) {
		var isHungarian = options && typeof options === "object" && (
			   options.bServerSide !== undefined
			|| options.sAjaxSource !== undefined
			|| options.aoColumns   !== undefined
			|| options.sDom        !== undefined
			|| options.oLanguage   !== undefined
		);

		if ( isHungarian ) {
			return $( this ).DataTable( PresideDatatables.mapHungarianOptions( options ) );
		}

		return originalDt.apply( this, arguments );
	};
	$.extend( $.fn.dataTable, originalDt );
	$.fn.dataTableExt = originalDt.ext || $.fn.dataTable.ext || {};
	$.fn.dataTableExt.oApi = $.fn.dataTableExt.oApi || {};

} )( presideJQuery );
