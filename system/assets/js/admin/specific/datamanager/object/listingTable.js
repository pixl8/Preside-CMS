/**
 * This script controls the behaviour of the object listing table
 */

( function( $ ){

	var $listingTable  = $( '.object-listing-table:first' )
	  , searchDelay    = 400
	  , setupDatatable
	  , setupCheckboxBehaviour
	  , setupTableRowFocusBehaviour
	  , object              = cfrequest.objectName || ""
	  , allowSearch         = cfrequest.allowSearch
	  , datasourceUrl       = cfrequest.datasourceUrl || buildAjaxLink( "dataManager.getObjectRecordsForAjaxDataTables", { id : object } )
	  , useMultiActions     = typeof cfrequest.useMultiActions === "undefined" ? true : cfrequest.useMultiActions
	  , isMultilingual      = cfrequest.isMultilingual      || false
	  , object              = cfrequest.objectName  || ""
	  , objectTitle         = cfrequest.objectTitle || i18n.translateResource( "preside-objects." + object + ":title" ).toLowerCase()
	  , enabledContextHotkeys;

	setupDatatable = function(){
		var $tableHeaders = $listingTable.find( 'thead > tr > th')
		  , colConfig     = []
		  , defaultSort   = []
		  , i;

		if ( useMultiActions ) {
			colConfig.push( {
				sClass    : "center",
				bSortable : false,
				mData     : "_checkbox",
	 			sWidth    : "5em"
			} );
		}

		for( i=( useMultiActions ? 1 : 0 ); i < $tableHeaders.length-1; i++ ){
			colConfig.push( { "mData":$( $tableHeaders.get(i) ).data( 'field' ) } );
			if ( typeof $( $tableHeaders.get(i) ).data( 'defaultSortOrder' ) !== 'undefined' ) {
				defaultSort.push( [ i, $( $tableHeaders.get(i) ).data( 'defaultSortOrder' ) ]);
			}
		}
		if( isMultilingual ) {
			colConfig.push( {
				sClass    : "center",
				bSortable : false,
				mData     : "_translateStatus",
				sWidth    : "12em"
			} );
		}

		colConfig.push( {
			sClass    : "center",
			bSortable : false,
			mData     : "_options",
			sWidth    : "9em"
		} );

		$listingTable.dataTable( {
			aoColumns     : colConfig,
			aaSorting     : defaultSort,
			bServerSide   : true,
			bProcessing   : true,
			bStateSave    : true,
			bFilter       : allowSearch,
			bAutoWidth    : false,
			aLengthMenu   : [ 5, 10, 25, 50, 100 ],
			sDom          : "<'row'<'col-sm-6'l><'col-sm-6'f>r>t<'row'<'col-sm-6'i><'col-sm-6'p>>",
			sAjaxSource   : datasourceUrl,
			fnRowCallback : function( row ){
				$row = $( row );
				$row.attr( 'data-context-container', "1" ); // make work with context aware Preside hotkeys system
				$row.addClass( "clickable" ); // make work with clickable tr Preside system
			},
			fnInitComplete : function( settings ){
				if ( allowSearch ) {
					var $searchContainer = $( settings.aanFeatures.f[0] )
					  , $input           = $searchContainer.find( "input" ).first();

					$input.addClass( "data-table-search" );
					$input.attr( "data-global-key", "s" );
					$input.attr( "autocomplete", "off" );
					$input.attr( "placeholder", i18n.translateResource( "cms:datamanager.search.placeholder", { data : [ objectTitle ], defaultValue : "" } ) );
					$input.wrap( '<span class="input-icon"></span>' );
					$input.after( '<i class="fa fa-search data-table-search-icon"></i>' );

					$input.keydown( "down", function( e ){
						var $firstResult = $listingTable.find( useMultiActions ? 'tbody :checkbox:first' : 'tbody tr:first' );

						if ( $firstResult.length ) {
							$firstResult.focus();
						}
					} );
				}
			},
			oLanguage : {
      			oAria : {
					sSortAscending : i18n.translateResource( "cms:datatables.sortAscending", {} ),
					sSortDescending : i18n.translateResource( "cms:datatables.sortDescending", {} )
				},
				oPaginate : {
					sFirst : i18n.translateResource( "cms:datatables.first", { data : [objectTitle], defaultValue : "" } ),
					sLast : i18n.translateResource( "cms:datatables.last", { data : [objectTitle], defaultValue : "" } ),
					sNext : i18n.translateResource( "cms:datatables.next", { data : [objectTitle], defaultValue : "" } ),
					sPrevious : i18n.translateResource( "cms:datatables.previous", { data : [objectTitle], defaultValue : "" } )
				},
				sEmptyTable : i18n.translateResource( "cms:datatables.emptyTable", { data : [objectTitle], defaultValue : "" } ),
				sInfo : i18n.translateResource( "cms:datatables.info", { data : [objectTitle], defaultValue : "" } ),
				sInfoEmpty : i18n.translateResource( "cms:datatables.infoEmpty", { data : [objectTitle], defaultValue : "" } ),
				sInfoFiltered : i18n.translateResource( "cms:datatables.infoFiltered", { data : [objectTitle], defaultValue : "" } ),
				sInfoThousands : i18n.translateResource( "cms:datatables.infoThousands", { data : [objectTitle], defaultValue : "" } ),
				sLengthMenu : i18n.translateResource( "cms:datatables.lengthMenu", { data : [objectTitle], defaultValue : "" } ),
				sLoadingRecords : i18n.translateResource( "cms:datatables.loadingRecords", { data : [objectTitle], defaultValue : "" } ),
				sProcessing : i18n.translateResource( "cms:datatables.processing", { data : [objectTitle], defaultValue : "" } ),
				sZeroRecords : i18n.translateResource( "cms:datatables.zeroRecords", { data : [objectTitle], defaultValue : "" } ),
				sSearch : '',
				sUrl : '',
				sInfoPostFix : ''
    		}
		} ).fnSetFilteringDelay( searchDelay );
	};

	setupCheckboxBehaviour = function(){
	  	var $selectAllCBox   = $listingTable.find( "th input:checkbox" )
	  	  , $multiActionBtns = $( "#multi-action-buttons" );

		$selectAllCBox.on( 'click' , function(){
			var $allCBoxes = $listingTable.find( 'tr > td:first-child input:checkbox' );

			$allCBoxes.each( function(){
				this.checked = $selectAllCBox.is( ':checked' );
				$(this).closest('tr').toggleClass('selected');
			});
		});

		$multiActionBtns.data( 'hidden', true );
		$listingTable.on( "click", "th input:checkbox,tbody tr > td:first-child input:checkbox", function( e ){
			var anyBoxesTicked = $listingTable.find( 'tr > td:first-child input:checkbox:checked' ).length;

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
		var $form              = $( '#multi-action-form' )
		  , $hiddenActionField = $form.find( '[name=multiAction]' );

		$( "#multi-action-buttons button" ).click( function( e ){
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

	setupTableRowFocusBehaviour = function(){
		var focusSelector = useMultiActions ? 'tbody :checkbox' : 'tbody tr a';

		$listingTable.on( 'focus', focusSelector, function(){
			$( this ).closest( 'tr' ).addClass( 'focus' );
		} );
		$listingTable.on( 'blur', focusSelector, function(){
			$( this ).closest( 'tr' ).removeClass( 'focus' );
		} );

		$listingTable.on( 'click', 'tbody :checkbox', function(){
			var $cbox = $( this );
			$cbox.closest( 'tr' ).toggleClass( 'selected', $cbox.is( ':checked' ) );
		} );

		$listingTable.on( 'keydown', 'tr.focus', 'return', function(){
			$( this ).click();
		} );
	};

	setupDatatable();
	setupTableRowFocusBehaviour();

	if ( useMultiActions ) {
		setupCheckboxBehaviour();
		setupMultiActionButtons();
	}

} )( presideJQuery );