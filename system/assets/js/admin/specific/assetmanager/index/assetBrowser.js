( function( $ ){

	var $tree  = $( ".preside-tree-nav" )
	  , $nodes = $tree.find( ".tree-node" )
	  , $listingTable     = $( '#asset-listing-table' )
	  , $listingForm      = $( '.asset-manager-listing-form' ).first()
	  , $tableHeaders     = $listingTable.find( 'thead > tr > th')
	  , $titleAndActions  = $( '.title-and-actions-container' ).first()
	  , $pageSubtitle     = $( '.page-subtitle' ).first()
	  , $multiActions     = $( '#multi-action-buttons' )
	  , colConfig         = []
	  , assets            = i18n.translateResource( "preside-objects.asset:title" )
	  , activeFolder      = cfrequest.folder || ""
	  , activeFolderTitle = ""
	  , dataTable, i, nodeClickHandler, presideTreeNav, setupCheckboxBehaviour, enabledContextHotkeys, setupMultiActionButtons;

	nodeClickHandler = function( $node, e ){
		var newActiveFolder = $node.data( "folderId" ) || ""
		  , $clickedElement = $( e.target );

		$nodes.removeClass( "selected" );
		$node.addClass( "selected" );

		if ( $clickedElement.hasClass( 'folder-name' ) && $node.parent().hasClass( 'tree-folder' ) ) {
			presideTreeNav.toggleNode( $node.parent() );
		}

		if ( activeFolder !== newActiveFolder ) {
			$.ajax({
				  url     : buildAjaxLink( "assetmanager.getFolderTitleAndActions" )
				, data    : { folder : newActiveFolder }
				, method  : "POST"
				, success : function( data ){
					activeFolder = newActiveFolder;
					$titleAndActions.html( data.title );
					$pageSubtitle.html( $node.find( '.folder-name:first' ).html() );
					$multiActions.html( $( data.multiActions ).html() );

					dataTable && dataTable.fnPageChange( 'first' );
				}
				, beforeSend: function() {
					$listingForm.presideLoadingSheen( true );
				}
				, complete: function() {
					setTimeout( function(){
						$listingForm.presideLoadingSheen( false );
					}, 400 );
				}
			});

		}
	};

	setupCheckboxBehaviour = function(){
	  	var $selectAllCBox   = $listingTable.find( "th input:checkbox" )
	  	  , $multiActionBtns = $( "#multi-action-buttons" );

		$selectAllCBox.on( 'click' , function(){
			var $allCBoxes = $listingTable.find( 'tr > td:first-child input:checkbox' );

			$allCBoxes.each( function(){
				this.checked = $selectAllCBox.is( ':checked' );
				if( this.checked ) {
					$( this ).closest( 'tr' ).addClass( 'selected' );
				} else {
					$( this ).closest( 'tr' ).removeClass( 'selected' );
				}
			});
		});

		$listingTable.on( 'click', 'tbody :checkbox', function(){
			var $cbox = $( this );
			$cbox.closest( 'tr' ).toggleClass( 'selected', $cbox.is( ':checked' ) );
		});

		$multiActionBtns.data( 'hidden', true );
		$listingTable.on( "click", "th input:checkbox,tbody tr > td:first-child input:checkbox", function( e ){
			var anyBoxesTicked = $listingTable.find( 'tr > td:first-child input:checkbox:checked' ).length;

			if( anyBoxesTicked == $listingTable.find( "td input:checkbox" ).length ) {
				$selectAllCBox.prop( 'checked', true );
			} else {
				$selectAllCBox.prop( 'checked', false );
			}

			enabledContextHotkeys( !anyBoxesTicked );

			if ( anyBoxesTicked && $multiActionBtns.data( 'hidden' ) ) {
				$multiActionBtns
					.slideDown( 250 )
					.data( 'hidden', false )
					.find( "button" ).prop( 'disabled', false );

			} else if ( !anyBoxesTicked && !$multiActionBtns.data( 'hidden' ) ) {
				$multiActionBtns
					.slideUp( 250 )
					.data( 'hidden', true )
					.find( "button" ).prop( 'disabled', true );
			}
		} );
	};

	setupMultiActionButtons = function(){
		$( "body" ).on( "click", "#multi-action-buttons button", function( e ){
			var $hiddenActionField = $( this ).closest( "form" ).find( '[name=multiAction]' );

			$hiddenActionField.val( $( this ).attr( 'name' ) );
		} );
	};

	enabledContextHotkeys = function( enabled ){
		$listingTable.find( 'tbody > tr' ).each( function(){
			if ( enabled ) {
				$( this ).attr( 'data-context-container', '1' );
			} else {
				$( this ).removeAttr( 'data-context-container' );
			}
		} );
	};

	$tree.presideTreeNav( {
		  onClick      : nodeClickHandler
		, collapseIcon : "fa-folder-open"
		, expandIcon   : "fa-folder"
	} );
	presideTreeNav = $tree.data( 'presideTreeNav' );

	colConfig.push( {
		sClass    : "center",
		bSortable : false,
		mData     : "_checkbox",
		sWidth    : "5em"
	} );
	colConfig.push( {
		  mData     : $( $tableHeaders.get(1) ).data( 'field' )
		, sWidth    : $( $tableHeaders.get(1) ).data( 'width' ) || 'auto'
		, bSortable : true
		, sClass    : "asset-name"
	} );
	colConfig.push( {
		  mData     : $( $tableHeaders.get(2) ).data( 'field' )
		, sWidth    : $( $tableHeaders.get(2) ).data( 'width' ) || 'auto'
		, bSortable : true
	} );
	colConfig.push( {
		  mData     : $( $tableHeaders.get(3) ).data( 'field' )
		, sWidth    : $( $tableHeaders.get(3) ).data( 'width' ) || 'auto'
		, bSortable : true
	} );
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
		processing    : true,
		bStateSave    : true,
		bPaginate     : true,
		bLengthChange : true,
		aaSorting     : [],
		sDom          : "t<'dataTables_pagination bottom'<'pull-left'i><'pull-left'l><'pull-right'p><'clearfix'>",
		fnRowCallback : function( row ){
			$row = $( row );
			$row.attr( 'data-context-container', "1" ); // make work with context aware Preside hotkeys system
			$row.addClass( "clickable" ); // make work with clickable tr Preside system
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
			sProcessing : $listingForm.presideLoadingSheen( true ),
			sZeroRecords : i18n.translateResource( "cms:datatables.zeroRecords", { data : [assets], defaultValue : "" } ),
			sSearch : '',
			sUrl : '',
			sInfoPostFix : ''
		}
	}).on( 'draw.dt', function () {
		setTimeout( function(){
			$listingForm.presideLoadingSheen( false );
		}, 400 );
    });

	setupCheckboxBehaviour();
	setupMultiActionButtons();

} )( presideJQuery );