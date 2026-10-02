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
			  url     : url
			, type    : "POST"
			, data    : function( d ) {
				var hungarian = PresideDatatables.toHungarianAjaxData( d, extraParams );
				$.extend( d, hungarian );
				return d;
			  }
			, dataSrc : function( json ) {
				return PresideDatatables.fromHungarianResponse( json );
			  }
		};
	};

	PresideDatatables.listingUrlParam = "lst";

	PresideDatatables._listingUrlIdHash = function( tableId ) {
		var str = String( tableId || "" )
		  , h   = 2166136261
		  , i, hex;

		for( i=0; i<str.length; i++ ) {
			h ^= str.charCodeAt( i );
			h = Math.imul( h, 16777619 );
		}

		hex = ( h >>> 0 ).toString( 16 );
		while ( hex.length < 8 ) {
			hex = "0" + hex;
		}

		return hex;
	};

	PresideDatatables.listingUrlParamFor = function( tableId ) {
		return PresideDatatables.listingUrlParam + PresideDatatables._listingUrlIdHash( tableId );
	};

	PresideDatatables._utf8ToBase64Url = function( str ) {
		var b64 = btoa( encodeURIComponent( str ).replace( /%([0-9A-F]{2})/g, function( match, hex ) {
			return String.fromCharCode( parseInt( hex, 16 ) );
		} ) );

		return b64.replace( /\+/g, "-" ).replace( /\//g, "_" ).replace( /=+$/g, "" );
	};

	PresideDatatables._base64UrlToUtf8 = function( encoded ) {
		var b64 = String( encoded || "" ).replace( /-/g, "+" ).replace( /_/g, "/" );

		while ( b64.length % 4 ) {
			b64 += "=";
		}

		return decodeURIComponent( Array.prototype.map.call( atob( b64 ), function( ch ) {
			return "%" + ( "00" + ch.charCodeAt( 0 ).toString( 16 ) ).slice( -2 );
		} ).join( "" ) );
	};

	PresideDatatables.compactListingUrlState = function( state ) {
		var compact = {};

		state = state || {};
		if ( state.q ) {
			compact.q = state.q;
		}
		if ( state.f && state.f.length ) {
			compact.f = state.f;
		}
		if ( state.a && state.a.length ) {
			compact.a = state.a;
		}
		if ( state.x && state.x.length ) {
			compact.x = state.x;
		}
		if ( state.c && typeof state.c === "object" && Object.keys( state.c ).length ) {
			compact.c = state.c;
		}
		if ( state.o && state.o.length ) {
			compact.o = state.o;
		}

		return compact;
	};

	PresideDatatables.encodeListingUrlState = function( state ) {
		var compact = PresideDatatables.compactListingUrlState( state );

		if ( !Object.keys( compact ).length ) {
			return "";
		}

		try {
			return PresideDatatables._utf8ToBase64Url( JSON.stringify( compact ) );
		} catch ( e ) {
			return "";
		}
	};

	PresideDatatables.decodeListingUrlState = function( encoded ) {
		var raw;

		if ( !encoded ) {
			return null;
		}

		try {
			raw = JSON.parse( PresideDatatables._base64UrlToUtf8( encoded ) );
		} catch ( e ) {
			return null;
		}

		if ( !raw || typeof raw !== "object" ) {
			return null;
		}

		return {
			  q : raw.q || ""
			, f : $.isArray( raw.f ) ? raw.f : []
			, a : $.isArray( raw.a ) ? raw.a : []
			, x : $.isArray( raw.x ) ? raw.x : []
			, c : raw.c && typeof raw.c === "object" && !$.isArray( raw.c ) ? raw.c : {}
			, o : $.isArray( raw.o ) ? raw.o : []
		};
	};

	PresideDatatables.readListingUrlState = function( tableId ) {
		var params, key;

		try {
			params = new URLSearchParams( window.location.search );
			key    = PresideDatatables.listingUrlParamFor( tableId );
			return PresideDatatables.decodeListingUrlState( params.get( key ) );
		} catch ( e ) {
			return null;
		}
	};

	PresideDatatables.writeListingUrlState = function( encoded, mode, tableId ) {
		var url, key;

		try {
			url = new URL( window.location.href );
		} catch ( e ) {
			return;
		}

		key = PresideDatatables.listingUrlParamFor( tableId );
		if ( encoded ) {
			url.searchParams.set( key, encoded );
		} else {
			url.searchParams.delete( key );
		}

		if ( mode === "replace" ) {
			history.replaceState( history.state, document.title, url );
		} else {
			history.pushState( history.state, document.title, url );
		}
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
			  time    : new Date().getTime()
			, start   : legacy.iStart || 0
			, length  : legacy.iLength || 10
			, order   : []
			, search  : { search : ( legacy.oSearch && legacy.oSearch.sSearch ) || "", smart : true, regex : false, caseInsensitive : true }
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
		var mapped         = $.extend( true, {}, options || {} )
		  , fnServerParams = mapped.fnServerParams
		  , origInitComplete = mapped.fnInitComplete
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
		if ( mapped.aoColumnDefs !== undefined ) { mapped.columnDefs = PresideDatatables.mapHungarianColumnDefs( mapped.aoColumnDefs ); delete mapped.aoColumnDefs; }
		if ( mapped.iDeferLoading !== undefined ) { mapped.deferLoading = mapped.iDeferLoading; delete mapped.iDeferLoading; }
		if ( mapped.sPaginationType !== undefined ) { delete mapped.sPaginationType; }
		if ( mapped.sDom !== undefined ) {
			if ( !mapped.layout ) {
				mapped.layout = PresideDatatables.domToLayout( mapped.sDom );
			}
			delete mapped.sDom;
		}
		if ( mapped.sAjaxSource ) {
			mapped.ajax = PresideDatatables.hungarianAjax( mapped.sAjaxSource, fnServerParams ? function( params ){
				var aoData = [];
				fnServerParams( aoData );
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
			mapped.rowCallback = mapped.fnRowCallback;
			delete mapped.fnRowCallback;
		}
		if ( mapped.fnCreatedRow ) {
			mapped.createdRow = mapped.fnCreatedRow;
			delete mapped.fnCreatedRow;
		}
		if ( origInitComplete ) {
			mapped.initComplete = function( settings, json ) {
				var api = this.api ? this.api() : ( DataTable.Api ? new DataTable.Api( settings ) : null )
				  , $container;

				if ( api ) {
					$container = $( api.table().container() );
					settings.aanFeatures = settings.aanFeatures || {};
					settings.aanFeatures.f = $container.find( ".dt-search, .dataTables_filter" ).toArray();
					settings.aanFeatures.l = $container.find( ".dt-length, .dataTables_length" ).toArray();
					settings.aanFeatures.i = $container.find( ".dt-info, .dataTables_info" ).toArray();
					settings.aanFeatures.p = $container.find( ".dt-paging, .dataTables_paginate" ).toArray();
				}

				return origInitComplete.call( this, settings, json );
			};
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
			return PresideDatatables.mapHungarianColumn( col );
		} );
	};

	PresideDatatables.mapHungarianColumnDefs = function( defs ) {
		return ( defs || [] ).map( function( def ) {
			var mapped = PresideDatatables.mapHungarianColumn( def );

			if ( mapped.aTargets !== undefined ) { mapped.targets = mapped.aTargets; delete mapped.aTargets; }

			return mapped;
		} );
	};

	PresideDatatables.mapHungarianColumn = function( col ) {
		var mapped = $.extend( {}, col );

		if ( mapped.mData !== undefined ) { mapped.data = mapped.mData; delete mapped.mData; }
		if ( mapped.sClass !== undefined ) { mapped.className = mapped.sClass; delete mapped.sClass; }
		if ( mapped.bSortable !== undefined ) { mapped.orderable = mapped.bSortable; delete mapped.bSortable; }
		if ( mapped.bSearchable !== undefined ) { mapped.searchable = mapped.bSearchable; delete mapped.bSearchable; }
		if ( mapped.bVisible !== undefined ) { mapped.visible = mapped.bVisible; delete mapped.bVisible; }
		if ( mapped.sWidth !== undefined ) { mapped.width = mapped.sWidth; delete mapped.sWidth; }
		if ( mapped.sTitle !== undefined ) { mapped.title = mapped.sTitle; delete mapped.sTitle; }
		if ( mapped.sName !== undefined ) { mapped.name = mapped.sName; delete mapped.sName; }
		if ( mapped.sDefaultContent !== undefined ) { mapped.defaultContent = mapped.sDefaultContent; delete mapped.sDefaultContent; }
		if ( mapped.mRender !== undefined ) { mapped.render = mapped.mRender; delete mapped.mRender; }

		return mapped;
	};

	PresideDatatables.mapHungarianLanguage = function( oLanguage ) {
		var language = {};

		language.emptyTable     = oLanguage.sEmptyTable;
		language.info           = oLanguage.sInfo;
		language.infoEmpty      = oLanguage.sInfoEmpty;
		language.infoFiltered   = oLanguage.sInfoFiltered;
		language.thousands      = oLanguage.sInfoThousands;
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
				  orderable        : oLanguage.oAria.sSortAscending
				, orderableReverse : oLanguage.oAria.sSortDescending
			};
		}

		return language;
	};

	PresideDatatables.domToLayout = function( sDom ) {
		var src, has, tIndex, beforeT, afterT, layout, bottomEnd;

		if ( !sDom ) {
			return undefined;
		}

		src      = String( sDom );
		has      = function( haystack, ch ){ return haystack.indexOf( ch ) !== -1; };
		tIndex   = src.indexOf( "t" );
		beforeT  = tIndex === -1 ? src : src.substring( 0, tIndex );
		afterT   = tIndex === -1 ? ""  : src.substring( tIndex + 1 );
		layout   = {
			  topStart    : null
			, topEnd      : null
			, bottomStart : null
			, bottomEnd   : null
		};
		bottomEnd = [];

		if ( has( beforeT, "f" ) ) {
			layout.topStart = "search";
		} else if ( has( afterT, "f" ) ) {
			bottomEnd.push( "search" );
		}

		if ( has( beforeT, "l" ) ) {
			layout.topEnd = "pageLength";
		} else if ( has( afterT, "l" ) ) {
			bottomEnd.push( "pageLength" );
		}

		if ( has( src, "i" ) ) {
			layout.bottomStart = "info";
		}
		if ( has( src, "p" ) ) {
			bottomEnd.push( "paging" );
		}
		if ( bottomEnd.length ) {
			layout.bottomEnd = bottomEnd;
		}

		return layout;
	};

	if ( DataTable.Api ) {
		DataTable.Api.register( "fnDraw()", function( resetPaging ) {
			return this.draw( resetPaging === false ? false : true );
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
		DataTable.Api.register( "fnFilter()", function( value, column, regex ) {
			if ( typeof column === "number" ) {
				this.column( column ).search( value || "", !!regex, regex ? false : true );
			} else {
				this.search( value || "", !!regex, regex ? false : true );
			}
			return this.draw();
		} );
		DataTable.Api.register( "fnGetData()", function( row, col ) {
			if ( row === undefined ) {
				return this.rows().data().toArray();
			}
			if ( col === undefined ) {
				return this.row( row ).data();
			}
			return this.cell( row, col ).data();
		} );
		DataTable.Api.register( "fnUpdate()", function( data, row, col, redraw ) {
			if ( col === undefined || col === null ) {
				this.row( row ).data( data );
			} else {
				this.cell( row, col ).data( data );
			}
			if ( redraw !== false ) {
				this.draw( false );
			}
			return this;
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
		var isHungarian;

		if ( !arguments.length || options === undefined ) {
			return $( this ).DataTable();
		}

		isHungarian = options && typeof options === "object" && (
			   options.bServerSide !== undefined
			|| options.sAjaxSource !== undefined
			|| options.aoColumns   !== undefined
			|| options.aoColumnDefs !== undefined
			|| options.sDom        !== undefined
			|| options.oLanguage   !== undefined
			|| options.fnServerParams !== undefined
			|| options.aaSorting   !== undefined
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
