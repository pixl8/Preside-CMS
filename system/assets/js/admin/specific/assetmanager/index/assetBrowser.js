( function( $ ){

	var $tree  = $( ".preside-tree-nav" )
	  , $nodes = $tree.find( ".tree-node" )
	  , $listingTable     = $( '#asset-listing-table' )
	  , $tableHeaders     = $listingTable.find( 'thead > tr > th')
	  , $titleAndActions  = $( '.title-and-actions-container' ).first()
	  , colConfig         = []
	  , assets            = i18n.translateResource( "preside-objects.asset:title" )
	  , activeFolder      = cfrequest.folder || ""
	  , activeFolderTitle = ""
	  , dataTable, i, nodeClickHandler;

	nodeClickHandler = function( $node ){
		var newActiveFolder = $node.data( "folderId" ) || "";

		$nodes.removeClass( "selected" );
		$node.addClass( "selected" );

		if ( activeFolder !== newActiveFolder ) {
			$.ajax({
				  url     : buildAjaxLink( "assetmanager.getFolderTitleAndActions" )
				, data    : { folder : newActiveFolder }
				, method  : "POST"
				, success : function( html ){
					activeFolder = newActiveFolder;
					$titleAndActions.html( html );

					dataTable && dataTable.fnPageChange( 'first' );
				}
			});

		}
	};

	$tree.presideTreeNav( {
		  onClick      : nodeClickHandler
		, collapseIcon : "fa-folder-open"
		, expandIcon   : "fa-folder"
	} );

	for( i=0; i < $tableHeaders.length-1; i++ ){
		colConfig.push( {
			  mData  : $( $tableHeaders.get(i) ).data( 'field' )
			, sWidth : $( $tableHeaders.get(i) ).data( 'width' ) || 'auto'
		} );
	}
	colConfig.push( {
		sClass    : "center",
		bSortable : false,
		sWidth    : "8em",
		mData     : "_options"
	} );

	dataTable = $listingTable.dataTable( {
		aoColumns     : colConfig,
		bServerSide   : true,
		sAjaxSource   : buildAjaxLink( "assetmanager.assetsForListingGrid" ),
		fnServerParams: function ( aoData ) {
	    	aoData.push( { name : "folder", value : activeFolder } );
		},
		bProcessing   : false,
		bStateSave    : false,
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
			$input.attr( "placeholder", i18n.translateResource( "cms:datamanager.search.placeholder", { data : [ assets ], defaultValue : "" } ) );
			$input.wrap( '<span class="input-icon"></span>' );
			$input.after( '<i class="fa fa-search data-table-search-icon"></i>' );
		},
		oLanguage : {
			oAria : {
				sSortAscending : i18n.translateResource( "cms:datatables.sortAscending", {} ),
				sSortDescending : i18n.translateResource( "cms:datatables.sortDescending", {} )
			},
			oPaginate : {
				sFirst : i18n.translateResource( "cms:datatables.first", { data : [assets], defaultValue : "" } ),
				sLast : i18n.translateResource( "cms:datatables.last", { data : [assets], defaultValue : "" } ),
				sNext : i18n.translateResource( "cms:datatables.next", { data : [assets], defaultValue : "" } ),
				sPrevious : i18n.translateResource( "cms:datatables.previous", { data : [assets], defaultValue : "" } )
			},
			sEmptyTable : i18n.translateResource( "cms:datatables.emptyTable", { data : [assets], defaultValue : "" } ),
			sInfo : i18n.translateResource( "cms:datatables.info", { data : [assets], defaultValue : "" } ),
			sInfoEmpty : i18n.translateResource( "cms:datatables.infoEmpty", { data : [assets], defaultValue : "" } ),
			sInfoFiltered : i18n.translateResource( "cms:datatables.infoFiltered", { data : [assets], defaultValue : "" } ),
			sInfoThousands : i18n.translateResource( "cms:datatables.infoThousands", { data : [assets], defaultValue : "" } ),
			sLengthMenu : i18n.translateResource( "cms:datatables.lengthMenu", { data : [assets], defaultValue : "" } ),
			sLoadingRecords : i18n.translateResource( "cms:datatables.loadingRecords", { data : [assets], defaultValue : "" } ),
			sProcessing : i18n.translateResource( "cms:datatables.processing", { data : [assets], defaultValue : "" } ),
			sZeroRecords : i18n.translateResource( "cms:datatables.zeroRecords", { data : [assets], defaultValue : "" } ),
			sSearch : '',
			sUrl : '',
			sInfoPostFix : ''
		}
	} );

} )( presideJQuery );