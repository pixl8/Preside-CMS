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
	  , orderControl      = [ { target : 0, content : [ "order" ] } ]
	  , noControl         = [ { target : 0, content : [] } ]
	  , assets            = i18n.translateResource( "preside-objects.asset:title" )
	  , activeFolder      = cfrequest.folder || ""
	  , defaultPageLength = cfrequest.defaultPageLength || 10
	  , paginationOptions = cfrequest.paginationOptions || [ 5, 10, 25, 50, 100 ]
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

					if ( dataTable ) {
						dataTable.page( "first" ).draw( "page" );
					}
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
		, expandIcon   : "fa-folder-plus"
	} );
	presideTreeNav = $tree.data( 'presideTreeNav' );

	colConfig.push( {
		  className      : "center"
		, orderable      : false
		, data           : "_checkbox"
		, width          : "5em"
		, defaultContent : ""
		, columnControl  : noControl
	} );
	colConfig.push( {
		  data           : $( $tableHeaders.get(1) ).data( "field" )
		, width          : $( $tableHeaders.get(1) ).data( "width" ) || "auto"
		, orderable      : true
		, className      : "asset-name"
		, defaultContent : ""
		, columnControl  : orderControl
	} );
	colConfig.push( {
		  data           : $( $tableHeaders.get(2) ).data( "field" )
		, width          : $( $tableHeaders.get(2) ).data( "width" ) || "auto"
		, orderable      : true
		, defaultContent : ""
		, columnControl  : orderControl
	} );
	colConfig.push( {
		  data           : $( $tableHeaders.get(3) ).data( "field" )
		, width          : $( $tableHeaders.get(3) ).data( "width" ) || "auto"
		, orderable      : true
		, defaultContent : ""
		, columnControl  : orderControl
	} );
	colConfig.push( {
		  className      : "center"
		, orderable      : false
		, width          : "8em"
		, data           : "_options"
		, defaultContent : ""
		, columnControl  : noControl
	} );

	dataTable = $listingTable.DataTable( {
		  columns      : colConfig
		, serverSide   : true
		, processing   : false
		, stateSave    : true
		, paging       : true
		, lengthChange : true
		, searching    : false
		, ordering     : { indicators : false, handler : false }
		, pageLength   : parseInt( defaultPageLength, 10 )
		, lengthMenu   : paginationOptions
		, order        : []
		, layout       : {
			  topStart    : null
			, topEnd      : null
			, bottomStart : "info"
			, bottomEnd   : [ "pageLength", "paging" ]
		  }
		, ajax : PresideDatatables.hungarianAjax( buildAjaxLink( "assetmanager.assetsForListingGrid" ), function( params ){
			params.folder = activeFolder;
		  } )
		, createdRow : function( row ){
			var $row = $( row );
			$row.attr( "data-context-container", "1" );
			$row.addClass( "clickable" );
		  }
		, preDrawCallback : function() {
			$listingForm.presideLoadingSheen( true );
		  }
		, drawCallback : function() {
			setTimeout( function(){
				$listingForm.presideLoadingSheen( false );
			}, 400 );
		  }
		, language : {
			  emptyTable     : i18n.translateResource( "cms:datatables.emptyTable", { data : [assets], defaultValue : "" } )
			, info           : i18n.translateResource( "cms:datatables.info", { data : [assets], defaultValue : "" } )
			, infoEmpty      : i18n.translateResource( "cms:datatables.infoEmpty", { data : [assets], defaultValue : "" } )
			, infoFiltered   : i18n.translateResource( "cms:datatables.infoFiltered", { data : [assets], defaultValue : "" } )
			, thousands      : i18n.translateResource( "cms:datatables.infoThousands", { data : [assets], defaultValue : "" } )
			, lengthMenu     : i18n.translateResource( "cms:datatables.lengthMenu", { data : [assets], defaultValue : "" } )
			, loadingRecords : i18n.translateResource( "cms:datatables.loadingRecords", { data : [assets], defaultValue : "" } )
			, processing     : i18n.translateResource( "cms:datatables.processing", { data : [assets], defaultValue : "" } )
			, zeroRecords    : i18n.translateResource( "cms:datatables.zeroRecords", { data : [assets], defaultValue : "" } )
			, search         : ""
			, paginate : {
				  first    : '<i class="fa fa-angle-double-left"></i>'
				, previous : '<i class="fa fa-chevron-left"></i>'
				, next     : '<i class="fa fa-chevron-right"></i>'
				, last     : '<i class="fa fa-angle-double-right"></i>'
			  }
			, aria : {
				paginate : {
					  first    : i18n.translateResource( "cms:datatables.first", { data : [assets], defaultValue : "First" } )
					, previous : i18n.translateResource( "cms:datatables.previous", { data : [assets], defaultValue : "Previous" } )
					, next     : i18n.translateResource( "cms:datatables.next", { data : [assets], defaultValue : "Next" } )
					, last     : i18n.translateResource( "cms:datatables.last", { data : [assets], defaultValue : "Last" } )
				}
			  }
		  }
	} );

	setupCheckboxBehaviour();
	setupMultiActionButtons();

} )( presideJQuery );