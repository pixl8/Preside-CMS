/**
 * This script controls the behaviour of the object listing table
 */

( function( $ ){

	var $listingTable  = $( '.notifications-listing-table:first' )
	  , searchDelay    = 400
	  , objectTitle    = i18n.translateResource( "cms:notification.entity.title" ).toLowerCase()
	  , setupDatatable
	  , setupCheckboxBehaviour
	  , setupMultiActionButtons
	  , setupTableRowFocusBehaviour
	  , enabledContextHotkeys;


	setupDatatable = function(){
		var $tableHeaders = $listingTable.find( 'thead > tr > th')
		  , colConfig     = []
		  , i;

		colConfig.push( {
			sClass    : "center",
			bSortable : false,
			sWidth    : "5em"
		} );
		colConfig.push( { bSortable : false } );
		colConfig.push( {
			sClass    : "center",
			bSortable : false,
			sWidth    : "9em"
		} );

		$listingTable.dataTable( {
			aoColumns     : colConfig,
			bStateSave    : true,
			bFilter       : 0,
			aLengthMenu   : [ 5, 10, 25, 50, 100 ],
			sDom          : "<'row'<'col-sm-6'l>r>t<'row'<'col-sm-6'i><'col-sm-6'p>>",
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
				sInfoPostFix : ''
    		}
		} );
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
		var focusSelector = 'tbody :checkbox';

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
	setupCheckboxBehaviour();
	setupMultiActionButtons();

} )( presideJQuery );