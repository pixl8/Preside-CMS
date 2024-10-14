/**
 * This script controls the behaviour of the object listing table
 */

( function( $ ){

	$.fn.dataListingTable = function(){
		return this.each( function(){
			var $listingTable  = $( this )
			  , tableSettings  = $listingTable.data()
			  , tableId        = $listingTable.attr( "id" )
			  , datatable
			  , searchDelay    = 400
			  , setupDatatable
			  , setupCheckboxBehaviour
			  , setupTableRowFocusBehaviour
			  , setupFilters
			  , updateFilterFolderCount
			  , setupDataExport
			  , setupQuickSaveFilterIframeModal
			  , prePopulateFilter
			  , toggleAdvancedFilter
			  , dtSettings
			  , getFavourites
			  , setFavourites
			  , updateSelectAllOptionRecordCount
			  , activateSelectAllOption
			  , deactivateSelectAllOption
			  , object                   = tableSettings.objectName               || cfrequest.objectName     || ""
			  , datasourceUrl            = tableSettings.datasourceUrl            || cfrequest.datasourceUrl  || buildAjaxLink( "dataManager.getObjectRecordsForAjaxDataTables", { id : object } )
			  , isMultilingual           = tableSettings.isMultilingual           || cfrequest.isMultilingual || false
			  , draftsEnabled            = tableSettings.draftsEnabled            || cfrequest.draftsEnabled  || false
			  , object                   = tableSettings.objectName               || cfrequest.objectName     || ""
			  , objectTitle              = tableSettings.objectTitle              || cfrequest.objectTitle    || i18n.translateResource( "preside-objects." + object + ":title" )
			  , allowSearch              = tableSettings.allowSearch              || cfrequest.allowSearch
			  , allowFilter              = tableSettings.allowFilter              || cfrequest.allowFilter
			  , allowDataExport          = tableSettings.allowDataExport          || cfrequest.allowDataExport
			  , allowSaveExport          = tableSettings.allowSaveExport          || cfrequest.allowSaveExport
			  , noRecordMessage          = tableSettings.noRecordMessage          || i18n.translateResource( "cms:datatables.emptyTable" )
			  , noRecordTableHide        = tableSettings.noRecordTableHide        || false
			  , noRecordTableHideMessage = tableSettings.noRecordTableHideMessage || i18n.translateResource( "cms:preside-objects.default.field.no_value.title" )
			  , favouritesUrl            = tableSettings.favouritesUrl            || cfrequest.favouritesUrl || buildAjaxLink( "rulesEngine.ajaxDataGridFavourites", { objectName : object } )
			  , compact                  = tableSettings.compact                  || cfrequest.compact
			  , defaultPageLength        = cfrequest.defaultPageLength            || 10
			  , paginationOptions        = cfrequest.paginationOptions            || [ 5, 10, 25, 50, 100 ]
			  , clickableRows            = typeof tableSettings.clickableRows   === "undefined" ? ( typeof cfrequest.clickableRows   === "undefined" ? true : cfrequest.clickableRows   ) : tableSettings.clickableRows
			  , noActions                = typeof tableSettings.noActions       === "undefined" ? ( typeof cfrequest.noActions       === "undefined" ? false: cfrequest.noActions       ) : tableSettings.noActions
			  , useMultiActions          = typeof tableSettings.useMultiActions === "undefined" ? ( typeof cfrequest.useMultiActions === "undefined" ? true : cfrequest.useMultiActions ) : tableSettings.useMultiActions
			  , $filterDiv               = $( '#' + tableId + '-filter' )
			  , $favouritesDiv           = $( '#' + tableId + '-favourites' )
			  , UNKNOWN_TOTAL            = 1000000001
			  , $filterLink
			  , enabledContextHotkeys, refreshFavourites
			  , lastAjaxResult
			  , filterSettings, allowUseFilter=false, allowManageFilter=false, manageFiltersLink=""
			  , filtersPopulated=false
			  , hasPreFilters=false;

			if ( allowFilter ) {
				filterSettings = $( ".object-listing-table-filter" ).data();
				if ( filterSettings !== null ) {
					allowUseFilter    = filterSettings.allowUseFilter    || false;
					allowManageFilter = filterSettings.allowManageFilter || false;
					if ( allowManageFilter ) {
						manageFiltersLink = filterSettings.manageFiltersLink || "";
					}
				}
			}

			setupDatatable = function(){
				var $tableHeaders        = $listingTable.find( 'thead > tr > th')
				  , colConfig            = []
				  , defaultSort          = []
				  , dynamicHeadersOffset = 1
				  , sDom
				  , i, $header;

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
				if ( noActions ) { dynamicHeadersOffset--; }

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

				if ( !noActions ) {
					colConfig.push( {
						sClass    : "text-right",
						bSortable : false,
						mData     : "_options",
						sWidth    : "13em"
					} );
				}
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

				if ( allowFilter ) {
					sDom = "<'well well-sm'fr<'clearfix'>><'dataTables_pagination top clearfix'<'pull-left'i><'pull-left'l><'pull-right'p>><'datatable-container't><'dataTables_pagination bottom'<'pull-left'i><'pull-left'l><'pull-right'p>><'clearfix'>";
				} else if ( compact ) {
					sDom = "frt<'dataTables_pagination bottom'<'pull-left'i><'pull-left'l><'pull-right'p><'clearfix'>";
				} else {
					sDom = "fr<'dataTables_pagination top clearfix'<'pull-left'i><'pull-left'l><'pull-right'p>><'datatable-container't><'dataTables_pagination bottom'<'pull-left'i><'pull-left'l><'pull-right'p><'clearfix'>";
				}

				datatable = $listingTable.dataTable( {
					aoColumns     : colConfig,
					aaSorting     : defaultSort,
					aoColumnDefs  : [ { "bSortable": false, "aTargets": [ 'no-sorting' ] } ],
					bServerSide   : true,
					bProcessing   : true,
					bStateSave    : true,
					bFilter       : allowSearch,
					iDeferLoading : 0,
					bAutoWidth    : false,
					iDisplayLength: parseInt( defaultPageLength ),
					aLengthMenu   : paginationOptions,
					sDom          : sDom,
					sAjaxSource   : datasourceUrl,
					sServerMethod : "POST",
					fnRowCallback : function( row ){
						$row = $( row );
						$row.attr( 'data-context-container', "1" ); // make work with context aware Preside hotkeys system

						if( clickableRows ) {
							$row.addClass( "clickable" ); // make work with clickable tr Preside system
						}
					},
					fnInitComplete : function( settings ){
						dtSettings = settings;

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

						if ( allowFilter ) {
							setupFilters( settings );
						}

						if ( allowDataExport ) {
							setupDataExport( settings );
						}

						if ( !hasPreFilters ) {
							this.fnDraw();
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
						sEmptyTable : noRecordMessage,
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
					},
					fnServerParams : function( aoData ) {
						if ( allowFilter ) {
							aoData.push( { "name": "sFilterExpression", "value": $filterDiv.find( "[name=filter]" ).val() } );
							var favourites = getFavourites();
							if ( favourites && favourites.length ) {
								aoData.push( { "name": "sSavedFilterExpressions", "value": favourites } );
							} else {
								aoData.push( { "name": "sSavedFilterExpressions", "value": $filterDiv.find( "[name=filters]" ).val() } );
							}
						}
					},
					fnFiltersPopulatedCallback: function() {
						return allowFilter ? filtersPopulated : true;
					},
					fnCookieCallback: function( sName, oData, sExpires, sPath ) {
						if ( allowFilter ) {
							oData.oFilter = {
								  filter     : $filterDiv.find( "[name=filter]" ).val()
								, filters    : $filterDiv.find( "[name=filters]" ).val()
								, favourites : getFavourites()
							};
						}

						return sName + "="+JSON.stringify(oData)+"; expires=" + sExpires +"; path=" + sPath;
					},
					fnPreDrawCallback : function() {
						$( ".datatable-container" ).presideLoadingSheen( true );
					},
					fnDrawCallback : function( dt ) {
						$( ".datatable-container" ).presideLoadingSheen( false );
						updateSelectAllOptionRecordCount( dt.fnFormatNumber( dt._iRecordsTotal ) );
					},
					fnFooterCallback: function ( nFoot, aaData, iStart, iEnd, aiDisplay ) {
						if ( $( nFoot ).length ) {
							if ( $( nFoot ).hasClass( "multi-column-footer" ) ) {
								if ( lastAjaxResult && typeof lastAjaxResult.sFooter !== "undefined" && lastAjaxResult.sFooter.length ) {
									$( nFoot ).html( lastAjaxResult.sFooter );
								} else {
									$( nFoot ).html( "" );
								}
							} else {
								var nRow = $( nFoot ).children('tr')[0];
								if ( lastAjaxResult && typeof lastAjaxResult.sFooter !== "undefined" && lastAjaxResult.sFooter.length ) {
									$( nRow ).show().find( "th:first" ).html( lastAjaxResult.sFooter );
								} else {
									$( nRow ).hide().find( "th:first" ).html( "" );
								}
							}
						}
					},
					fnInfoCallback: function( oSettings, iStart, iEnd, iMax, iTotal, sPre ) {
						var info = "";

						if ( iTotal == UNKNOWN_TOTAL ) {
							info = i18n.translateResource( "cms:datatables.infoCountUnknown", { data : [objectTitle], defaultValue : "" } );
						} else {
							info = i18n.translateResource( "cms:datatables.info", { data : [objectTitle], defaultValue : "" } );
						}

						info = info.replace( "_START_", Intl.NumberFormat().format( iStart ) );
						info = info.replace( "_END_"  , Intl.NumberFormat().format( iEnd   ) );
						info = info.replace( "_TOTAL_", Intl.NumberFormat().format( iTotal ) );

						return info;
					}
				} ).fnSetFilteringDelay( searchDelay );

				$listingTable.on( "xhr", function( event, settings, json ){
					lastAjaxResult = json;

					if ( noRecordTableHide ) {
						var searchQuery = "";

						if ( allowSearch ) {
							searchQuery = $( dtSettings.aanFeatures.f[0] ).find( "input.data-table-search" ).val();
						}

						if ( searchQuery.length == 0 ) {
							var iTotalRecords = json.iTotalRecords || 0;

							if ( iTotalRecords == 0 ) {
								var $tableContainer = $( "#"+tableId+"-container" );

								$tableContainer.parent().append( noRecordTableHideMessage );

								$tableContainer.hide();
							}
						}
					}
				} );
			};

			setupCheckboxBehaviour = function(){
				var $selectAllCBox   = $listingTable.find( "th input:checkbox" )
				  , $multiActionBtns = $listingTable.closest( '.multi-action-form' ).find( ".multi-action-buttons" );

				$selectAllCBox.on( 'click' , function(){
					var $allCBoxes = $listingTable.find( 'tr > td:first-child input:checkbox' )
					  , isChecked  = $selectAllCBox.is( ':checked' );

					$allCBoxes.each( function(){
						this.checked = isChecked;
						if ( this.checked ) {
							$( this ).closest( 'tr' ).addClass( 'selected' );
						} else {
							$( this ).closest( 'tr' ).removeClass( 'selected' );
						}
					});

					if ( isChecked ) {
						activateSelectAllOption();
					} else {
						deactivateSelectAllOption();
					}
				});

				$multiActionBtns.data( 'hidden', true );
				$listingTable.on( "click", "th input:checkbox,tbody tr > td:first-child input:checkbox", function( e ){
					var anyBoxesTicked = $listingTable.find( 'tr > td:first-child input:checkbox:checked' ).length;

					if ( anyBoxesTicked == $listingTable.find( "td input:checkbox" ).length ) {
						$selectAllCBox.prop( 'checked', true );
						activateSelectAllOption();
					} else {
						$selectAllCBox.prop( 'checked', false );
						deactivateSelectAllOption();
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
				var $form              = $listingTable.closest( '.multi-action-form' )
				  , $hiddenActionField = $form.find( '[name=multiAction]' );

				$form.find( ".multi-action-buttons button" ).click( function( e ){
					$hiddenActionField.val( $( this ).attr( 'name' ) );
				} );

				$form.on( "submit", function(){
					var allRecords = $form.find( "[name=batchAll]:checked" ).length > 0;
					if ( allRecords ) {
						var $batchSrcArgs = $( '<input type="hidden" name="batchSrcArgs">' );

						$batchSrcArgs.val( lastAjaxResult.sBatchSource );
						$form.append( $batchSrcArgs );

						$form.find( "input[name=id]" ).remove();
					}
				} );
			};

			updateSelectAllOptionRecordCount = function( newCount ){
				var $form = $listingTable.closest( '.multi-action-form' );

				if ( $form.length ) {
					$form.find( ".batch-update-select-all .matching-record-count" ).each( function(){
						$( this ).html( newCount );
					} );
				}
			};
			activateSelectAllOption = function(){
				var $form = $listingTable.closest( '.multi-action-form' )
				  , $selectAllContainer;

				if ( $form.length ) {
					$selectAllContainer = $form.find( ".batch-update-select-all" );
					if ( $selectAllContainer.length ) {
						if ( datatable.fnPagingInfo().iTotalPages > 1 && lastAjaxResult.sBatchSource ) {
							$selectAllContainer.show();
						} else {
							deactivateSelectAllOption();
						}
					}
				}
			};
			deactivateSelectAllOption = function(){
				var $form = $listingTable.closest( '.multi-action-form' );
				var $selectAllContainer;

				if ( $form.length ) {
					$selectAllContainer = $form.find( ".batch-update-select-all" );

					if ( $selectAllContainer.length ) {
						$selectAllContainer.find( "input[name='batchAll']" ).prop( "checked", false );
						$selectAllContainer.hide();
					}
				}
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
				$listingTable.on( 'click', 'tbody :checkbox', function(){
					var $cbox = $( this );
					$cbox.closest( 'tr' ).toggleClass( 'selected', $cbox.is( ':checked' ) );
				} );
			};

			setupFilters = function( settings ){
				// setup DOM
				var $searchContainer = $( settings.aanFeatures.f[0] )
				  , filterState, $manageLink, $filterLinksContainer = $( '<div class="pull-right filter-links-container"></div>' );

				if ( allowUseFilter ) {
					$filterLink = $( '<a href="#"><i class="fa fa-fw fa-caret-right"></i> ' + i18n.translateResource( "cms:datatables.show.advanced.filters" ) + '</a>' );
					$filterLinksContainer.append( $filterLink );

					if ( allowManageFilter && manageFiltersLink.length ) {
						$manageLink = $( '<a href="' + manageFiltersLink + '"><i class="fa fa-fw fa-cogs"></i> ' + i18n.translateResource( "cms:datatables.manage.filters.link" ) + '</a>' );
						$filterLinksContainer.prepend( $manageLink );
					}

					$searchContainer.append( $filterLinksContainer );
				}

				if ( $favouritesDiv.length ) {
					$searchContainer.append( $favouritesDiv );
					$favouritesDiv.removeClass( "hide" );
					$favouritesDiv.on( "click", ".filter", function( e ){
						e.preventDefault();
						var $filter = $( this )
						  , $otherFilters = $filter.siblings( ".filter" );

						$filter.toggleClass( "active" ).find( ":focus" ).blur();

						if ( $filter.parents( ".data-table-favourite-group" ).length ) {
							e.stopPropagation();
							updateFilterFolderCount( $filter.closest( ".data-table-favourite-group" ) );
						}

						datatable.fnDraw();
					} );
				}
				$searchContainer.parent().append( $filterDiv );

				$filterDiv.find( ".well" ).removeClass( "well" );

				// toggles between filter mode + basic search mode
				if ( allowUseFilter ) {
					$filterLink.on( "click", toggleAdvancedFilter );
				}

				// filter change listener
				$filterDiv.on( "change", function( e ){
					datatable.fnDraw();

					if ( allowManageFilter ) {
						$filterDiv.find( ".save-filter-btn" ).prop( "disabled", !$filterDiv.find( "[name=filter]" ).val().length );
					}
				} );

				if ( allowManageFilter ) {
					setupQuickSaveFilterIframeModal( $filterDiv );
				}

				try {
					filterState = settings.oLoadedState.oFilter;
				} catch( e ) {}

				if ( typeof filterState !== "undefined" ) {
					if ( allowUseFilter && typeof filterState.filter !== "undefined" ) {
						if ( filterState.filter.length ) {
							prePopulateFilter( filterState.filter );
						} else {
							filtersPopulated = true;
						}
					}
					if ( filterState.favourites && filterState.favourites.length ) {
						setFavourites( filterState.favourites );
					}
				} else {
					filtersPopulated = true;
				}
			};

			updateFilterFolderCount = function( $group ) {
				var activeCount = $group.find( ".filter.active" ).length
				  , $titleEl    = $group.find( ".dropdown-toggle:first" )
				  , $counterEl  = $titleEl.find( ".badge" );

				$counterEl.html( activeCount );

				activeCount ? $group.addClass( "has-selections" ) : $group.removeClass( "has-selections" );
			};

			setupDataExport = function( settings ){
				// setup DOM
				var paginationContainers = settings.aanFeatures.p
				  , $uberContainer       = $( "#"+tableId+"-container" )
				  , $dataExportContainer = $( ".object-listing-table-export", $uberContainer )
				  , $configForm          = $( ".object-listing-data-export-config-form", $uberContainer )
				  , $exportBtn           = $( ".object-listing-data-export-button", $uberContainer )
				  , iframeSrc            = $exportBtn.attr( "href" )
				  , i, $container, modalOptions, callbacks, processExport, saveExport, exportConfigModal, configIframe;

				for( i=0; i<paginationContainers.length; i++ ) {
					$container = $( paginationContainers[i] );
					$container.prepend( $dataExportContainer.html() );
				}

				modalOptions    = {
					title      : i18n.translateResource( "cms:dataexport.config.modal.title" ),
					className  : "full-screen-dialog",
					buttons : {
						cancel : {
							  label     : '<i class="fa fa-reply"></i> ' + i18n.translateResource( "cms:cancel.btn" )
							, className : "btn-default"
						},
						ok : {
							  label     : '<i class="fa fa-download"></i> ' + i18n.translateResource( "cms:downloadnow.btn" )
							, className : "btn-primary ok-button"
							, callback  : function(){ return processExport(); }
						}
					}
				}

				if ( allowSaveExport ) {
					modalOptions.buttons.save = {
						  label     : '<i class="fa fa-save"></i> ' + i18n.translateResource( "cms:saveforlater.btn" )
						, className : "btn-success"
						, callback  : function(){ return saveExport(); }
					};
				}
				callbacks = {
					onLoad : function( iframe ) {
						configIframe = iframe;
					}
				};
				processExport = function(){
					var $configForm      = $( configIframe.document ).find( ".export-config-form" )
					  , $submissionForm  = $( ".object-listing-table-export-form", $uberContainer )
					  , sortColumns      = dtSettings.aaSorting
					  , allColumns       = dtSettings.aoColumns
					  , config           = $configForm.serializeObject()
					  , sortOrder        = []
					  , favourites, key, $hiddenInput, i, $searchContainer;

					if ( allowFilter ) {
						config.filterExpressions = $filterDiv.find( "[name=filter]" ).val();

						favourites = getFavourites();
						if ( favourites && favourites.length ) {
							config.savedFilters = favourites;
						} else {
							config.savedFilters = $filterDiv.find( "[name=filters]" ).val();
						}
					}

					if ( allowSearch ) {
						$searchContainer = $( dtSettings.aanFeatures.f[0] );
						config.searchQuery = $searchContainer.find( "input.data-table-search" ).val();
					}

					for( key in config ) {
						$hiddenInput = $submissionForm.find( "[name=" + key + "]" );

						if ( !$hiddenInput.length ) {
							$hiddenInput = $( '<input type="hidden" name="' + key + '">' );
							$submissionForm.append( $hiddenInput );
						}

						$hiddenInput.val( config[ key ] );
					}

					for( i=0; i<sortColumns.length; i++ ) {
						sortOrder.push( allColumns[ sortColumns[ i ][ 0 ] ].mData + " " + sortColumns[ i ][ 1 ] );
					}
					if ( sortOrder.length ) {
						$hiddenInput = $( '<input type="hidden" name="orderby">' );
						$hiddenInput.val( sortOrder.join( "," ) );
						$submissionForm.append( $hiddenInput );
					}

					$submissionForm.submit();

					return true;
				};
				saveExport = function(){
					var $configForm      = $( configIframe.document ).find( ".export-config-form" )
					  , $submissionForm  = $( ".object-listing-table-save-export-form", $uberContainer )
					  , sortColumns      = dtSettings.aaSorting
					  , allColumns       = dtSettings.aoColumns
					  , config           = $configForm.serializeObject()
					  , sortOrder        = []
					  , favourites, key, $hiddenInput, i, $searchContainer;

					if ( allowFilter ) {
						config.filterExpressions = $filterDiv.find( "[name=filter]" ).val();

						favourites = getFavourites();
						if ( favourites && favourites.length ) {
							config.savedFilters = favourites;
						} else {
							config.savedFilters = $filterDiv.find( "[name=filters]" ).val();
						}
					}

					if ( allowSearch ) {
						$searchContainer = $( dtSettings.aanFeatures.f[0] );
						config.searchQuery = $searchContainer.find( "input.data-table-search" ).val();
					}

					for( key in config ) {
						$hiddenInput = $submissionForm.find( "[name=" + key + "]" );

						if ( !$hiddenInput.length ) {
							$hiddenInput = $( '<input type="hidden" name="' + key + '">' );
							$submissionForm.append( $hiddenInput );
						}

						$hiddenInput.val( config[ key ] );
					}

					for( i=0; i<sortColumns.length; i++ ) {
						sortOrder.push( allColumns[ sortColumns[ i ][ 0 ] ].mData + " " + sortColumns[ i ][ 1 ] );
					}
					if ( sortOrder.length ) {
						$hiddenInput = $( '<input type="hidden" name="orderby">' );
						$hiddenInput.val( sortOrder.join( "," ) );
						$submissionForm.append( $hiddenInput );
					}

					$submissionForm.submit();

					return true;
				}

				exportConfigModal = new PresideIframeModal( iframeSrc, "100%", "100%", callbacks, modalOptions );

				$( ".object-listing-data-export-button", $uberContainer ).on( "click", function(e ){
					e.preventDefault();

					exportConfigModal.open();
				} );

				$dataExportContainer.remove();
			};

			refreshFavourites = function( callback ){
				$.ajax({
					  url     : favouritesUrl
					, cache   : false
					, success : function( resp ) {
						$favouritesDiv.fadeOut( 200, function(){
							$favouritesDiv.html( resp );

							if ( callback !== null ) {
								callback.call();
							}

							$favouritesDiv.fadeIn( 200 );

						} )
					  }
				});
			};

			getFavourites = function() {
				if ( $favouritesDiv.length ) {
					var favourites = [];

					$favouritesDiv.find( ".filter.active" ).each( function(){
						favourites.push( $( this ).data( "filterId" ) );
					} );

					return favourites.join( "," );
				}

				return "";
			};

			setFavourites = function( ids ) {
				var i;

				if ( $favouritesDiv.length ) {
					ids = ids.split( "," );
					$favouritesDiv.find( ".filter" ).removeClass( "active" );

					for( i=0; i<ids.length; i++ ) {
						$favouritesDiv.find( ".filter[ data-filter-id='" + ids[i] + "' ]" ).addClass( "active" );
					}

					$favouritesDiv.find( ".data-table-favourite-group" ).each( function(){
						updateFilterFolderCount( $( this ) );
					} );
				}
			};

			prePopulateFilter = function( filter ) {
				if ( filter && filter.length ) {
					hasPreFilters = true;
					$( document ).on( "conditionBuilderInitialized", function(){
						filtersPopulated = true;
						$filterDiv.find( "[name=filter]" ).data( "conditionBuilder" ).load( filter );
					} );
					toggleAdvancedFilter();
				} else {
					filtersPopulated = true;
					hasPreFilters = false;
				}
			}

			toggleAdvancedFilter = function( e ){
				e && e.preventDefault();

				if ( allowUseFilter ) {
					$filterDiv.toggleClass( "hide" );
					$filterLink.find( "i.fa" ).toggleClass( "fa-caret-right" ).toggleClass( "fa-caret-down" );
				}
			};

			setupQuickSaveFilterIframeModal = function( $filterDiv ) {
				$filterDiv.on( "click", ".save-filter-btn", function( e ){
					e.preventDefault();

					var iframemodal, rawIframe, dummyPresideObjectPicker
					  , iframeSrc           = $( this ).data( "saveFormEndpoint" ) + encodeURIComponent( $filterDiv.find( "[name=filter]" ).val() )
					  , modalTitle          = i18n.translateResource( "cms:rulesEngine.save.filter.modal" )
					  , modalOptions        = {
							title     : modalTitle,
							className : $( this ).data( "modalDialogFull" ) ? "full-screen-dialog" : "filter-quick-save-modal",
							buttons   : {
								cancel : {
									  label     : '<i class="fa fa-reply"></i> ' + i18n.translateResource( "cms:cancel.btn" )
									, className : "btn-default"
								},
								add : {
									  label     : '<i class="fa fa-plus"></i> ' + i18n.translateResource( "cms:save.btn" )
									, className : "btn-primary"
									, callback  : function(){
										if ( typeof rawIframe.quickAdd !== "undefined" ) {
											rawIframe.quickAdd.submitForm();

											return false;
										}
										return true;
									 }
								}
							}
						}
					  , callbacks = {
							onLoad : function( iframe ) {
								iframe.presideObjectPicker = dummyPresideObjectPicker;
								rawIframe = iframe;
							},
							onShow : function( modal, iframe ){
								if ( typeof iframe !== "undefined" && typeof iframe.quickAdd !== "undefined" ) {
									iframe.quickAdd.focusForm();

									return false;
								}

								modal.on('hidden.bs.modal', function (e) {
									modal.remove();
								} );
							}
						};

					dummyPresideObjectPicker = {
						  addRecordToControl  : function( recordId ){
							$filterDiv.find( "[name=filter]" ).data( "conditionBuilder" ).clear();

							refreshFavourites( function(){
								var $fav = $favouritesDiv.find( '[data-filter-id="' + recordId + '"]' );
								if ( $fav.length ) {
									$fav.addClass( "active" );
									if ( $fav.parents( ".data-table-favourite-group" ).length ) {
										updateFilterFolderCount( $fav.closest( ".data-table-favourite-group" ) );
									}
								}

								toggleAdvancedFilter();
								datatable.fnDraw();
							} );
						  }
						, closeQuickAddDialog : function(){
							iframemodal.close();
							$.gritter.add({
								  title      : i18n.translateResource( "cms:info.notification.title" )
								, text       : i18n.translateResource( "cms:rulesEngine.save.filter.confirmation.message" )
								, class_name : 'gritter-success'
								, sticky     : false
							});
						  }
					};

					iframemodal = new PresideIframeModal( iframeSrc, "100%", "100%", callbacks, modalOptions );
					iframemodal.open();
				} );
			};

			setupDatatable();
			setupTableRowFocusBehaviour();

			if ( useMultiActions ) {
				setupCheckboxBehaviour();
				setupMultiActionButtons();
			}
		} );
	};

	$( '.object-listing-table' ).dataListingTable();

} )( presideJQuery );