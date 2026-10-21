( function( $ ){
	$( ".static-data-table" ).each( function(){
		var $listingTable     = $( this )
		  , objectTitle       = $listingTable.data( "objectTitle" ) || i18n.translateResource( "cms:datamanager.record" )
		  , disableSearch     = $listingTable.data( "disableSearch" )
		  , disableSort       = $listingTable.data( "disableSort" )
		  , defaultPageLength = $listingTable.data( "defaultPageLength" )
		  , paginationOptions = $listingTable.data( "paginationOptions" )
		  , layout
		  , tableOptions;

		if ( typeof defaultPageLength == "undefined" ) {
		 	defaultPageLength = "10";
		}
		if ( typeof paginationOptions == "undefined" ) {
			paginationOptions = "5,10,25,50,100";
		}

		layout = {
			  topStart    : null
			, topEnd      : null
			, bottomStart : "info"
			, bottomEnd   : [ "pageLength", "paging" ]
		};

		if ( !disableSearch ) {
			layout.top = "search";
		}

		tableOptions = {
			  layout     : layout
			, ordering   : disableSort ? false : { indicators : false, handler : false }
			, searching  : !disableSearch
			, pageLength : parseInt( defaultPageLength, 10 )
			, lengthMenu : paginationOptions.toString().split( "," ).map( function( n ){ return parseInt( n, 10 ); } )
			, autoWidth  : false
			, initComplete : function(){
				var api, $input, $icon, placeholder;

				if ( disableSearch ) { return; }

				api    = this.api ? this.api() : undefined;
				$input = api
					? $( api.table().container() ).find( ".dt-search input, input[type=search]" ).first()
					: $listingTable.closest( ".dt-container, .dataTables_wrapper" ).find( ".dt-search input, input[type=search]" ).first();

				if ( !$input.length ) { return; }

				placeholder = i18n.translateResource( "cms:datamanager.search.placeholder", { data : [ objectTitle ], defaultValue : "" } );

				$input.removeClass( "input-sm" );
				$input.addClass( "data-table-search" );
				$input.attr( "data-global-key", "s" );
				$input.attr( "autocomplete", "off" );
				if ( placeholder ) {
					$input.attr( "placeholder", placeholder );
				}
				$icon = $( '<i class="fa fa-search data-table-search-icon"></i>' );
				$input.wrap( '<span class="input-icon"></span>' );
				$input.before( $icon );
			}
			, language : {
				  emptyTable     : i18n.translateResource( "cms:datatables.emptyTable", { data : [objectTitle], defaultValue : "" } )
				, info           : i18n.translateResource( "cms:datatables.info", { data : [objectTitle], defaultValue : "" } )
				, infoEmpty      : i18n.translateResource( "cms:datatables.infoEmpty", { data : [objectTitle], defaultValue : "" } )
				, infoFiltered   : i18n.translateResource( "cms:datatables.infoFiltered", { data : [objectTitle], defaultValue : "" } )
				, thousands      : i18n.translateResource( "cms:datatables.infoThousands", { data : [objectTitle], defaultValue : "" } )
				, lengthMenu     : i18n.translateResource( "cms:datatables.lengthMenu", { data : [objectTitle], defaultValue : "" } )
				, loadingRecords : i18n.translateResource( "cms:datatables.loadingRecords", { data : [objectTitle], defaultValue : "" } )
				, processing     : i18n.translateResource( "cms:datatables.processing", { data : [objectTitle], defaultValue : "" } )
				, zeroRecords    : i18n.translateResource( "cms:datatables.zeroRecords", { data : [objectTitle], defaultValue : "" } )
				, search         : ""
				, paginate : {
					  first    : '<i class="fa fa-angle-double-left"></i>'
					, previous : '<i class="fa fa-chevron-left"></i>'
					, next     : '<i class="fa fa-chevron-right"></i>'
					, last     : '<i class="fa fa-angle-double-right"></i>'
				  }
				, aria : {
					paginate : {
						  first    : i18n.translateResource( "cms:datatables.first", { data : [objectTitle], defaultValue : "First" } )
						, previous : i18n.translateResource( "cms:datatables.previous", { data : [objectTitle], defaultValue : "Previous" } )
						, next     : i18n.translateResource( "cms:datatables.next", { data : [objectTitle], defaultValue : "Next" } )
						, last     : i18n.translateResource( "cms:datatables.last", { data : [objectTitle], defaultValue : "Last" } )
					}
				  }
			}
		};

		if ( !disableSort && window.DataTable && DataTable.ColumnControl ) {
			tableOptions.columnControl = [ { target : 0, content : [ "order" ] } ];
		}

		$listingTable.DataTable( tableOptions );
	} );
} )( presideJQuery );
