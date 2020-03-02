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
			  , setupDataExport
			  , setupQuickSaveFilterIframeModal
			  , prePopulateFilter
			  , showFilters
			  , showSimpleSearch
			  , dtSettings
			  , getFavourites
			  , setFavourites
			  , object              = tableSettings.objectName      || cfrequest.objectName     || ""
			  , datasourceUrl       = tableSettings.datasourceUrl   || cfrequest.datasourceUrl  || buildAjaxLink( "dataManager.getObjectRecordsForAjaxDataTables", { id : object } )
			  , isMultilingual      = tableSettings.isMultilingual  || cfrequest.isMultilingual || false
			  , draftsEnabled       = tableSettings.draftsEnabled   || cfrequest.draftsEnabled  || false
			  , object              = tableSettings.objectName      || cfrequest.objectName     || ""
			  , objectTitle         = tableSettings.objectTitle     || cfrequest.objectTitle    || i18n.translateResource( "preside-objects." + object + ":title" )
			  , allowSearch         = tableSettings.allowSearch     || cfrequest.allowSearch
			  , allowFilter         = tableSettings.allowFilter     || cfrequest.allowFilter
			  , allowDataExport     = tableSettings.allowDataExport || cfrequest.allowDataExport
			  , noRecordMessage     = tableSettings.noRecordMessage || i18n.translateResource( "cms:datatables.emptyTable" )
			  , favouritesUrl       = tableSettings.favouritesUrl   || cfrequest.favouritesUrl || buildAjaxLink( "rulesEngine.ajaxDataGridFavourites", { objectName : object } )
			  , compact             = tableSettings.compact         || cfrequest.compact
			  , clickableRows       = typeof tableSettings.clickableRows   === "undefined" ? ( typeof cfrequest.clickableRows   === "undefined" ? true : cfrequest.clickableRows   ) : tableSettings.clickableRows
			  , noActions           = typeof tableSettings.noActions       === "undefined" ? ( typeof cfrequest.noActions       === "undefined" ? false: cfrequest.noActions       ) : tableSettings.noActions
			  , useMultiActions     = typeof tableSettings.useMultiActions === "undefined" ? ( typeof cfrequest.useMultiActions === "undefined" ? true : cfrequest.useMultiActions ) : tableSettings.useMultiActions
			  , $filterDiv          = $( '#' + tableId + '-filter' )
			  , $favouritesDiv      = $( '#' + tableId + '-favourites' )
			  , enabledContextHotkeys, refreshFavourites
			  , lastAjaxResult;

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
						sWidth    : "12em"
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
					sDom = "<'well'fr<'clearfix'>><'dataTables_pagination top clearfix'<'pull-left'i><'pull-left'l><'pull-right'p>><'datatable-container't><'dataTables_pagination bottom'<'pull-left'i><'pull-left'l><'pull-right'p>><'clearfix'>";
				} else if ( compact ) {
					sDom = "frt<'dataTables_pagination bottom'<'pull-left'i><'pull-left'l><'pull-right'p><'clearfix'>";
				} else {
					sDom = "fr<'dataTables_pagination top'<'pull-left'i><'pull-left'l><'pull-right'p>>t<'dataTables_pagination bottom'<'pull-left'i><'pull-left'l><'pull-right'p><'clearfix'>";
				}

				datatable = $listingTable.dataTable( {
					aoColumns     : colConfig,
					aaSorting     : defaultSort,
					bServerSide   : true,
					bProcessing   : true,
					bStateSave    : true,
					bFilter       : allowSearch,
					iDeferLoading : 0,
					bAutoWidth    : false,
					aLengthMenu   : [ 5, 10, 25, 50, 100 ],
					sDom          : sDom,
					sAjaxSource   : datasourceUrl,
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

						this.fnDraw();
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
					fnDrawCallback : function() {
						$( ".datatable-container" ).presideLoadingSheen( false );
					},
					fnFooterCallback: function ( nRow, aaData, iStart, iEnd, aiDisplay ) {
						if ( $( nRow ).length ) {
							if ( lastAjaxResult && typeof lastAjaxResult.sFooter !== "undefined" && lastAjaxResult.sFooter.length ) {
								$( nRow ).show().find( "th:first" ).html( lastAjaxResult.sFooter );
							} else {
								$( nRow ).hide().find( "th:first" ).html( "" );
							}
						}
					}
				} ).fnSetFilteringDelay( searchDelay );

				$listingTable.on( "xhr", function( event, settings, json ){
					lastAjaxResult = json;
				} );
			};

			setupCheckboxBehaviour = function(){
				var $selectAllCBox   = $listingTable.find( "th input:checkbox" )
				  , $multiActionBtns = $listingTable.closest( '.multi-action-form' ).find( ".multi-action-buttons" );

				$selectAllCBox.on( 'click' , function(){
					var $allCBoxes = $listingTable.find( 'tr > td:first-child input:checkbox' );

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
				$listingTable.on( "click", "th input:checkbox,tbody tr > td:first-child input:checkbox", function( e ){
					var anyBoxesTicked = $listingTable.find( 'tr > td:first-child input:checkbox:checked' ).length;

					if ( anyBoxesTicked == $listingTable.find( "td input:checkbox" ).length ) {
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
				var $form              = $listingTable.closest( '.multi-action-form' )
				  , $hiddenActionField = $form.find( '[name=multiAction]' );

				$form.find( ".multi-action-buttons button" ).click( function( e ){
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
				$listingTable.on( 'click', 'tbody :checkbox', function(){
					var $cbox = $( this );
					$cbox.closest( 'tr' ).toggleClass( 'selected', $cbox.is( ':checked' ) );
				} );
			};

			setupFilters = function( settings ){
				// setup DOM
				var $searchContainer = $( settings.aanFeatures.f[0] )
				  , $searchTitle     = $( '<h4 class="blue">' + i18n.translateResource( "cms:datatables.simple.search.title" ) + '</h4>' )
				  , $filterLink      = $( '<a href="#" class="pull-right"><i class="fa fa-fw fa-filter"></i> ' + i18n.translateResource( "cms:datatables.show.advanced.filters" ) + '</a>' );

				$searchContainer.prepend( $searchTitle );
				$searchContainer.prepend( $filterLink );
				if ( $favouritesDiv.length ) {
					$searchContainer.append( $favouritesDiv );
					$favouritesDiv.removeClass( "hide" );
					$favouritesDiv.on( "click", ".filter", function( e ){
						e.preventDefault();
						var $filter = $( this )
						  , $otherFilters = $filter.siblings( ".filter" );

						$filter.toggleClass( "active" ).find( ":focus" ).blur();

						datatable.fnDraw();
					} );
				}
				$searchContainer.parent().append( $filterDiv );

				$filterDiv.hide().removeClass( "hide" ).find( ".well" ).removeClass( "well" );

				// toggles between filter mode + basic search mode
				$filterLink.on( "click", showFilters );
				$filterDiv.on( "click", ".back-to-basic-search", showSimpleSearch );

				// toggle for showing / hiding filter builder
				$filterDiv.on( "click", ".quick-filter-toggler", function( e ){
					e.preventDefault();
					$( this ).find( ".fa:first" ).toggleClass( "fa-caret-right fa-caret-down" );
				} );

				// filter change listener
				$filterDiv.on( "change", function( e ){
					datatable.fnDraw();

					$filterDiv.find( ".save-filter-btn" ).prop( "disabled", !$filterDiv.find( "[name=filter]" ).val().length );
				} );

				setupQuickSaveFilterIframeModal( $filterDiv );

				if ( settings.oLoadedState !== null && typeof settings.oLoadedState.oFilter !== "undefined" ) {
					if ( settings.oLoadedState.oFilter.filters.length || settings.oLoadedState.oFilter.filter.length ) {
						prePopulateFilter( settings.oLoadedState.oFilter.filters, settings.oLoadedState.oFilter.filter );
					} else if ( settings.oLoadedState.oFilter.favourites && settings.oLoadedState.oFilter.favourites.length ) {
						setFavourites( settings.oLoadedState.oFilter.favourites );
					}
				}
			};

			setupDataExport = function( settings ){
				// setup DOM
				var paginationContainers = settings.aanFeatures.p
				  , $dataExportContainer = $( ".object-listing-table-export" )
				  , $configForm          = $( ".object-listing-data-export-config-form" )
				  , $exportBtn           = $( ".object-listing-data-export-button" )
				  , iframeSrc            = $exportBtn.attr( "href" )
				  , i, $container, modalOptions, callbacks, processExport, exportConfigModal, configIframe;

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
							  label     : '<i class="fa fa-download"></i> ' + i18n.translateResource( "cms:export.btn" )
							, className : "btn-primary ok-button"
							, callback  : function(){ return processExport(); }
						}
					}
				}
				callbacks = {
					onLoad : function( iframe ) {
						configIframe = iframe;
					}
				};
				processExport = function(){
					var $configForm      = $( configIframe.document ).find( ".export-config-form" )
					  , $submissionForm  = $( ".object-listing-table-export-form" )
					  , $searchContainer = $( dtSettings.aanFeatures.f[0] )
					  , sortColumns      = dtSettings.aaSorting
					  , allColumns       = dtSettings.aoColumns
					  , config           = $configForm.serializeObject()
					  , sortOrder        = []
					  , favourites, key, $hiddenInput, i;

					if ( allowFilter ) {
						config.filterExpressions = $filterDiv.find( "[name=filter]" ).val();

						favourites = getFavourites();
						if ( favourites && favourites.length ) {
							config.savedFilters = favourites;
						} else {
							config.savedFilters = $filterDiv.find( "[name=filters]" ).val();
						}
					}

					config.searchQuery = $searchContainer.find( "input.data-table-search" ).val();

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

				exportConfigModal = new PresideIframeModal( iframeSrc, "100%", "100%", callbacks, modalOptions );

				$( ".object-listing-data-export-button" ).on( "click", function(e ){
					e.preventDefault();

					exportConfigModal.open();
				} );

				$dataExportContainer.remove();
			};

			refreshFavourites = function(){
				$.ajax({
					  url     : favouritesUrl
					, cache   : false
					, success : function( resp ) {
						$favouritesDiv.fadeOut( 200, function(){
							$favouritesDiv.html( resp ).fadeIn( 200 );
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
				}
			};

			prePopulateFilter = function( filters, filter ) {
				var loaded = false;

				if ( filters && filters.length ) {
					var filterArray   = filters.split(",")
					  , filtersSelect = $filterDiv.find( "[name=filters]" ).data( "uberSelect")
					  , i;

					for( i=0; i<filterArray.length; i++ ) {
						if ( filterArray[i].length ) {
							filtersSelect.select( filterArray[i] )
						}
					}

					showFilters();
				}

				if ( filter && filter.length ) {
					$( document ).on( "conditionBuilderInitialized", function(){
						$filterDiv.find( "[name=filter]" ).data( "conditionBuilder" ).load( filter );
					} );
					showFilters();
				}
			}

			showFilters = function( e ){
				e && e.preventDefault();
				var $searchContainer = $( dtSettings.aanFeatures.f[0] );
				$searchContainer.fadeOut( 100, function(){
					$searchContainer.find( "input.data-table-search" ).val( "" );
					setFavourites( "" );
					datatable.fnFilter("");
					$filterDiv.fadeIn( 100 );
				} );
			};

			showSimpleSearch = function( e ){
				e && e.preventDefault();
				var $searchContainer = $( dtSettings.aanFeatures.f[0] );

				$filterDiv.fadeOut( 100, function(){
					$filterDiv.find( "[name=filter]" ).data( "conditionBuilder" ).clear();
					$filterDiv.find( "[name=filters]" ).data( "uberSelect").clear();
					$filterDiv.find( "[name=filters]" ).val("");
					refreshFavourites();
					datatable.fnDraw();
					$searchContainer.fadeIn( 100 );
				} );
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
							$filterDiv.find( "[name=filters]" ).data( "uberSelect").select( recordId );
							$filterDiv.find( ".quick-filter-toggler" ).click();
							datatable.fnDraw();
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