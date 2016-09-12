/**
 * This script controls the behaviour of the object listing table
 */

( function( $ ){
	$( '.object-listing-table' ).each( function() {
		var searchDelay        = 400
		, object               = $( this ).data( "objectname" ) || ""
		, allowSearch          = $( this ).data( "allowsearch" )
		, datasourceUrl        = $( this ).data( "datasourceurl" ) || buildAjaxLink( "dataManager.getObjectRecordsForAjaxDataTables", { id : object } )
		, useMultiActions      = typeof $( this ).data( "usemultiactions" ) === "undefined" ? true : $( this ).data( "usemultiactions" )
		, isMultilingual       = $( this ).data( "ismultilingual" ) || false
		, draftsEnabled        = $( this ).data( "draftsenabled" )  || false
		, objectTitle          = $( this ).data( "objecttitle" ) || i18n.translateResource( "preside-objects." + object + ":title" ).toLowerCase()
		, $tableHeaders        = $(this).find( 'thead > tr > th')
		, $elementOfTable      = $( "#"+$(this).attr( "id" ) )
		, colConfig            = []
	  	, defaultSort          = []
	  	, dynamicHeadersOffset = 1
	  	, i
	  	, $header;

		if ( useMultiActions ) {
			colConfig.push( {
				sClass    : "center",
				bSortable : false,
				mData     : "_checkbox",
	 			sWidth    : "5em"
			} );
		}

		if ( draftsEnabled  ) { dynamicHeadersOffset++; }
		if ( isMultilingual ) { dynamicHeadersOffset++; }

		for( i=( useMultiActions ? 1 : 0 ); i < $tableHeaders.length-dynamicHeadersOffset; i++ ){
			$header = $( $tableHeaders.get(i) );
			colConfig.push( { "mData":$( $tableHeaders.get(i) ).data( 'field' ) } );

			if ( typeof $header.data( 'defaultSortOrder' ) !== 'undefined' ) {
				defaultSort.push( [ i, $header.data( 'defaultSortOrder' ) ]);
			}
		}
		if( draftsEnabled ) {
			colConfig.push( {
				bSortable : false,
				mData     : "_status",
				sWidth    : "15em"
			} );
		}
		if( isMultilingual ) {
			colConfig.push( {
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
		$header = $( $tableHeaders.get( $tableHeaders.length-1 ) );

		for( i=0; i < $tableHeaders.length; i++ ){
			$header = $( $tableHeaders.get(i) );

			if ( typeof $header.data( 'class' ) !== 'undefined' ) {
				colConfig[ i ].sClass = $header.data( 'class' );
			}

			if ( typeof $header.data( 'sortable' ) !== 'undefined' ) {
				colConfig[ i ].bSortable = $header.data( 'sortable' );
			}

			if ( typeof $header.data( 'width' ) !== 'undefined' ) {
				colConfig[ i ].sWidth = $header.data( 'width' );
			}
		}

		$elementOfTable.dataTable( {
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

				if( $( this ).data( "clickablerows" ) ) {
					$row.addClass( "clickable" ); // make work with clickable tr Preside system
				}
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
						var $firstResult = $(this).find( useMultiActions ? 'tbody :checkbox:first' : 'tbody tr:first' );

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
		
		if( useMultiActions ) {
		  	var $selectAllCBox   = $elementOfTable.find( "th input:checkbox" )
		  	  , $multiActionBtns = $elementOfTable.parents( ".dataTables_wrapper" ).siblings( ".multi-action-buttons" );

			$selectAllCBox.on( 'click' , function(){
				var $allCBoxes = $elementOfTable.find( 'tr > td:first-child input:checkbox' );

				$allCBoxes.each( function(){
					this.checked = $selectAllCBox.is( ':checked' );
					if ( this.checked ) {
						$( this ).closest( 'tr' ).addClass( 'selected' );
					} else {
						$( this ).closest( 'tr' ).removeClass( 'selected' );
					}
				});
			});

			$multiActionBtns.data( 'hidden', true );
			$elementOfTable.on( "click", "th input:checkbox,tbody tr > td:first-child input:checkbox", function( e ){
				var anyBoxesTicked = $elementOfTable.find( 'tr > td:first-child input:checkbox:checked' ).length;

				if ( anyBoxesTicked == $elementOfTable.find( "td input:checkbox" ).length ) {
					$selectAllCBox.prop( 'checked', true );
				} else {
					$selectAllCBox.prop( 'checked', false );
				}

				$elementOfTable.find( 'tbody > tr' ).each( function(){
					if ( !anyBoxesTicked ) {
						$( this ).removeAttr( 'data-context-container' );
					} else {
						$( this ).attr( 'data-context-container', '1' );
					}
				} );

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

			var $form              = $elementOfTable.parents( '.multi-action-form' )
		  	, $hiddenActionField   = $form.find( '[name=multiAction]' );

			$multiActionBtns.find( "button" ).click( function( e ){
				$hiddenActionField.val( $( this ).attr( 'name' ) );
			} );
		}

		$elementOfTable.on( 'click', 'tbody :checkbox', function(){
			var $cbox = $( this );
			$cbox.closest( 'tr' ).toggleClass( 'selected', $cbox.is( ':checked' ) );
		} );
	});
} )( presideJQuery );