( function( $ ){

	var $listingTable    = $( '#asset-listing-table' )
	  , $tableHeaders    = $listingTable.find( 'thead > tr > th')
	  , colConfig        = []
	  , foldersAndAssets = i18n.translateResource( "cms:assetmanager.datatables.foldersAndAssets" )
	  , i;

	colConfig.push( {
		sClass    : "center",
		bSortable : false,
		sWidth    : "40px"
	} );
	colConfig.push( { bSortable : false } );
	colConfig.push( {
		sClass    : "center",
		bSortable : false,
		sWidth    : "8em"
	} );

	$listingTable.dataTable( {
		aoColumns     : colConfig,
		bServerSide   : false,
		bProcessing   : false,
		bStateSave    : false,
		aLengthMenu   : [ 5, 10, 25, 50, 100 ],
		aaSorting     : [],
		sDom          : "<'row'<'col-sm-6'l><'col-sm-6'f>r>t<'row'<'col-sm-6'i><'col-sm-6'p>>",
		fnRowCallback : function( row ){
			$row = $( row );
			$row.attr( 'data-context-container', "1" ); // make work with context aware Preside hotkeys system
			$row.addClass( "clickable" ); // make work with clickable tr Preside system
		},
		fnInitComplete : function( settings ){
			var $searchContainer = $( settings.aanFeatures.f[0] )
			  , $input           = $searchContainer.find( "input" ).first();

			$input.addClass( "data-table-search" );
			$input.attr( "data-global-key", "s" );
			$input.attr( "autocomplete", "off" );
			$input.attr( "placeholder", i18n.translateResource( "cms:assetmanager.search.placeholder" ) );
			$input.wrap( '<span class="input-icon"></span>' );
			$input.after( '<i class="fa fa-search data-table-search-icon"></i>' );

			$input.keydown( "down", function( e ){
				var $firstResult = $listingTable.find( 'tbody :checkbox:first' );

				if ( $firstResult.length ) {
					$firstResult.focus();
				}
			} );
		},
		oLanguage : {
			oAria : {
				sSortAscending : i18n.translateResource( "cms:datatables.sortAscending", {} ),
				sSortDescending : i18n.translateResource( "cms:datatables.sortDescending", {} )
			},
			oPaginate : {
				sFirst : i18n.translateResource( "cms:datatables.first", { data : [foldersAndAssets], defaultValue : "" } ),
				sLast : i18n.translateResource( "cms:datatables.last", { data : [foldersAndAssets], defaultValue : "" } ),
				sNext : i18n.translateResource( "cms:datatables.next", { data : [foldersAndAssets], defaultValue : "" } ),
				sPrevious : i18n.translateResource( "cms:datatables.previous", { data : [foldersAndAssets], defaultValue : "" } )
			},
			sEmptyTable : i18n.translateResource( "cms:datatables.emptyTable", { data : [foldersAndAssets], defaultValue : "" } ),
			sInfo : i18n.translateResource( "cms:datatables.info", { data : [foldersAndAssets], defaultValue : "" } ),
			sInfoEmpty : i18n.translateResource( "cms:datatables.infoEmpty", { data : [foldersAndAssets], defaultValue : "" } ),
			sInfoFiltered : i18n.translateResource( "cms:datatables.infoFiltered", { data : [foldersAndAssets], defaultValue : "" } ),
			sInfoThousands : i18n.translateResource( "cms:datatables.infoThousands", { data : [foldersAndAssets], defaultValue : "" } ),
			sLengthMenu : i18n.translateResource( "cms:datatables.lengthMenu", { data : [foldersAndAssets], defaultValue : "" } ),
			sLoadingRecords : i18n.translateResource( "cms:datatables.loadingRecords", { data : [foldersAndAssets], defaultValue : "" } ),
			sProcessing : i18n.translateResource( "cms:datatables.processing", { data : [foldersAndAssets], defaultValue : "" } ),
			sZeroRecords : i18n.translateResource( "cms:datatables.zeroRecords", { data : [foldersAndAssets], defaultValue : "" } ),
			sSearch : '',
			sUrl : '',
			sInfoPostFix : ''
		}
	} );

} )( presideJQuery );