/**
 * This script controls the behaviour of the object listing table
 */

( function( $ ){

	var $listingTable  = $( '.notifications-listing-table:first' )
	  , objectTitle    = i18n.translateResource( "cms:notification.entity.title" ).toLowerCase()
	  , setupDatatable
	  , setupCheckboxBehaviour
	  , setupMultiActionButtons
	  , setupTableRowFocusBehaviour
	  , enabledContextHotkeys;


	setupDatatable = function(){
		if ( !$listingTable.length ) {
			return;
		}

		$listingTable.DataTable( {
			  columns      : [
				  { className : "center", orderable : false, width : "5em" }
				, { orderable : false }
				, { className : "center", orderable : false, width : "9em" }
			  ]
			, stateSave    : true
			, searching    : false
			, lengthMenu   : [ 5, 10, 25, 50, 100 ]
			, layout       : {
				  topStart    : null
				, topEnd      : "pageLength"
				, bottomStart : "info"
				, bottomEnd   : "paging"
			  }
			, createdRow : function( row ){
				var $row = $( row );
				$row.attr( "data-context-container", "1" );
				$row.addClass( "clickable" );
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