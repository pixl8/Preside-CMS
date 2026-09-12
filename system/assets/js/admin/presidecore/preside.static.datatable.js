( function( $ ){
	$( ".static-data-table" ).each( function(){
		var $listingTable     = $( this )
		  , objectTitle       = $listingTable.data( "objectTitle" ) || i18n.translateResource( "cms:datamanager.record" )
		  , disableSearch     = $listingTable.data( "disableSearch" )
		  , disableSort       = $listingTable.data( "disableSort" )
		  , defaultPageLength = $listingTable.data( "defaultPageLength" )
		  , paginationOptions = $listingTable.data( "paginationOptions" )
		  , layout;

		if ( typeof defaultPageLength == "undefined" ) {
		 	defaultPageLength = "10";
		}
		if ( typeof paginationOptions == "undefined" ) {
			paginationOptions = "5,10,25,50,100";
		}

		layout = disableSearch ?
			{ topStart : null, topEnd : null, bottomStart : "info", bottomEnd : [ "pageLength", "paging" ] } :
			{ topStart : "search", topEnd : null, bottomStart : "info", bottomEnd : [ "pageLength", "paging" ] };

		$listingTable.DataTable({
			  layout     : layout
			, ordering   : !disableSort
			, searching  : !disableSearch
			, pageLength : parseInt( defaultPageLength, 10 )
			, lengthMenu : paginationOptions.split( "," )
			, initComplete : function(){
				if ( disableSearch ) { return; }

				var api    = this.api ? this.api() : undefined
				  , $input = api
				  	? $( api.table().container() ).find( "input[type=search]" ).first()
				  	: $listingTable.closest( ".dt-container, .dataTables_wrapper" ).find( "input[type=search]" ).first();

				$input.addClass( "data-table-search" );
				$input.attr( "data-global-key", "s" );
				$input.attr( "autocomplete", "off" );
				$input.wrap( '<span class="input-icon"></span>' );
				$input.after( '<i class="fa fa-search data-table-search-icon"></i>' );
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
					  first    : i18n.translateResource( "cms:datatables.first", { data : [objectTitle], defaultValue : "" } )
					, last     : i18n.translateResource( "cms:datatables.last", { data : [objectTitle], defaultValue : "" } )
					, next     : i18n.translateResource( "cms:datatables.next", { data : [objectTitle], defaultValue : "" } )
					, previous : i18n.translateResource( "cms:datatables.previous", { data : [objectTitle], defaultValue : "" } )
				  }
			}
		});
	} );
} )( presideJQuery );
