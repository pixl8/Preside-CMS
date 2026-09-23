/**
 * Object listing table: DataTables 3 + ColumnControl header filters/colVis,
 * Everything bar for search / saved / segmentation filters.
 * Public plugin remains $.fn.dataListingTable on .object-listing-table.
 */
( function( $ ){

	window.PresideDatatables = window.PresideDatatables || {};

	if ( typeof PresideDatatables.encodeListingUrlState !== "function" ) {
		PresideDatatables.listingUrlParam = PresideDatatables.listingUrlParam || "lst";

		PresideDatatables._listingUrlIdHash = PresideDatatables._listingUrlIdHash || function( tableId ) {
			var str = String( tableId || "" )
			  , h   = 2166136261
			  , i, hex;

			for( i=0; i<str.length; i++ ) {
				h ^= str.charCodeAt( i );
				h = Math.imul( h, 16777619 );
			}

			hex = ( h >>> 0 ).toString( 16 );
			while ( hex.length < 8 ) {
				hex = "0" + hex;
			}

			return hex;
		};

		PresideDatatables.listingUrlParamFor = PresideDatatables.listingUrlParamFor || function( tableId ) {
			return PresideDatatables.listingUrlParam + PresideDatatables._listingUrlIdHash( tableId );
		};

		PresideDatatables._utf8ToBase64Url = function( str ) {
			var b64 = btoa( encodeURIComponent( str ).replace( /%([0-9A-F]{2})/g, function( match, hex ) {
				return String.fromCharCode( parseInt( hex, 16 ) );
			} ) );

			return b64.replace( /\+/g, "-" ).replace( /\//g, "_" ).replace( /=+$/g, "" );
		};

		PresideDatatables._base64UrlToUtf8 = function( encoded ) {
			var b64 = String( encoded || "" ).replace( /-/g, "+" ).replace( /_/g, "/" );

			while ( b64.length % 4 ) {
				b64 += "=";
			}

			return decodeURIComponent( Array.prototype.map.call( atob( b64 ), function( ch ) {
				return "%" + ( "00" + ch.charCodeAt( 0 ).toString( 16 ) ).slice( -2 );
			} ).join( "" ) );
		};

		PresideDatatables.compactListingUrlState = function( state ) {
			var compact = {};

			state = state || {};
			if ( state.q ) { compact.q = state.q; }
			if ( state.f && state.f.length ) { compact.f = state.f; }
			if ( state.a && state.a.length ) { compact.a = state.a; }
			if ( state.x && state.x.length ) { compact.x = state.x; }
			if ( state.c && typeof state.c === "object" && Object.keys( state.c ).length ) { compact.c = state.c; }
			if ( state.o && state.o.length ) { compact.o = state.o; }

			return compact;
		};

		PresideDatatables.encodeListingUrlState = function( state ) {
			var compact = PresideDatatables.compactListingUrlState( state );

			if ( !Object.keys( compact ).length ) {
				return "";
			}

			try {
				return PresideDatatables._utf8ToBase64Url( JSON.stringify( compact ) );
			} catch ( e ) {
				return "";
			}
		};

		PresideDatatables.decodeListingUrlState = function( encoded ) {
			var raw;

			if ( !encoded ) {
				return null;
			}

			try {
				raw = JSON.parse( PresideDatatables._base64UrlToUtf8( encoded ) );
			} catch ( e ) {
				return null;
			}

			if ( !raw || typeof raw !== "object" ) {
				return null;
			}

			return {
				  q : raw.q || ""
				, f : $.isArray( raw.f ) ? raw.f : []
				, a : $.isArray( raw.a ) ? raw.a : []
				, x : $.isArray( raw.x ) ? raw.x : []
				, c : raw.c && typeof raw.c === "object" && !$.isArray( raw.c ) ? raw.c : {}
				, o : $.isArray( raw.o ) ? raw.o : []
			};
		};

		PresideDatatables.readListingUrlState = function( tableId ) {
			try {
				return PresideDatatables.decodeListingUrlState(
					new URLSearchParams( window.location.search ).get( PresideDatatables.listingUrlParamFor( tableId ) )
				);
			} catch ( e ) {
				return null;
			}
		};

		PresideDatatables.writeListingUrlState = function( encoded, mode, tableId ) {
			var url, key;

			try {
				url = new URL( window.location.href );
			} catch ( e ) {
				return;
			}

			key = PresideDatatables.listingUrlParamFor( tableId );
			if ( encoded ) {
				url.searchParams.set( key, encoded );
			} else {
				url.searchParams.delete( key );
			}

			if ( mode === "replace" ) {
				history.replaceState( history.state, document.title, url );
			} else {
				history.pushState( history.state, document.title, url );
			}
		};
	}

	if ( window.DataTable && window.DataTable.ColumnControl && window.DataTable.ColumnControl.icons ) {
		window.DataTable.ColumnControl.icons.filter = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/></svg>';
		window.DataTable.ColumnControl.icons.filterActive = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/></svg>';
	}

	$.fn.dataListingTable = function(){
		return this.each( function(){
			var $listingTable  = $( this )
			  , tableSettings  = $listingTable.data()
			  , tableId        = $listingTable.attr( "id" )
			  , $container     = $( "#" + tableId + "-container" )
			  , $toolbar       = $( "#" + tableId + "-toolbar" )
			  , datatable
			  , dtApi
			  , searchDelay    = 400
			  , searchTimer
			  , object                   = tableSettings.objectName               || cfrequest.objectName     || ""
			  , datasourceUrl            = tableSettings.datasourceUrl            || cfrequest.datasourceUrl  || buildAjaxLink( "dataManager.getObjectRecordsForAjaxDataTables", { id : object } )
			  , isMultilingual           = tableSettings.isMultilingual           || cfrequest.isMultilingual || false
			  , draftsEnabled            = tableSettings.draftsEnabled            || cfrequest.draftsEnabled  || false
			  , objectTitle              = tableSettings.objectTitle              || cfrequest.objectTitle    || i18n.translateResource( "preside-objects." + object + ":title" )
			  , allowSearch              = tableSettings.allowSearch              || cfrequest.allowSearch
			  , allowFilter              = tableSettings.allowFilter              || cfrequest.allowFilter
			  , allowDataExport          = tableSettings.allowDataExport          || cfrequest.allowDataExport
			  , allowSaveExport          = tableSettings.allowSaveExport          || cfrequest.allowSaveExport
			  , allowColumnPicker        = !( tableSettings.allowColumnPicker === false || tableSettings.allowColumnPicker === "false" )
			  , allowColumnFilter        = !( tableSettings.allowColumnFilter === false || tableSettings.allowColumnFilter === "false" )
			  , allowSavedViews          = tableSettings.allowSavedViews === true || tableSettings.allowSavedViews === "true"
			  , listingKey               = tableSettings.listingKey               || object
			  , listingContextKey        = tableSettings.listingContextKey        || ""
			  , listingContextLabel      = tableSettings.listingContextLabel      || ""
			  , namedListingContext      = tableSettings.namedListingContext === true || tableSettings.namedListingContext === "true"
			  , saveListingColumnsUrl    = tableSettings.saveListingColumnsUrl    || ""
			  , saveListingViewUrl       = tableSettings.saveListingViewUrl       || ""
			  , updateListingViewUrl     = tableSettings.updateListingViewUrl     || ""
			  , deleteListingViewUrl     = tableSettings.deleteListingViewUrl     || ""
			  , saveListingViewFormUrl   = tableSettings.saveListingViewFormUrl   || ""
			  , saveListingViewDefaultUrl = tableSettings.saveListingViewDefaultUrl || ""
			  , clearListingViewDefaultUrl = tableSettings.clearListingViewDefaultUrl || ""
			  , saveListingViewDefaultFormUrl = tableSettings.saveListingViewDefaultFormUrl || ""
			  , hiddenGridFields         = tableSettings.hiddenGridFields         ? String( tableSettings.hiddenGridFields ).split( "," ).filter( Boolean ) : []
			  , noRecordMessage          = tableSettings.noRecordMessage          || i18n.translateResource( "cms:datatables.emptyTable" )
			  , noRecordTableHide        = tableSettings.noRecordTableHide        || false
			  , noRecordTableHideMessage = tableSettings.noRecordTableHideMessage || i18n.translateResource( "cms:preside-objects.default.field.no_value.title" )
			  , compact                  = tableSettings.compact                  || cfrequest.compact
			  , defaultPageLength        = cfrequest.defaultPageLength            || 10
			  , paginationOptions        = cfrequest.paginationOptions            || [ 5, 10, 25, 50, 100 ]
			  , clickableRows            = typeof tableSettings.clickableRows   === "undefined" ? ( typeof cfrequest.clickableRows   === "undefined" ? true : cfrequest.clickableRows   ) : tableSettings.clickableRows
			  , noActions                = typeof tableSettings.noActions       === "undefined" ? ( typeof cfrequest.noActions       === "undefined" ? false: cfrequest.noActions       ) : tableSettings.noActions
			  , useMultiActions          = typeof tableSettings.useMultiActions === "undefined" ? ( typeof cfrequest.useMultiActions === "undefined" ? true : cfrequest.useMultiActions ) : tableSettings.useMultiActions
			  , $filterDiv               = $( "#" + tableId + "-filter" )
			  , $favouritesDiv           = $( "#" + tableId + "-favourites" )
			  , UNKNOWN_TOTAL            = 1000000001
			  , lastAjaxResult
			  , everythingBar
			  , lastDtRequest
			  , lastColumnSearch = {}
			  , lastFetchedGridFields = []
			  , columnUiReady = false
			  , saveColumnsTimer
			  , reloadListingDataTimer
			  , toolbarConfig = {}
			  , listingViews
			  , filtersPopulated = false
			  , hasPreFilters    = false
			  , hasFilterVal     = $filterDiv.find( "[name=filter]" ).length > 0 && $filterDiv.find( "[name=filter]" ).val().length > 0
			  , listingUrlPending = ( typeof PresideDatatables.readListingUrlState === "function" ) ? PresideDatatables.readListingUrlState( tableId ) : null
			  , listingUrlReady = false
			  , listingUrlApplying = false
			  , listingUrlLast = ""
			  , listingUrlBaseline = null
			  , listingDefaultSortFields = []
			  , setupDatatable, setupCheckboxBehaviour, setupMultiActionButtons, setupTableRowFocusBehaviour
			  , setupFilters, setupDataExport, setupQuickSaveFilterIframeModal, setupEverythingBar, setupHeaderColumnUi
			  , registerListingColumnControlPlugins, searchContentForField, headingContent, expressionsFromColumnControl
			  , columnSearchToExpressions, columnFilterChipsFromRequest, columnFilterChipsFromStored, columnFilterChipLabel, columnFilterListValueLabel
			  , columnFilterOperatorLabel, columnFilterChipText, syncColumnFilterChips, clearColumnFilter
			  , pickerSelection, pickerHasValue
			  , getVisibleGridFields, saveVisibleColumns, applyDefaultColumnVisibility, applyColumnLayout
			  , listingFieldWasFetched, scheduleListingDataReload, appendListingGrantParams
			  , captureColumnSearch, getListingViewSnapshot, applyListingViewSnapshot, applyListingDefaultView
			  , applyColumnSearch, setAdvancedFilter, normalizeFilterState, normalizeColumnSearchMap
			  , expressionsFromStoredColumnSearch, columnControlStateFromSearch, syncViewFilterLock
			  , setupListingViews, andExpressionArrays, listingPreferencePayload, persistActiveView, persistListingTableState
			  , stripListingTableColumnControlState, getListingUrlState, encodeCurrentListingUrl, pushListingUrl
			  , applyListingUrlState, setupListingUrlSync, getListingSortState, setListingSortState
			  , listingColumnIndexForField, listingSortMatchesDefault, persistListingFilterState, loadListingFilterState
			  , syncListingSortBadges
			  , prePopulateFilter, toggleAdvancedFilter, syncAdvancedFilterToggle, getFavourites, getMergedFilterExpression
			  , enabledContextHotkeys, refreshFavourites, updateSelectAllOptionRecordCount
			  , activateSelectAllOption, deactivateSelectAllOption, redrawTable, getSearchQuery
			  , applyListingFooter, listingFooterIsMapped, listingFooterRows, listingFooterCell
			  , listingFooterColumnField, listingFooterValue, renderMappedListingFooter
			  , allowUseFilter=false, allowManageFilter=false, manageFiltersLink="";

			if ( $toolbar.length ) {
				try {
					toolbarConfig = JSON.parse( $toolbar.find( ".listing-toolbar-data" ).text() || "{}" );
				} catch( e ) {
					toolbarConfig = {};
				}
			}

			if ( allowFilter ) {
				if ( $filterDiv.length ) {
					var filterSettings = $filterDiv.data();
					allowUseFilter    = filterSettings.allowUseFilter    || false;
					allowManageFilter = filterSettings.allowManageFilter || false;
					if ( allowManageFilter ) {
						manageFiltersLink = filterSettings.manageFiltersLink || "";
					}
				}
			}

			getSearchQuery = function() {
				if ( everythingBar ) {
					return everythingBar.searchQuery || "";
				}
				return $toolbar.find( ".everything-bar-input" ).val() || "";
			};

			applyListingFooter = function() {
				var json = lastAjaxResult
				  , footer
				  , $tfoot = $listingTable.children( "tfoot" )
				  , wrapWithRow = !( tableSettings.footerWrapWithRow === false || tableSettings.footerWrapWithRow === "false" )
				  , $row;

				if ( dtApi && ( !json || typeof json.sFooter === "undefined" ) && dtApi.ajax ) {
					json = dtApi.ajax.json() || json;
				}

				if ( !json || typeof json.sFooter === "undefined" ) {
					return;
				}

				footer = json.sFooter;

				if ( listingFooterIsMapped( footer ) ) {
					if ( !$tfoot.length ) {
						$tfoot = $( "<tfoot class=\"listing-mapped-footer\"></tfoot>" );
						$listingTable.append( $tfoot );
					}
					$tfoot.addClass( "listing-mapped-footer" );
					renderMappedListingFooter( $tfoot, footer );
					return;
				}

				if ( !$tfoot.length ) {
					if ( !footer || !String( footer ).length ) {
						return;
					}
					$tfoot = $( wrapWithRow ? "<tfoot><tr><th></th></tr></tfoot>" : "<tfoot class=\"multi-column-footer\"></tfoot>" );
					$listingTable.append( $tfoot );
				}

				if ( $tfoot.hasClass( "multi-column-footer" ) ) {
					if ( footer && String( footer ).length ) {
						$tfoot.html( footer );
					} else {
						$tfoot.empty();
					}
				} else {
					$row = $tfoot.children( "tr" ).first();
					if ( !$row.length ) {
						$row = $( "<tr><th></th></tr>" ).appendTo( $tfoot );
					}
					if ( footer && String( footer ).length ) {
						$row.show().children( "th:first, td:first" ).html( footer );
					} else {
						$row.hide().children( "th:first, td:first" ).html( "" );
					}
				}
			};

			listingFooterIsMapped = function( footer ) {
				return !!( footer && typeof footer === "object" );
			};

			listingFooterValue = function( obj, name ) {
				var key, lower;
				if ( !obj || !name ) {
					return;
				}
				if ( Object.prototype.hasOwnProperty.call( obj, name ) ) {
					return obj[ name ];
				}
				lower = String( name ).toLowerCase();
				for( key in obj ) {
					if ( String( key ).toLowerCase() === lower ) {
						return obj[ key ];
					}
				}
			};

			listingFooterRows = function( footer ) {
				var rows, cells, label;
				if ( $.isArray( footer ) ) {
					return footer;
				}
				rows = listingFooterValue( footer, "rows" );
				if ( rows && rows.length ) {
					return rows;
				}
				cells = listingFooterValue( footer, "cells" );
				if ( cells ) {
					label = listingFooterValue( footer, "label" ) || "";
					return [ { label : label, cells : cells, labelField : listingFooterValue( footer, "labelField" ) } ];
				}
				return [];
			};

			listingFooterColumnField = function( column ) {
				var src, $th;
				if ( !column ) {
					return "";
				}
				src = column.dataSrc();
				if ( typeof src === "string" && src.length ) {
					return src;
				}
				$th = $( column.header() );
				return $th.data( "field" ) || "";
			};

			listingFooterCell = function( cells, field ) {
				var value, stripped;
				if ( !cells || !field ) {
					return;
				}
				value = listingFooterValue( cells, field );
				if ( typeof value === "undefined" ) {
					value = listingFooterValue( cells, field + "_value" );
				}
				if ( typeof value === "undefined" && /_value$/i.test( field ) ) {
					stripped = field.replace( /_value$/i, "" );
					value = listingFooterValue( cells, stripped );
				}
				if ( typeof value === "undefined" || value === null ) {
					return;
				}
				if ( typeof value === "object" ) {
					return {
						  html      : listingFooterValue( value, "html" ) || listingFooterValue( value, "content" ) || ""
						, className : listingFooterValue( value, "className" ) || listingFooterValue( value, "class" ) || ""
					};
				}
				return { html : String( value ), className : "" };
			};

			renderMappedListingFooter = function( $tfoot, footer ) {
				var rows = listingFooterRows( footer )
				  , defaultLabelField = ( footer && !$.isArray( footer ) ) ? ( listingFooterValue( footer, "labelField" ) || "" ) : ""
				  , reserved = { _checkbox : true, _options : true, _status : true, _translateStatus : true }
				  , $headers = $listingTable.children( "thead" ).find( "> tr:first > th" )
				  , allRowsHtml = []
				  , r, row, labelField, labelFieldVisible, labelPlaced, hasContent, cellsHtml;

				if ( !dtApi || !rows.length ) {
					$tfoot.empty();
					return;
				}

				for( r=0; r<rows.length; r++ ) {
					row = rows[ r ] || {};
					labelField = listingFooterValue( row, "labelField" ) || defaultLabelField;
					labelFieldVisible = false;
					labelPlaced = false;
					hasContent = false;
					cellsHtml = [];

					if ( labelField ) {
						$headers.each( function() {
							var column = dtApi.column( this );
							if ( column.visible() && listingFooterColumnField( column ) === labelField ) {
								labelFieldVisible = true;
							}
						} );
						if ( !labelFieldVisible ) {
							labelField = "";
						}
					}

					$headers.each( function() {
						var column = dtApi.column( this )
						  , field = listingFooterColumnField( column )
						  , $th = $( this )
						  , cell = listingFooterCell( listingFooterValue( row, "cells" ) || {}, field )
						  , className = []
						  , isDataCol = field && !reserved[ field ]
						  , cellHtml = "";

						if ( !column.visible() ) {
							return;
						}

						if ( $th.hasClass( "dt-align-right" ) || $th.hasClass( "text-right" ) ) {
							className.push( "text-right" );
						} else if ( $th.hasClass( "dt-align-center" ) || $th.hasClass( "center" ) ) {
							className.push( "center" );
						}

						if ( cell ) {
							cellHtml = cell.html || "";
							if ( cell.className ) {
								className.push( cell.className );
							}
						} else if ( !labelPlaced && ( ( labelField && field === labelField ) || ( !labelField && isDataCol ) ) ) {
							cellHtml = listingFooterValue( row, "label" ) || "";
							labelPlaced = true;
						}

						if ( cellHtml.length ) {
							hasContent = true;
						}

						cellsHtml.push( "<th" + ( className.length ? " class=\"" + className.join( " " ) + "\"" : "" ) + ">" + cellHtml + "</th>" );
					} );

					if ( hasContent ) {
						allRowsHtml.push( "<tr>" + cellsHtml.join( "" ) + "</tr>" );
					}
				}

				$tfoot.html( allRowsHtml.join( "" ) );
			};

			getFavourites = function() {
				if ( everythingBar ) {
					return everythingBar.getFavourites();
				}
				return "";
			};

			getMergedFilterExpression = function() {
				var advanced = []
				  , extra    = ( everythingBar && everythingBar.getExtraFilterExpressions ) ? everythingBar.getExtraFilterExpressions() : []
				  , column   = expressionsFromStoredColumnSearch( lastColumnSearch )
				  , raw      = $filterDiv.find( "[name=filter]" ).val()
				  , merged;

				if ( raw && raw.length ) {
					try { advanced = JSON.parse( raw ); } catch( e ) { advanced = []; }
				}
				if ( !$.isArray( advanced ) ) {
					advanced = [];
				}

				merged = andExpressionArrays( advanced, extra );
				merged = andExpressionArrays( merged, column );

				return merged.length ? JSON.stringify( merged ) : "";
			};

			andExpressionArrays = function( left, right ) {
				left  = $.isArray( left ) ? left : [];
				right = $.isArray( right ) ? right : [];

				if ( !left.length ) {
					return right.slice();
				}
				if ( !right.length ) {
					return left.slice();
				}

				return left.concat( [ "and" ], right );
			};

			getVisibleGridFields = function() {
				var fields = [];

				if ( dtApi ) {
					dtApi.columns( ".listing-data-column" ).every( function() {
						if ( this.visible() ) {
							fields.push( this.dataSrc() );
						}
					} );
				}

				if ( fields.length ) {
					return fields;
				}

				return ( toolbarConfig.columns || [] ).filter( function( col ) {
					return col.visible;
				} ).map( function( col ) {
					return col.field;
				} );
			};

			listingFieldWasFetched = function( field ) {
				if ( !field ) {
					return true;
				}
				return lastFetchedGridFields.indexOf( field ) !== -1;
			};

			scheduleListingDataReload = function() {
				clearTimeout( reloadListingDataTimer );
				reloadListingDataTimer = setTimeout( function() {
					if ( dtApi ) {
						dtApi.ajax.reload( null, false );
					}
				}, 300 );
			};

			appendListingGrantParams = function( params ) {
				params.listingKey = listingKey;
				if ( toolbarConfig.grantedColumns && toolbarConfig.grantedColumns.length && toolbarConfig.grantedColumnsSig ) {
					params.grantedGridFields    = toolbarConfig.grantedColumns.join( "," );
					params.grantedGridFieldsSig = toolbarConfig.grantedColumnsSig;
				}
			};

			redrawTable = function() {
				if ( dtApi ) {
					dtApi.draw();
				}
			};

			setupEverythingBar = function() {
				if ( !$toolbar.length || typeof PresideEverythingBar === "undefined" ) {
					return;
				}
				if ( !$toolbar.find( ".everything-bar-input" ).length ) {
					return;
				}

				everythingBar = new PresideEverythingBar( {
					  $toolbar               : $toolbar
					, config                 : toolbarConfig
					, objectName             : object
					, listingKey             : listingKey
					, onChange               : function(){
						if ( listingViews ) {
							listingViews.refreshDirty();
						}
						pushListingUrl();
						redrawTable();
					  }
					, onRemoveColumnFilter   : function( field ){
						clearColumnFilter( field );
						if ( listingViews ) {
							listingViews.refreshDirty();
						}
						pushListingUrl();
						redrawTable();
					  }
					, onApplyView            : function( viewId ){
						if ( !listingViews ) {
							return;
						}
						if ( viewId === "default" ) {
							listingViews.applyDefaultView();
						} else {
							listingViews.applyNamedView( viewId );
						}
					  }
					, getListingFilterState  : function(){
						var advanced = []
						  , raw      = $filterDiv.find( "[name=filter]" ).val();

						if ( raw && raw.length ) {
							try { advanced = JSON.parse( raw ); } catch( e ) { advanced = []; }
						}
						if ( !$.isArray( advanced ) ) {
							advanced = [];
						}

						return {
							  columnSearch   : $.extend( {}, lastColumnSearch )
							, advancedFilter : advanced
						};
					  }
					, onApplyAjaxResult      : function( listingResult ){
						var applied = false
						  , merged;

						listingResult = listingResult || {};

						if ( listingResult.columnSearch && typeof listingResult.columnSearch === "object" && Object.keys( listingResult.columnSearch ).length ) {
							merged = $.extend( true, {}, lastColumnSearch, normalizeColumnSearchMap( listingResult.columnSearch ) );
							applyColumnSearch( merged );
							syncColumnFilterChips();
							applied = true;
						}
						if ( $.isArray( listingResult.advancedFilter ) ) {
							setAdvancedFilter( listingResult.advancedFilter );
							applied = true;
						}
						if ( listingResult.openAdvancedFilter && allowUseFilter ) {
							$filterDiv.removeClass( "hide" );
							syncAdvancedFilterToggle();
							applied = true;
						}

						return applied;
					  }
				} );
				$( document ).trigger( "preside.listing.everythingBar", [ everythingBar ] );
			};

			setupListingViews = function() {
				if ( !allowSavedViews || !$toolbar.find( ".listing-views" ).length || typeof PresideListingViews === "undefined" ) {
					return;
				}

				listingViews = new PresideListingViews( {
					  $toolbar          : $toolbar
					, config            : toolbarConfig
					, objectName        : object
					, listingKey        : listingKey
					, listingContextKey : listingContextKey || toolbarConfig.listingContextKey || ""
					, listingContextLabel : listingContextLabel || toolbarConfig.listingContextLabel || ""
					, namedListingContext : namedListingContext || toolbarConfig.namedListingContext || false
					, urls              : {
						  save         : saveListingViewUrl
						, update       : updateListingViewUrl
						, delete       : deleteListingViewUrl
						, form         : saveListingViewFormUrl
						, saveDefault  : saveListingViewDefaultUrl
						, clearDefault : clearListingViewDefaultUrl
						, defaultForm  : saveListingViewDefaultFormUrl
					  }
					, getSnapshot       : getListingViewSnapshot
					, applySnapshot     : applyListingViewSnapshot
					, applyDefault      : applyListingDefaultView
					, persistActiveView : persistActiveView
					, onLockChange      : syncViewFilterLock
					, defaultSort       : listingDefaultSortFields
				} );
				listingViews.restore();
				syncViewFilterLock();
			};

			registerListingColumnControlPlugins = function() {
				var DT = window.DataTable
				  , resetLabel, columnsTitle, SearchInput, origOptions, origStateLoad;

				if ( !DT || !DT.ColumnControl ) {
					return;
				}

				if ( DT.ColumnControl.SearchInput && !DT.ColumnControl.SearchInput._presideEqualsDefault ) {
					SearchInput   = DT.ColumnControl.SearchInput;
					origOptions   = SearchInput.prototype.options;
					origStateLoad = SearchInput.prototype._stateLoad;

					SearchInput.prototype.options = function( opts ) {
						var list        = opts.slice()
						  , containsIdx = -1
						  , equalIdx    = -1
						  , i;

						for( i=0; i<list.length; i++ ) {
							if ( list[ i ].value === "contains" ) {
								containsIdx = i;
							}
							if ( list[ i ].value === "equal" ) {
								equalIdx = i;
							}
						}
						if ( containsIdx !== -1 && equalIdx > 0 ) {
							list.unshift( list.splice( equalIdx, 1 )[ 0 ] );
						}

						return origOptions.call( this, list );
					};

					SearchInput.prototype._stateLoad = function( state ) {
						var columnName, bucket, loaded, savedUnique, result;

						savedUnique     = this._colUnique;
						this._colUnique = this._idx;

						if ( state && state.columnControl && this._type === "text" ) {
							columnName = this._dt.column( this._idx ).name();
							bucket     = state.columnControl[ columnName ] || state.columnControl[ this._idx ];
							loaded     = bucket && bucket.searchInput;

							if ( loaded && loaded.logic === "contains" && !$.trim( loaded.value || "" ) ) {
								loaded.logic = "equal";
							}
						}

						result = origStateLoad.call( this, state );
						this._colUnique = savedUnique;
						return result;
					};

					SearchInput._presideEqualsDefault = true;
				}

				if ( DT.ColumnControl.content.searchList && !DT.ColumnControl.content.searchList._presideCurrentIndexState ) {
					var origSearchListInit = DT.ColumnControl.content.searchList.init;

					DT.ColumnControl.content.searchList.init = function( config ) {
						this.idxOriginal = this.idx;
						return origSearchListInit.call( this, config );
					};
					DT.ColumnControl.content.searchList._presideCurrentIndexState = true;
				}

				if ( !DT.ColumnControl.content.searchObject ) {
					DT.ColumnControl.content.searchObject = {
						defaults : {
							  className          : "searchObject"
							, relatedTo          : ""
							, relatedToLabel     : ""
							, filterExpressionId : ""
						},
						init : function( config ) {
							var host              = this
							  , dt                = this.dt()
							  , originalIdx       = this.idx()
							  , relatedTo         = config.relatedTo || ""
							  , relatedLabel      = config.relatedToLabel || relatedTo
							  , allowSavedFilter  = !!( config.filterExpressionId && relatedTo )
							, $wrap             = $( '<div class="listing-object-search"></div>' )
							  , pickerId          = "listing-object-filter-" + String( Math.random() ).replace( ".", "" )
							  , current           = { object : { ids : [], labels : [] }, filter : { ids : [], labels : [] } }
							  , loadingState      = false
							  , $objectSelect, $filterSelect;

							function pickerUrls( handler, qs ) {
								return {
									  remote   : buildAjaxLink( handler, $.extend( { q : "%QUERY" }, qs ) )
									, prefetch : buildAjaxLink( handler, $.extend( {
										  maxRows              : 100
										, prefetchCacheBuster : pickerId
									  }, qs ) )
								};
							}

							function selectionFromUber( $el ) {
								var uber = $el.data( "uberSelect" )
								  , ids  = []
								  , labels = []
								  , selected, i, id, text;

								if ( !uber ) {
									return { ids : [], labels : [] };
								}

								selected = uber.getSelected() || [];
								for( i=0; i<selected.length; i++ ) {
									id = String( selected[ i ].value || selected[ i ].__value || "" );
									if ( !id.length ) {
										continue;
									}
									ids.push( id );
									text = selected[ i ].text;
									if ( typeof text !== "string" ) {
										text = "";
									}
									labels.push( $( "<div>" ).html( text ).text() || id );
								}

								if ( !ids.length && uber.hidden_field ) {
									ids = String( uber.hidden_field.val() || "" ).split( "," ).filter( Boolean );
									labels = ids.slice();
								}

								return { ids : ids, labels : labels };
							}

							function setPickerSelection( $el, selection ) {
								var uber   = $el.data( "uberSelect" )
								  , ids    = ( selection && selection.ids ) || []
								  , labels = ( selection && selection.labels ) || []
								  , i;

								$el.attr( "data-value", ids.join( "," ) );
								if ( !uber ) {
									return;
								}

								if ( uber.is_multiple ) {
									uber.clear();
								} else if ( typeof uber.results_reset === "function" ) {
									uber.results_reset();
								}

								for( i=0; i<ids.length; i++ ) {
									uber.select( ids[ i ], labels[ i ] || ids[ i ] );
								}
							}

							function hasValue() {
								return current.object.ids.length || current.filter.ids.length;
							}

							function syncParents() {
								var col, init;

								if ( config._parents ) {
									config._parents.forEach( function( btn ) {
										btn.activeList( host.unique() + "object", hasValue() );
									} );
								}

								try {
									col  = dt.column( host.idx() );
									init = col && col.init && col.init();
									if ( init ) {
										init.__ccList = hasValue();
									}
								} catch ( ignore ) {}
							}

							function applySearch( redraw ) {
								current.object = selectionFromUber( $objectSelect );
								current.filter = $filterSelect && $filterSelect.length
									? selectionFromUber( $filterSelect )
									: { ids : [], labels : [] };
								syncParents();
								if ( !loadingState && redraw !== false ) {
									dt.draw();
								}
							}

							function loadFromState( state ) {
								var idx        = host.idxOriginal ? host.idxOriginal() : originalIdx
								  , columnName = dt.column( idx ).name()
								  , loaded;

								if ( !state || !state.columnControl ) {
									return;
								}

								loaded = ( state.columnControl[ columnName ] || state.columnControl[ idx ] || {} ).searchObject;
								if ( !loaded ) {
									return;
								}

								loadingState = true;
								setPickerSelection( $objectSelect, loaded.object || {} );
								if ( $filterSelect && $filterSelect.length ) {
									setPickerSelection( $filterSelect, loaded.filter || {} );
								}
								current.object = loaded.object || { ids : [], labels : [] };
								current.filter = loaded.filter || { ids : [], labels : [] };
								syncParents();
								loadingState = false;
							}

							function buildSelect( opts ) {
								var urls    = pickerUrls( opts.handler, opts.query )
								  , $select = $( "<select></select>" )
										.addClass( "object-picker" )
										.attr( {
											  id                   : pickerId + "-" + opts.suffix
											, name                 : pickerId + "-" + opts.suffix
											, "data-placeholder"   : opts.placeholder
											, "data-remote-url"    : urls.remote
											, "data-prefetch-url"  : urls.prefetch
											, "data-display-limit" : 100
											, "data-value"         : ""
										} );

								if ( opts.multiple ) {
									$select.attr( "multiple", "multiple" );
								}
								if ( opts.htmlLabels ) {
									$select.attr( "data-result-template-format", "{{{text}}}" );
									$select.attr( "data-selected-template-format", "{{{text}}}" );
								}

								return $select;
							}

							function buildField( title, $select ) {
								var $field = $( '<div class="listing-object-search-field"></div>' );
								if ( title ) {
									$field.append( $( '<div class="dtcc-list-title"></div>' ).text( title ) );
								}
								$field.append( $select );
								return $field;
							}

							$objectSelect = buildSelect( {
								  suffix      : "records"
								, handler     : "dataManager.getObjectRecordsForAjaxSelectControl"
								, query       : { object : relatedTo }
								, multiple    : true
								, placeholder : i18n.translateResource( "cms:datamanager.search.data.placeholder", {
									  data         : [ relatedLabel ]
									, defaultValue : "Type to search " + relatedLabel
								  } )
							} );
							$wrap.append( buildField(
								  i18n.translateResource( "cms:datatables.filter.object.records", { defaultValue : "Records" } )
								, $objectSelect
							) );

							if ( allowSavedFilter ) {
								$filterSelect = buildSelect( {
									  suffix      : "filter"
									, handler     : "rulesEngine.getFiltersForAjaxSelectControl"
									, query       : { filterObject : relatedTo }
									, multiple    : false
									, htmlLabels  : true
									, placeholder : i18n.translateResource( "cms:rulesengine.filterPicker.placeholder", {
										  defaultValue : "Type to search globally saved filters"
									  } )
								} );
								$wrap.append( buildField(
									  i18n.translateResource( "cms:datatables.filter.object.savedFilter", { defaultValue : "Saved filter" } )
									, $filterSelect
								) );
							}

							$wrap.on( "click mousedown keydown keypress keyup", function( e ) {
								e.stopPropagation();
							} );

							loadingState = true;
							$objectSelect.presideObjectPicker();
							$objectSelect.on( "change", function() {
								applySearch( true );
							} );

							if ( $filterSelect && $filterSelect.length ) {
								$filterSelect.presideObjectPicker();
								$filterSelect.on( "change", function() {
									applySearch( true );
								} );
							}

							dt.on( "preXhr.DT", function( e, s, d ) {
								var idx = host.idx();
								if ( !d.columns || !d.columns[ idx ] ) {
									return;
								}
								if ( !d.columns[ idx ].columnControl ) {
									d.columns[ idx ].columnControl = {};
								}
								if ( current.object.ids.length ) {
									d.columns[ idx ].columnControl.object = current.object;
								}
								if ( current.filter.ids.length ) {
									d.columns[ idx ].columnControl.filter = current.filter;
								}
							} );

							dt.on( "stateSaveParams.DT", function( e, s, data ) {
								var idx  = host.idxOriginal ? host.idxOriginal() : originalIdx
								  , prop = dt.column( idx ).name() || idx;

								if ( !data.columnControl ) {
									data.columnControl = {};
								}
								if ( !data.columnControl[ prop ] ) {
									data.columnControl[ prop ] = {};
								}
								if ( hasValue() ) {
									data.columnControl[ prop ].searchObject = {
										  object : current.object
										, filter : current.filter
									};
								} else {
									delete data.columnControl[ prop ].searchObject;
								}
							} );

							dt.on( "stateLoaded.DT", function( e, s, state ) {
								loadFromState( state );
							} );

							dt.on( "cc-search-clear.DT", function( e, colIdx ) {
								if ( colIdx !== host.idx() ) {
									return;
								}
								loadingState = true;
								setPickerSelection( $objectSelect, { ids : [], labels : [] } );
								if ( $filterSelect && $filterSelect.length ) {
									setPickerSelection( $filterSelect, { ids : [], labels : [] } );
								}
								current = { object : { ids : [], labels : [] }, filter : { ids : [], labels : [] } };
								syncParents();
								loadingState = false;
							} );

							loadFromState( dt.state.loaded() );
							syncParents();
							loadingState = false;

							return $wrap.get( 0 );
						}
					};
				}

				resetLabel   = i18n.translateResource( "cms:datatables.columns.reset", { defaultValue : "Reset to default" } );
				columnsTitle = i18n.translateResource( "cms:datatables.columns.title", { defaultValue : "Columns" } );

				if ( !DT.ColumnControl.content.colVisReset ) {
					DT.ColumnControl.content.colVisReset = {
						defaults : { className : "colVisReset", text : resetLabel },
						init     : function( config ) {
							var el = document.createElement( "button" );
							el.type = "button";
							el.className = "btn btn-link btn-xs listing-colvis-reset";
							el.textContent = config.text;
							el.addEventListener( "click", function( e ) {
								e.preventDefault();
								e.stopPropagation();
								$( dtApi.table().node() ).trigger( "preside-listing-columns-reset" );
							} );
							return el;
						}
					};
				}

				if ( DT.ColumnControl.content.listingColVis ) {
					return;
				}

				DT.ColumnControl.content.listingColVis = {
					defaults : {
						  className : "listingColVis"
						, columns   : ".listing-user-column"
						, search    : true
						, title     : columnsTitle
					},
					init : function( config ) {
						var dt      = this.dt()
						  , $wrap   = $( '<div class="dtcc-list listing-colvis-list"></div>' )
						  , $title  = $( '<div class="dtcc-list-title"></div>' ).text( config.title )
						  , $search = $( '<input type="text" class="dtcc-list-search form-control form-control-sm" />' )
						  , $list   = $( '<div class="dtcc-list-buttons"></div>' );

						$search.attr( "placeholder", i18n.translateResource( "cms:datatables.columns.search", { defaultValue : "Search..." } ) );

						if ( config.title ) {
							$wrap.append( $title );
						}
						if ( config.search ) {
							$wrap.append( $search );
						}
						$wrap.append( $list );

						function userIndexes() {
							var idxs = [];
							dt.columns( config.columns ).every( function() {
								idxs.push( this.index() );
							} );
							return idxs;
						}

						var suppressColvisRender = false;

						function isLocked( idx ) {
							return $( dt.column( idx ).header() ).hasClass( "listing-locked-column" );
						}

						function rowHtml( idx, visible, locked ) {
							var col   = dt.column( idx )
							  , label = $( "<div>" ).text( $.trim( col.title() ) ).html()
							  , drag  = i18n.translateResource( "cms:datatables.columns.drag", { defaultValue : "Drag to reorder" } )
							  , html  = '<div class="listing-column-row' + ( locked ? " is-locked" : "" ) + ( visible ? "" : " is-hidden" ) + '" data-index="' + idx + '">';

							if ( visible && !locked ) {
								html += '<span class="listing-column-drag" title="' + drag + '"><i class="fa fa-bars"></i></span>';
							} else {
								html += '<span class="listing-column-drag is-placeholder"></span>';
							}

							html += '<label class="listing-column-label">' +
								'<input type="checkbox" class="listing-column-toggle no-ace"' + ( visible ? ' checked' : '' ) + ( locked ? ' disabled' : '' ) + ' />' +
								'<span>' + label + '</span>' +
							'</label></div>';
							return html;
						}

						function visibleFieldsFromList() {
							var fields = [];

							$list.find( ".listing-colvis-visible .listing-column-row" ).each( function() {
								var idx   = parseInt( $( this ).attr( "data-index" ), 10 )
								  , field = dt.column( idx ).dataSrc();

								if ( field ) {
									fields.push( field );
								}
							} );

							return fields;
						}

						function applyVisibleFieldOrder( fields ) {
							if ( typeof applyColumnLayout !== "function" || !fields || !fields.length ) {
								render();
								return;
							}

							suppressColvisRender = true;
							applyColumnLayout( fields );
							suppressColvisRender = false;
							render();
						}

						function bindSortable() {
							var $visible = $list.find( ".listing-colvis-visible" );

							if ( !$visible.length || !$.fn.sortable ) {
								return;
							}
							if ( $visible.data( "ui-sortable" ) ) {
								$visible.sortable( "destroy" );
							}
							$visible.sortable( {
								  items  : ".listing-column-row:not(.is-locked)"
								, handle : ".listing-column-drag"
								, axis   : "y"
								, update : function() {
									var fields = visibleFieldsFromList();
									setTimeout( function() {
										applyVisibleFieldOrder( fields );
									}, 0 );
								  }
							} );
						}

						function render() {
							var idxs     = userIndexes()
							  , visible  = []
							  , hidden   = []
							  , locked   = []
							  , unlocked = []
							  , html     = []
							  , i, idx;

							for( i=0; i<idxs.length; i++ ) {
								idx = idxs[ i ];
								if ( dt.column( idx ).visible() ) {
									visible.push( idx );
								} else {
									hidden.push( idx );
								}
							}
							for( i=0; i<visible.length; i++ ) {
								if ( isLocked( visible[ i ] ) ) {
									locked.push( visible[ i ] );
								} else {
									unlocked.push( visible[ i ] );
								}
							}

							html.push( '<div class="listing-colvis-visible">' );
							for( i=0; i<locked.length; i++ ) {
								html.push( rowHtml( locked[ i ], true, true ) );
							}
							for( i=0; i<unlocked.length; i++ ) {
								html.push( rowHtml( unlocked[ i ], true, false ) );
							}
							html.push( '</div>' );
							if ( hidden.length ) {
								html.push( '<div class="listing-colvis-hidden">' );
								for( i=0; i<hidden.length; i++ ) {
									html.push( rowHtml( hidden[ i ], false, false ) );
								}
								html.push( '</div>' );
							}

							$list.html( html.join( "" ) );
							filterRows();
							bindSortable();
						}

						function filterRows() {
							var q = $.trim( $search.val() ).toLowerCase();
							$list.find( ".listing-column-row" ).each( function() {
								var match = !q.length || $( this ).text().toLowerCase().indexOf( q ) !== -1;
								$( this ).toggleClass( "hide", !match );
							} );
						}

						$wrap.on( "click", ".listing-column-label, .listing-column-toggle, .listing-column-drag", function( e ) {
							e.stopPropagation();
						} );

						$wrap.on( "change", ".listing-column-toggle", function() {
							var $input  = $( this )
							  , idx     = parseInt( $input.closest( ".listing-column-row" ).attr( "data-index" ), 10 )
							  , checked = $input.is( ":checked" )
							  , field   = dt.column( idx ).dataSrc()
							  , fields;

							if ( !checked ) {
								dt.column( idx ).visible( false );
								render();
								return;
							}

							fields = visibleFieldsFromList();
							if ( field && fields.indexOf( field ) === -1 ) {
								fields.push( field );
							}
							applyVisibleFieldOrder( fields );
						} );

						$search.on( "input", function( e ) {
							e.stopPropagation();
							filterRows();
						} );

						dt.on( "columns-reordered", function() {
							if ( !suppressColvisRender ) {
								render();
							}
						} );
						render();

						return $wrap.get( 0 );
					}
				};
			};

			searchContentForField = function( field ) {
				var filter = null
				  , options, i;

				if ( !allowColumnFilter ) {
					return [];
				}

				( toolbarConfig.quickFilters || [] ).forEach( function( item ) {
					if ( item.field === field ) {
						filter = item;
					}
				} );

				if ( !filter ) {
					return [];
				}

				if ( filter.type === "object" ) {
					if ( !filter.relatedTo ) {
						return [];
					}
					return [ {
						  extend             : "searchObject"
						, relatedTo          : filter.relatedTo
						, relatedToLabel     : filter.relatedToLabel || filter.relatedTo
						, filterExpressionId : filter.filterExpressionId || ""
					} ];
				}

				if ( filter.type === "enum" && filter.options ) {
					options = [];
					for( i=0; i<filter.options.length; i++ ) {
						options.push( { label : filter.options[ i ].label, value : filter.options[ i ].id } );
					}
					return [ { extend : "searchList", options : options, search : options.length > 6, select : false, title : "" } ];
				}

				if ( filter.type === "boolean" ) {
					return [ {
						  extend  : "searchList"
						, options : [
							  { label : i18n.translateResource( "cms:yes", { defaultValue : "Yes" } ), value : "true" }
							, { label : i18n.translateResource( "cms:no" , { defaultValue : "No"  } ), value : "false" }
						  ]
						, search  : false
						, select  : false
						, title   : ""
					} ];
				}

				if ( filter.type === "date" ) {
					return [ { extend : "searchDateTime", format : "YYYY-MM-DD", excludeLogic : [ "notEqual", "empty", "notEmpty" ] } ];
				}

				if ( filter.type === "numeric" ) {
					return [ { extend : "searchNumber", excludeLogic : [ "empty", "notEmpty" ] } ];
				}

				return [ { extend : "searchText", excludeLogic : [ "empty", "notEmpty" ] } ];
			};

			headingContent = function( extras, orderable ) {
				var content = [];

				if ( orderable ) {
					content.push( {
						  extend : "order"
						, text   : i18n.translateResource( "cms:datatables.sort.toggle", { defaultValue : "Sort. Shift-click to add" } )
					} );
				}

				if ( extras && extras.length ) {
					content.push( {
						  extend     : "dropdown"
						, icon       : "filter"
						, iconActive : "filterActive"
						, text       : i18n.translateResource( "cms:datatables.filter.btn", { defaultValue : "Filter" } )
						, content    : extras
					} );
				}

				return [ { target : 0, content : content } ];
			};

			pickerSelection = function( raw ) {
				var ids = [], labels = [];

				if ( !raw || typeof raw !== "object" ) {
					return { ids : [], labels : [] };
				}
				if ( $.isArray( raw.ids ) ) {
					ids = raw.ids.filter( Boolean ).map( String );
				} else if ( typeof raw.ids === "string" && raw.ids.length ) {
					ids = raw.ids.split( "," ).filter( Boolean );
				}
				if ( $.isArray( raw.labels ) ) {
					labels = raw.labels.map( String );
				}

				return { ids : ids, labels : labels };
			};

			pickerHasValue = function( raw ) {
				return pickerSelection( raw ).ids.length > 0;
			};

			columnSearchToExpressions = function( filter, search ) {
				var expressions = []
				  , list        = []
				  , logic, value, i, fields, key, timePeriod, numericOp, stringOp, objectSel, filterSel;

				if ( !filter || !search ) {
					return expressions;
				}

				if ( filter.type === "object" ) {
					objectSel = pickerSelection( search.object );
					filterSel = pickerSelection( search.filter );
					if ( objectSel.ids.length && filter.expressionId ) {
						expressions.push( { expression : filter.expressionId, fields : { _is : true, value : objectSel.ids.join( "," ) } } );
					}
					if ( filter.filterExpressionId ) {
						for( i=0; i<filterSel.ids.length; i++ ) {
							if ( expressions.length ) {
								expressions.push( "and" );
							}
							expressions.push( { expression : filter.filterExpressionId, fields : { value : filterSel.ids[ i ] } } );
						}
					}
					return expressions.length > 2 ? [ expressions ] : expressions;
				}

				if ( !filter.expressionId ) {
					return expressions;
				}

				if ( search.list ) {
					for( key in search.list ) {
						if ( search.list.hasOwnProperty( key ) && String( search.list[ key ] ).length ) {
							list.push( search.list[ key ] );
						}
					}
					if ( filter.type === "boolean" ) {
						if ( list.length === 1 ) {
							expressions.push( { expression : filter.expressionId, fields : { _is : String( list[ 0 ] ) === "true" } } );
						}
						return expressions;
					}
					for( i=0; i<list.length; i++ ) {
						fields = { _is : true };
						if ( filter.type === "enum" ) {
							fields.enumValue = list[ i ];
						} else {
							fields.value = list[ i ];
						}
						if ( expressions.length ) {
							expressions.push( "or" );
						}
						expressions.push( { expression : filter.expressionId, fields : fields } );
					}
					return expressions.length > 2 ? [ expressions ] : expressions;
				}

				if ( !search.search ) {
					return expressions;
				}

				logic = search.search.logic || "";
				value = search.search.value;

				if ( logic === "empty" || logic === "notEmpty" ) {
					return expressions;
				}
				if ( ( value === "" || typeof value === "undefined" ) && logic !== "empty" && logic !== "notEmpty" ) {
					return expressions;
				}

				if ( filter.type === "date" ) {
					value = String( value ).substring( 0, 10 );
					if ( logic === "equal" ) {
						timePeriod = { type : "equal", date1 : value };
					} else if ( logic === "greater" ) {
						timePeriod = { type : "after", date1 : value };
					} else if ( logic === "less" ) {
						timePeriod = { type : "before", date1 : value };
					} else {
						return expressions;
					}
					expressions.push( { expression : filter.expressionId, fields : { _time : JSON.stringify( timePeriod ) } } );
					return expressions;
				}

				if ( filter.type === "numeric" ) {
					numericOp = { equal : "eq", notEqual : "neq", greater : "gt", greaterOrEqual : "gte", less : "lt", lessOrEqual : "lte" }[ logic ];
					if ( !numericOp ) {
						return expressions;
					}
					expressions.push( { expression : filter.expressionId, fields : { _numericOperator : numericOp, value : value } } );
					return expressions;
				}

				stringOp = { contains : "contains", notContains : "notcontains", equal : "eq", notEqual : "neq", starts : "startsWith", ends : "endsWith" }[ logic ];
				if ( !stringOp ) {
					return expressions;
				}
				expressions.push( { expression : filter.expressionId, fields : { _stringOperator : stringOp, value : value } } );
				return expressions;
			};

			columnFilterListValueLabel = function( filter, value ) {
				var i;

				if ( filter.type === "boolean" ) {
					return String( value ) === "true"
						? i18n.translateResource( "cms:yes", { defaultValue : "Yes" } )
						: i18n.translateResource( "cms:no" , { defaultValue : "No"  } );
				}

				if ( filter.options ) {
					for( i=0; i<filter.options.length; i++ ) {
						if ( String( filter.options[ i ].id ) === String( value ) ) {
							return filter.options[ i ].label;
						}
					}
				}

				return String( value );
			};

			columnFilterOperatorLabel = function( type, logic ) {
				var fallbacks = {
					  contains       : "contains"
					, notContains    : "does not contain"
					, equal          : "is"
					, notEqual       : "is not"
					, starts         : "starts with"
					, ends           : "ends with"
					, greater        : "greater than"
					, greaterOrEqual : "at least"
					, less           : "less than"
					, lessOrEqual    : "at most"
				};

				if ( type === "date" && logic === "greater" ) {
					return i18n.translateResource( "cms:datatables.filter.op.greater.date", { defaultValue : "after" } );
				}
				if ( type === "date" && logic === "less" ) {
					return i18n.translateResource( "cms:datatables.filter.op.less.date", { defaultValue : "before" } );
				}

				return i18n.translateResource( "cms:datatables.filter.op." + logic, { defaultValue : fallbacks[ logic ] || logic } );
			};

			columnFilterChipText = function( fieldLabel, detail ) {
				return i18n.translateResource( "cms:datatables.chip.column", {
					  data         : [ fieldLabel, detail ]
					, defaultValue : fieldLabel + ": " + detail
				} );
			};

			columnFilterChipLabel = function( filter, search ) {
				var title    = filter.label || filter.field
				  , values   = []
				  , isString = filter.type === "text" || filter.type === "string"
				  , key, logic, value, operator, detail, objectSel, filterSel, i;

				if ( filter.type === "object" ) {
					objectSel = pickerSelection( search.object );
					filterSel = pickerSelection( search.filter );
					for( i=0; i<objectSel.ids.length; i++ ) {
						values.push( objectSel.labels[ i ] || objectSel.ids[ i ] );
					}
					for( i=0; i<filterSel.ids.length; i++ ) {
						values.push( filterSel.labels[ i ] || filterSel.ids[ i ] );
					}
					if ( !values.length ) {
						return "";
					}
					return columnFilterChipText( title, values.join( ", " ) );
				}

				if ( search.list ) {
					for( key in search.list ) {
						if ( search.list.hasOwnProperty( key ) && String( search.list[ key ] ).length ) {
							values.push( columnFilterListValueLabel( filter, search.list[ key ] ) );
						}
					}
					if ( !values.length ) {
						return "";
					}
					return columnFilterChipText( title, values.join( ", " ) );
				}

				if ( !search.search ) {
					return "";
				}

				logic = search.search.logic || "";
				value = search.search.value;

				if ( logic === "empty" || logic === "notEmpty" ) {
					return "";
				}
				if ( value === "" || typeof value === "undefined" ) {
					return "";
				}

				if ( filter.type === "date" ) {
					value = String( value ).substring( 0, 10 );
				} else if ( isString ) {
					value = i18n.translateResource( "cms:datatables.chip.column.quoted", {
						  data         : [ value ]
						, defaultValue : '"' + value + '"'
					} );
				}

				operator = columnFilterOperatorLabel( filter.type, logic );
				detail   = i18n.translateResource( "cms:datatables.chip.column.withOperator", {
					  data         : [ operator, value ]
					, defaultValue : operator + " " + value
				} );

				return columnFilterChipText( title, detail );
			};

			columnFilterChipsFromRequest = function( dtRequest ) {
				var chips   = []
				  , byField = {}
				  , columns = ( dtRequest && dtRequest.columns ) || []
				  , i, col, field, filter, label;

				( toolbarConfig.quickFilters || [] ).forEach( function( item ) {
					byField[ item.field ] = item;
				} );

				for( i=0; i<columns.length; i++ ) {
					col    = columns[ i ];
					field  = col.name || col.data;
					filter = byField[ field ];
					if ( !field || !filter || !col.columnControl ) {
						continue;
					}
					if ( !columnSearchToExpressions( filter, col.columnControl ).length ) {
						continue;
					}
					label = columnFilterChipLabel( filter, col.columnControl );
					if ( label.length ) {
						chips.push( { field : field, label : label } );
					}
				}

				return chips;
			};

			columnFilterChipsFromStored = function( columnSearch ) {
				var chips   = []
				  , byField = {}
				  , label;

				( toolbarConfig.quickFilters || [] ).forEach( function( item ) {
					byField[ item.field ] = item;
				} );

				$.each( columnSearch || {}, function( field, spec ) {
					var filter = byField[ field ];
					if ( !filter ) {
						return;
					}
					if ( !columnSearchToExpressions( filter, spec ).length ) {
						return;
					}
					label = columnFilterChipLabel( filter, spec );
					if ( label.length ) {
						chips.push( { field : field, label : label } );
					}
				} );

				return chips;
			};

			syncColumnFilterChips = function() {
				if ( everythingBar ) {
					everythingBar.setColumnFilters( columnFilterChipsFromStored( lastColumnSearch ) );
				}
			};

			clearColumnFilter = function( field ) {
				var lockedSearch;

				if ( listingViews && listingViews.filtersAreLocked() ) {
					lockedSearch = listingViews.lockedFilterState().columnSearch || {};
					if ( field && lockedSearch[ field ] ) {
						return;
					}
				}
				if ( field && lastColumnSearch[ field ] ) {
					delete lastColumnSearch[ field ];
				}
				if ( !dtApi || !field ) {
					return;
				}

				dtApi.columns().every( function() {
					if ( this.dataSrc() === field ) {
						this.columnControl.searchClear();
					}
				} );
			};

			normalizeColumnSearchMap = function( map ) {
				var out = {};

				$.each( map || {}, function( field, spec ) {
					var bucket, search, list, objectSel, filterSel, loaded;
					if ( !field || !spec || typeof spec !== "object" ) {
						return;
					}
					loaded    = spec.searchObject || spec.SEARCHOBJECT || {};
					search    = spec.search || spec.searchInput || spec.SEARCH || spec.SEARCHINPUT;
					list      = spec.list   || spec.searchList  || spec.LIST   || spec.SEARCHLIST;
					objectSel = pickerSelection( spec.object || loaded.object );
					filterSel = pickerSelection( spec.filter || loaded.filter );
					bucket    = {};
					if ( search ) {
						bucket.search = search;
					}
					if ( list ) {
						bucket.list = list;
					}
					if ( objectSel.ids.length ) {
						bucket.object = objectSel;
					}
					if ( filterSel.ids.length ) {
						bucket.filter = filterSel;
					}
					if ( bucket.search || bucket.list || bucket.object || bucket.filter ) {
						out[ field ] = bucket;
					}
				} );

				return out;
			};

			normalizeFilterState = function( raw ) {
				raw = raw || {};
				return {
					  savedFilterIds : raw.savedFilterIds || raw.savedfilterids || raw.SAVEDFILTERIDS || []
					, advancedFilter : raw.advancedFilter || raw.advancedfilter || raw.ADVANCEDFILTER || []
					, columnSearch   : normalizeColumnSearchMap( raw.columnSearch || raw.columnsearch || raw.COLUMNSEARCH || {} )
				};
			};

			expressionsFromStoredColumnSearch = function( columnSearch ) {
				var expressions = []
				  , byField     = {}
				  , parts;

				( toolbarConfig.quickFilters || [] ).forEach( function( item ) {
					byField[ item.field ] = item;
				} );

				$.each( columnSearch || {}, function( field, spec ) {
					if ( !byField[ field ] ) {
						return;
					}
					parts = columnSearchToExpressions( byField[ field ], spec );
					if ( parts.length ) {
						if ( expressions.length ) {
							expressions.push( "and" );
						}
						if ( parts.length === 1 ) {
							expressions.push( parts[ 0 ] );
						} else {
							expressions.push( parts );
						}
					}
				} );

				return expressions;
			};

			columnControlStateFromSearch = function( columnSearch ) {
				var state = { columnControl : {} };

				$.each( columnSearch || {}, function( field, spec ) {
					var bucket = {};
					if ( spec.search ) {
						bucket.searchInput = spec.search;
					}
					if ( spec.list ) {
						if ( $.isArray( spec.list ) ) {
							bucket.searchList = spec.list;
						} else {
							bucket.searchList = [];
							$.each( spec.list, function( key, value ) {
								if ( String( value ).length ) {
									bucket.searchList.push( value );
								}
							} );
						}
					}
					if ( pickerHasValue( spec.object ) || pickerHasValue( spec.filter ) ) {
						bucket.searchObject = {
							  object : pickerSelection( spec.object )
							, filter : pickerSelection( spec.filter )
						};
					}
					if ( bucket.searchInput || ( bucket.searchList && bucket.searchList.length ) || bucket.searchObject ) {
						state.columnControl[ field ] = bucket;
					}
				} );

				return state;
			};

			syncViewFilterLock = function() {
				var locked      = !!( listingViews && listingViews.filtersAreLocked() )
				  , editing     = !!( listingViews && listingViews.isEditing() )
				  , lockState   = ( listingViews && listingViews.lockedFilterState ) ? listingViews.lockedFilterState() : {}
				  , lockedFields = lockState.columnSearch || {}
				  , hasAdvanced = $.isArray( lockState.advancedFilter ) && lockState.advancedFilter.length > 0;

				$container.toggleClass( "listing-view-locked", locked );
				$container.toggleClass( "listing-view-editing", editing );
				$container.toggleClass( "listing-view-advanced-locked", !!( locked && hasAdvanced ) );

				if ( dtApi ) {
					dtApi.columns( ".listing-data-column" ).every( function() {
						var field = this.dataSrc();
						$( this.header() ).toggleClass( "listing-view-filter-locked", locked && !!lockedFields[ field ] );
					} );
				}

				if ( everythingBar && everythingBar.setFilterLock ) {
					everythingBar.setFilterLock( {
						  locked        : locked
						, savedIds      : lockState.savedFilterIds || []
						, columnFields  : Object.keys( lockedFields )
					} );
				}
			};

			expressionsFromColumnControl = function( dtRequest ) {
				var expressions = []
				  , columns     = ( dtRequest && dtRequest.columns ) || []
				  , byField     = {}
				  , i, col, field, parts;

				( toolbarConfig.quickFilters || [] ).forEach( function( item ) {
					byField[ item.field ] = item;
				} );

				for( i=0; i<columns.length; i++ ) {
					col   = columns[ i ];
					field = col.name || col.data;
					if ( !field || !col.columnControl || !byField[ field ] ) {
						continue;
					}
					parts = columnSearchToExpressions( byField[ field ], col.columnControl );
					if ( parts.length ) {
						if ( expressions.length ) {
							expressions.push( "and" );
						}
						if ( parts.length === 1 ) {
							expressions.push( parts[ 0 ] );
						} else {
							expressions.push( parts );
						}
					}
				}

				return expressions;
			};

			listingPreferencePayload = function( extra ) {
				return $.extend( {
					  object               : object
					, listingKey           : listingKey
					, listingContextKey    : listingContextKey || toolbarConfig.listingContextKey || ""
					, namedListingContext  : namedListingContext || toolbarConfig.namedListingContext || false
					, grantedGridFields    : ( toolbarConfig.grantedColumns || [] ).join( "," )
					, grantedGridFieldsSig : toolbarConfig.grantedColumnsSig || ""
				}, extra || {} );
			};

			stripListingTableColumnControlState = function( data ) {
				if ( !data || typeof data !== "object" ) {
					return data;
				}

				delete data.columnControl;
				if ( $.isArray( data.columns ) ) {
					data.columns.forEach( function( col ) {
						if ( col && typeof col === "object" ) {
							delete col.columnControl;
							delete col.data;
							delete col.name;
						}
					} );
				}

				return data;
			};

			persistListingTableState = function( key, data ) {
				var payload = JSON.stringify( stripListingTableColumnControlState( data ) )
				  , i, storageKey;

				try {
					window.localStorage.setItem( key, payload );
					return;
				} catch ( e ) {}

				for( i=window.localStorage.length - 1; i>=0; i-- ) {
					storageKey = window.localStorage.key( i );
					if ( storageKey && ( storageKey.indexOf( "DataTables_listing_" ) === 0 || storageKey.indexOf( "PresideListingFilters_" ) === 0 ) ) {
						window.localStorage.removeItem( storageKey );
					}
				}

				try {
					window.localStorage.setItem( key, payload );
				} catch ( retry ) {}
			};

			persistListingFilterState = function() {
				var state = getListingUrlState()
				  , key   = "PresideListingFilters_" + tableId
				  , i, storageKey;

				delete state.o;

				try {
					window.localStorage.setItem( key, JSON.stringify( state ) );
					return;
				} catch ( e ) {}

				for( i=window.localStorage.length - 1; i>=0; i-- ) {
					storageKey = window.localStorage.key( i );
					if ( storageKey && storageKey.indexOf( "PresideListingFilters_" ) === 0 ) {
						window.localStorage.removeItem( storageKey );
					}
				}

				try {
					window.localStorage.setItem( key, JSON.stringify( state ) );
				} catch ( retry ) {}
			};

			loadListingFilterState = function() {
				var raw, parsed;

				try {
					raw = window.localStorage.getItem( "PresideListingFilters_" + tableId );
				} catch ( e ) {
					return null;
				}

				if ( !raw ) {
					return null;
				}

				try {
					parsed = JSON.parse( raw );
				} catch ( e ) {
					return null;
				}

				if ( !parsed || typeof parsed !== "object" ) {
					return null;
				}

				return parsed;
			};

			listingColumnIndexForField = function( field ) {
				var found = -1;

				if ( !dtApi || !field ) {
					return found;
				}

				dtApi.columns().every( function() {
					if ( found < 0 && String( this.dataSrc() ) === String( field ) ) {
						found = this.index();
					}
				} );

				return found;
			};

			getListingSortState = function() {
				var order, i, col, idx, dir, field, out;

				if ( !dtApi ) {
					return [];
				}

				order = dtApi.order() || [];
				out   = [];
				for( i=0; i<order.length; i++ ) {
					col = order[ i ];
					if ( $.isArray( col ) ) {
						idx = col[ 0 ];
						dir = col[ 1 ];
					} else if ( col && typeof col === "object" ) {
						idx = col.column;
						dir = col.dir;
					} else {
						continue;
					}
					field = dtApi.column( idx ).dataSrc();
					if ( field && String( field ).charAt( 0 ) !== "_" ) {
						out.push( [ String( field ), dir === "desc" ? "desc" : "asc" ] );
					}
				}

				return out;
			};

			setListingSortState = function( pairs ) {
				var mapped = []
				  , i, field, dir, idx;

				if ( !dtApi || !$.isArray( pairs ) ) {
					return;
				}

				for( i=0; i<pairs.length; i++ ) {
					field = pairs[ i ] && pairs[ i ][ 0 ];
					dir   = pairs[ i ] && pairs[ i ][ 1 ] === "desc" ? "desc" : "asc";
					idx   = listingColumnIndexForField( field );
					if ( idx >= 0 ) {
						mapped.push( [ idx, dir ] );
					}
				}

				if ( mapped.length ) {
					dtApi.order( mapped );
				}
			};

			listingSortMatchesDefault = function( order ) {
				return JSON.stringify( order || [] ) === JSON.stringify( listingDefaultSortFields || [] );
			};

			syncListingSortBadges = function() {
				var order = dtApi ? ( dtApi.order() || [] ) : []
				  , show  = order.length > 1
				  , ranks = {}
				  , title = i18n.translateResource( "cms:datatables.sort.toggle", { defaultValue : "Sort. Shift-click to add" } );

				order.forEach( function( col, i ) {
					var idx = $.isArray( col ) ? col[ 0 ] : ( col && ( col.column !== undefined ? col.column : ( col.col !== undefined ? col.col : col.idx ) ) );
					if ( typeof idx === "number" ) {
						ranks[ idx ] = i + 1;
					}
				} );

				$listingTable.find( "thead th" ).each( function() {
					var $th    = $( this )
					  , idx    = dtApi.column( this ).index()
					  , $btn   = $th.find( ".dtcc-button_order" )
					  , $badge = $btn.find( ".listing-sort-priority" )
					  , rank   = ranks[ idx ];

					if ( !$btn.length ) {
						return;
					}
					$btn.attr( "title", title );
					if ( show && rank ) {
						if ( !$badge.length ) {
							$badge = $( '<span class="listing-sort-priority"></span>' );
							$btn.append( $badge );
						}
						$badge.text( rank ).show();
					} else if ( $badge.length ) {
						$badge.hide();
					}
				} );
			};

			getListingUrlState = function() {
				var advanced = []
				  , extra    = []
				  , raw      = $filterDiv.find( "[name=filter]" ).val();

				if ( raw && raw.length ) {
					try { advanced = JSON.parse( raw ); } catch( e ) { advanced = []; }
				}
				if ( !$.isArray( advanced ) ) {
					advanced = [];
				}
				if ( everythingBar && everythingBar.getExtraFilters ) {
					extra = everythingBar.getExtraFilters();
				}

				return {
					  q : getSearchQuery()
					, f : getFavourites() ? getFavourites().split( "," ).filter( Boolean ) : []
					, a : advanced
					, x : extra
					, c : normalizeColumnSearchMap( lastColumnSearch || {} )
					, o : getListingSortState()
				};
			};

			encodeCurrentListingUrl = function() {
				var state = getListingUrlState();

				if ( listingSortMatchesDefault( state.o ) ) {
					state.o = [];
				}

				if ( typeof PresideDatatables.encodeListingUrlState === "function" ) {
					return PresideDatatables.encodeListingUrlState( state );
				}

				return "";
			};

			pushListingUrl = function() {
				var encoded;

				if ( !listingUrlReady || listingUrlApplying ) {
					return;
				}

				encoded = encodeCurrentListingUrl();
				if ( encoded === listingUrlLast ) {
					return;
				}

				listingUrlLast = encoded;
				persistListingFilterState();
				if ( typeof PresideDatatables.writeListingUrlState === "function" ) {
					PresideDatatables.writeListingUrlState( encoded, "push", tableId );
				}
			};

			applyListingUrlState = function( state, opts ) {
				var skipDraw = !!( opts && opts.skipDraw );

				state = state || {};
				listingUrlApplying = true;

				if ( everythingBar ) {
					everythingBar.setFavourites( state.f || [] );
					everythingBar.setSearchQuery( state.q || "" );
					if ( everythingBar.setExtraFilters ) {
						everythingBar.setExtraFilters( state.x || [] );
					} else if ( everythingBar.clearExtraFilters ) {
						everythingBar.clearExtraFilters();
					}
				}
				setAdvancedFilter( state.a || [] );
				applyColumnSearch( state.c || {} );
				syncColumnFilterChips();
				if ( $.isArray( state.o ) ) {
					setListingSortState( state.o.length ? state.o : listingDefaultSortFields );
				}

				if ( !skipDraw && dtApi ) {
					dtApi.draw();
				}
				persistListingFilterState();
				listingUrlApplying = false;
			};

			setupListingUrlSync = function() {
				var ns = "listingUrl" + tableId;

				if ( dtApi ) {
					dtApi.on( "order.dt", function() {
						pushListingUrl();
						syncListingSortBadges();
					} );
				}

				$( window ).off( "popstate." + ns ).on( "popstate." + ns, function() {
					var state = ( typeof PresideDatatables.readListingUrlState === "function" )
						? PresideDatatables.readListingUrlState( tableId )
						: null;

					applyListingUrlState( state || listingUrlBaseline || {} );
					listingUrlLast = encodeCurrentListingUrl();
				} );
			};

			persistActiveView = function( viewId ) {
				if ( !saveListingColumnsUrl ) {
					return;
				}

				$.ajax( {
					  url  : saveListingColumnsUrl
					, type : "POST"
					, data : listingPreferencePayload( { activeView : viewId || "default" } )
				} );
			};

			saveVisibleColumns = function() {
				var fields;

				if ( !allowColumnPicker || !saveListingColumnsUrl || !columnUiReady ) {
					return;
				}
				if ( listingViews && listingViews.shouldSkipColumnPrefSave() ) {
					listingViews.refreshDirty();
					return;
				}

				fields = getVisibleGridFields();
				if ( listingViews ) {
					listingViews.syncDefaultColumns( fields );
				}
				clearTimeout( saveColumnsTimer );
				saveColumnsTimer = setTimeout( function() {
					$.ajax( {
						  url  : saveListingColumnsUrl
						, type : "POST"
						, data : listingPreferencePayload( { columns : fields.join( "," ) } )
						, error : function() {
							$.gritter.add({
								  title      : i18n.translateResource( "cms:error.notification.title", { defaultValue : "Error" } )
								, text       : i18n.translateResource( "cms:datatables.columns.save.error", { defaultValue : "Your column changes could not be saved." } )
								, class_name : "gritter-error"
								, sticky     : false
							});
						  }
					} );
				}, 300 );
			};

			applyDefaultColumnVisibility = function() {
				var defaults = toolbarConfig.defaultColumns || []
				  , locked   = toolbarConfig.lockedColumns || [];

				if ( !dtApi ) {
					return;
				}

				dtApi.columns( ".listing-data-column" ).every( function() {
					var field = this.dataSrc()
					  , show  = defaults.indexOf( field ) !== -1 || locked.indexOf( field ) !== -1;

					this.visible( show, false );
				} );
				dtApi.columns.adjust().draw();
			};

			applyColumnLayout = function( fields ) {
				var locked = toolbarConfig.lockedColumns || []
				  , desired = fields || []
				  , i, current, fromIdx, toIdx, field;

				if ( !dtApi ) {
					return;
				}

				dtApi.columns( ".listing-data-column" ).every( function() {
					var colField = this.dataSrc()
					  , show     = locked.indexOf( colField ) !== -1 || desired.indexOf( colField ) !== -1;

					this.visible( show, false );
				} );

				if ( dtApi.colReorder ) {
					var userDesired = desired.filter( function( item ) {
						return locked.indexOf( item ) === -1;
					} );
					for( i=0; i<userDesired.length; i++ ) {
						field = userDesired[ i ];
						current = [];
						dtApi.columns( ".listing-user-column" ).every( function() {
							current.push( { index : this.index(), field : this.dataSrc() } );
						} );
						fromIdx = -1;
						current.forEach( function( col ) {
							if ( col.field === field ) {
								fromIdx = col.index;
							}
						} );
						toIdx = current[ i ] ? current[ i ].index : -1;
						if ( fromIdx >= 0 && toIdx >= 0 && fromIdx !== toIdx ) {
							dtApi.colReorder.move( fromIdx, toIdx );
						}
					}
				}

				dtApi.columns.adjust();
			};

			captureColumnSearch = function( dtRequest ) {
				var search  = {}
				  , seen    = {}
				  , columns = ( dtRequest && dtRequest.columns ) || [];

				columns.forEach( function( col ) {
					var field     = col.name || col.data
					  , hasSearch = false
					  , hasList   = false
					  , objectSel, filterSel
					  , hidden    = col.visible === false
					  , bucket;

					if ( !field ) {
						return;
					}
					if ( !col.columnControl ) {
						if ( !hidden ) {
							seen[ field ] = true;
						}
						return;
					}
					if ( col.columnControl.search && String( col.columnControl.search.value || "" ).length ) {
						hasSearch = true;
					}
					if ( col.columnControl.list ) {
						$.each( col.columnControl.list, function( key, value ) {
							if ( String( value ).length ) {
								hasList = true;
							}
						} );
					}
					objectSel = pickerSelection( col.columnControl.object );
					filterSel = pickerSelection( col.columnControl.filter );
					if ( hasSearch || hasList || objectSel.ids.length || filterSel.ids.length ) {
						bucket = {};
						if ( hasSearch ) {
							bucket.search = col.columnControl.search;
						}
						if ( hasList ) {
							bucket.list = col.columnControl.list;
						}
						if ( objectSel.ids.length ) {
							bucket.object = objectSel;
						}
						if ( filterSel.ids.length ) {
							bucket.filter = filterSel;
						}
						search[ field ] = bucket;
						seen[ field ] = true;
					} else if ( !hidden ) {
						seen[ field ] = true;
					}
				} );

				$.each( lastColumnSearch, function( field, bucket ) {
					if ( !seen[ field ] ) {
						search[ field ] = bucket;
					}
				} );

				if ( listingViews && listingViews.filtersAreLocked() ) {
					$.each( listingViews.lockedFilterState().columnSearch || {}, function( field, bucket ) {
						search[ field ] = bucket;
					} );
				}

				lastColumnSearch = search;
				return search;
			};

			getListingViewSnapshot = function() {
				var advanced = []
				  , extra    = ( everythingBar && everythingBar.getExtraFilterExpressions ) ? everythingBar.getExtraFilterExpressions() : []
				  , raw      = $filterDiv.find( "[name=filter]" ).val()
				  , ids      = getFavourites() ? getFavourites().split( "," ).filter( Boolean ) : [];

				if ( raw && raw.length ) {
					try { advanced = JSON.parse( raw ); } catch( e ) { advanced = []; }
				}
				if ( !$.isArray( advanced ) ) {
					advanced = [];
				}

				return {
					  columns     : getVisibleGridFields()
					, filterState : {
						  savedFilterIds : ids
						, advancedFilter : andExpressionArrays( advanced, extra )
						, columnSearch   : $.extend( {}, lastColumnSearch )
					  }
					, sort        : getListingSortState()
				};
			};

			setAdvancedFilter = function( expr ) {
				var $input  = $filterDiv.find( "[name=filter]" )
				  , json    = $.isArray( expr ) && expr.length ? JSON.stringify( expr ) : ""
				  , builder = $input.data( "conditionBuilder" );

				if ( builder ) {
					if ( json.length && typeof builder.load === "function" ) {
						builder.load( json );
					} else if ( typeof builder.clear === "function" ) {
						builder.clear();
					} else {
						$input.val( json );
					}
				} else {
					$input.val( json );
				}

				if ( json.length ) {
					$filterDiv.removeClass( "hide" );
				} else {
					$filterDiv.addClass( "hide" );
				}
				syncAdvancedFilterToggle();
			};

			applyColumnSearch = function( columnSearch ) {
				var state;

				columnSearch     = normalizeColumnSearchMap( columnSearch || {} );
				lastColumnSearch = columnSearch;

				if ( !dtApi ) {
					return;
				}

				if ( dtApi.columns().columnControl ) {
					dtApi.columns().columnControl.searchClear();
				}
				lastColumnSearch = columnSearch;
				state = columnControlStateFromSearch( columnSearch );
				if ( Object.keys( state.columnControl ).length ) {
					dtApi.trigger( "stateLoaded", [ dtApi.settings()[ 0 ], state ] );
				}
				lastColumnSearch = columnSearch;
			};

			applyListingViewSnapshot = function( view, opts ) {
				var filter   = normalizeFilterState( ( view && view.filterState ) || {} )
				  , skipDraw = !!( opts && opts.skipDraw )
				  , sort     = ( view && $.isArray( view.sort ) && view.sort.length ) ? view.sort : listingDefaultSortFields;

				applyColumnLayout( view.columns || [] );
				if ( everythingBar ) {
					everythingBar.setFavourites( filter.savedFilterIds || [] );
					everythingBar.setSearchQuery( "" );
					if ( everythingBar.clearExtraFilters ) {
						everythingBar.clearExtraFilters();
					}
				}
				setAdvancedFilter( filter.advancedFilter || [] );
				applyColumnSearch( filter.columnSearch || {} );
				setListingSortState( sort );
				syncColumnFilterChips();
				syncViewFilterLock();

				if ( !skipDraw && dtApi ) {
					scheduleListingDataReload();
				}
				pushListingUrl();
			};

			applyListingDefaultView = function( opts ) {
				applyColumnLayout( ( opts && opts.columns ) || toolbarConfig.currentColumns || [] );
				if ( everythingBar ) {
					everythingBar.setFavourites( [] );
					everythingBar.setSearchQuery( "" );
					if ( everythingBar.clearExtraFilters ) {
						everythingBar.clearExtraFilters();
					}
				}
				setAdvancedFilter( [] );
				applyColumnSearch( {} );
				setListingSortState( listingDefaultSortFields );
				syncColumnFilterChips();
				syncViewFilterLock();

				if ( !( opts && opts.skipDraw ) && dtApi ) {
					scheduleListingDataReload();
				}
				pushListingUrl();
			};

			setupHeaderColumnUi = function() {
				if ( !dtApi ) {
					return;
				}

				$container.off( ".listingHotkeys" ).on( "keydown.listingHotkeys keypress.listingHotkeys keyup.listingHotkeys", ".dtcc-dropdown input, .dtcc-search input, .listing-colvis-list input, .listing-object-search, .chosen-container", function( e ) {
					e.stopPropagation();
				} );

				$listingTable.on( "column-visibility.dt", function( e, settings, column, visible ) {
					if ( !columnUiReady ) {
						return;
					}

					saveVisibleColumns();
					dtApi.columns.adjust();
					applyListingFooter();

					if ( visible === false ) {
						return;
					}

					( function() {
						var field = dtApi.column( column ).dataSrc()
						  , spec  = field && lastColumnSearch[ field ]
						  , one   = {}
						  , state;

						if ( spec ) {
							one[ field ] = spec;
							state = columnControlStateFromSearch( one );
							if ( Object.keys( state.columnControl ).length ) {
								dtApi.trigger( "stateLoaded", [ dtApi.settings()[ 0 ], state ] );
							}
						}
					} )();

					if ( getVisibleGridFields().some( function( field ) {
						return !listingFieldWasFetched( field );
					} ) ) {
						scheduleListingDataReload();
					}
				} );

				dtApi.on( "columns-reordered", function() {
					if ( columnUiReady ) {
						saveVisibleColumns();
						dtApi.columns.adjust();
						applyListingFooter();
					}
				} );

				$listingTable.on( "preside-listing-columns-reset", function() {
					if ( listingViews && listingViews.isNamedViewActive() ) {
						applyColumnLayout( listingViews.selectedColumns() );
						listingViews.refreshDirty();
						applyListingFooter();
						return;
					}
					if ( !saveListingColumnsUrl ) {
						if ( dtApi.colReorder ) {
							dtApi.colReorder.reset();
						}
						applyDefaultColumnVisibility();
						return;
					}
					$.ajax( {
						  url  : saveListingColumnsUrl
						, type : "POST"
						, data : listingPreferencePayload( { columns : "" } )
						, success : function() {
							window.location.reload();
						  }
					} );
				} );
			};

			setupDatatable = function(){
				var $tableHeaders        = $listingTable.find( "thead > tr:first > th")
				  , colConfig            = []
				  , defaultSort          = []
				  , dynamicHeadersOffset = 1
				  , lastDataIndex        = -1
				  , i, $header, col, fieldName, searchContent, classNames, colVisDropdown;

				registerListingColumnControlPlugins();

				colVisDropdown = {
					  extend  : "dropdown"
					, icon    : "columns"
					, text    : i18n.translateResource( "cms:datatables.columns.btn", { defaultValue : "Columns" } )
					, content : [
						  { extend : "listingColVis", columns : ".listing-user-column", search : true, title : i18n.translateResource( "cms:datatables.columns.title", { defaultValue : "Columns" } ) }
						, "colVisReset"
					  ]
				};

				if ( useMultiActions ) {
					colConfig.push( {
						  className      : "center"
						, orderable      : false
						, searchable     : false
						, data           : "_checkbox"
						, name           : "_checkbox"
						, width          : "5em"
						, defaultContent : ""
						, columnControl  : [ { target : 0, content : [] } ]
					} );
				}

				if ( draftsEnabled  ) { dynamicHeadersOffset++; }
				if ( isMultilingual ) { dynamicHeadersOffset++; }
				if ( noActions ) { dynamicHeadersOffset--; }

				for( i=( useMultiActions ? 1 : 0 ); i < $tableHeaders.length-dynamicHeadersOffset; i++ ){
					$header       = $( $tableHeaders.get(i) );
					fieldName     = $header.attr( "data-field" ) || $header.data( "field" );
					classNames    = [ "listing-data-column" ];
					searchContent = searchContentForField( fieldName );

					if ( $header.hasClass( "listing-user-column" ) ) {
						classNames.push( "listing-user-column" );
					}
					if ( $header.hasClass( "listing-locked-column" ) ) {
						classNames.push( "listing-locked-column" );
					}
					if ( $header.data( "class" ) ) {
						classNames.push( $header.data( "class" ) );
					}

					col = {
						  data           : fieldName || null
						, name           : fieldName || ( "_col" + i )
						, title          : $.trim( $header.text() )
						, defaultContent : ""
						, className      : classNames.join( " " )
						, visible        : $header.data( "visible" ) !== false && $header.data( "visible" ) !== "false"
						, columnControl  : headingContent( searchContent, !$header.hasClass( "no-sorting" ) )
					};
					if ( $header.hasClass( "no-sorting" ) ) {
						col.orderable = false;
					}
					colConfig.push( col );
					lastDataIndex = colConfig.length - 1;

					if ( typeof $header.data( "defaultSortOrder" ) !== "undefined" ) {
						defaultSort.push( [ i, $header.data( "defaultSortOrder" ) ]);
					}
				}
				if( draftsEnabled ) {
					colConfig.push( {
						  orderable      : false
						, searchable     : false
						, data           : "_status"
						, name           : "_status"
						, width          : "15em"
						, defaultContent : ""
						, columnControl  : [ { target : 0, content : [] } ]
					} );
				}
				if( isMultilingual ) {
					colConfig.push( {
						  orderable      : false
						, searchable     : false
						, data           : "_translateStatus"
						, name           : "_translateStatus"
						, width          : "12em"
						, defaultContent : ""
						, columnControl  : [ { target : 0, content : [] } ]
					} );
				}
				if ( !noActions ) {
					colConfig.push( {
						  className      : "text-right"
						, orderable      : false
						, searchable     : false
						, data           : "_options"
						, name           : "_options"
						, width          : "13em"
						, defaultContent : ""
						, columnControl  : [ { target : 0, content : allowColumnPicker ? [ colVisDropdown ] : [] } ]
					} );
				} else if ( allowColumnPicker && lastDataIndex >= 0 ) {
					colConfig[ lastDataIndex ].columnControl[ 0 ].content.push( colVisDropdown );
				}

				for( i=0; i < $tableHeaders.length; i++ ){
					$header = $( $tableHeaders.get(i) );
					if ( typeof $header.data( "class" ) !== "undefined" && colConfig[ i ] && !$header.hasClass( "listing-data-column" ) ) {
						colConfig[ i ].className = $header.data( "class" );
					}
					if ( typeof $header.data( "sortable" ) !== "undefined" && colConfig[ i ] ) {
						colConfig[ i ].orderable = $header.data( "sortable" );
					}
					if ( typeof $header.data( "width" ) !== "undefined" && colConfig[ i ] ) {
						colConfig[ i ].width = $header.data( "width" );
					}
				}

				listingDefaultSortFields = [];
				for( i=0; i<defaultSort.length; i++ ) {
					col = colConfig[ defaultSort[ i ][ 0 ] ];
					if ( col && col.data ) {
						listingDefaultSortFields.push( [ col.data, defaultSort[ i ][ 1 ] === "desc" ? "desc" : "asc" ] );
					}
				}

				datatable = $listingTable.DataTable( {
					  columns        : colConfig
					, order          : defaultSort
					, ordering       : { indicators : false, handler : false }
					, columnDefs     : [ { orderable : false, targets : "no-sorting" } ]
					, serverSide     : true
					, processing     : false
					, stateSave      : true
					, searching      : true
					, autoWidth      : true
					, colReorder     : allowColumnPicker ? { columns : ".listing-user-column", enable : false } : false
					, deferLoading   : 0
					, pageLength     : parseInt( defaultPageLength, 10 )
					, lengthMenu     : paginationOptions
					, layout         : {
						  topStart    : null
						, topEnd      : null
						, bottomStart : "info"
						, bottomEnd   : [ "pageLength", "paging" ]
					  }
					, ajax : PresideDatatables.hungarianAjax( datasourceUrl, function( params, dtRequest ) {
						lastDtRequest = dtRequest;
						params.sSearch = getSearchQuery();
						if ( allowFilter ) {
							params.sSavedFilterExpressions = getFavourites();
						}
						params.gridFields = getVisibleGridFields().concat( hiddenGridFields ).join( "," );
						appendListingGrantParams( params );
						lastFetchedGridFields = params.gridFields.split( "," ).map( function( field ) {
							return $.trim( field );
						} ).filter( Boolean );
					  } )
					, createdRow : function( row ){
						var $row = $( row );
						$row.attr( "data-context-container", "1" );
						if( clickableRows ) {
							$row.addClass( "clickable" );
						}
					}
					, initComplete : function(){
						var storedFilters;

						dtApi = this.api ? this.api() : datatable;
						setupEverythingBar();
						setupHeaderColumnUi();
						if ( allowFilter ) {
							setupFilters();
						}
						setupListingViews();
						if ( listingUrlPending ) {
							applyListingUrlState( listingUrlPending, { skipDraw : true } );
							listingUrlPending = null;
						} else if ( !( listingViews && listingViews.isNamedViewActive() ) && !( listingViews && listingViews.hasResolvedNamedDefault && listingViews.hasResolvedNamedDefault() ) ) {
							storedFilters = loadListingFilterState();
							if ( storedFilters ) {
								applyListingUrlState( storedFilters, { skipDraw : true } );
							}
						}
						dtApi.on( "preXhr", function( e, settings, data ) {
							lastDtRequest = data;
							captureColumnSearch( data );
							if ( allowFilter ) {
								data.sFilterExpression = getMergedFilterExpression();
							}
							syncColumnFilterChips();
							if ( listingViews ) {
								listingViews.refreshDirty();
							}
							pushListingUrl();
							delete data.columns;
							delete data.order;
							delete data.search;
							delete data.draw;
							delete data.start;
							delete data.length;
						} );
						if ( allowDataExport ) {
							setupDataExport();
						}

						columnUiReady = true;
						listingUrlBaseline = $.extend( true, {}, getListingUrlState() );
						listingUrlLast     = encodeCurrentListingUrl();
						setupListingUrlSync();
						if ( !hasPreFilters ) {
							dtApi.draw();
						}
						listingUrlReady = true;
						syncListingSortBadges();
					}
					, language : {
						  emptyTable     : noRecordMessage
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
					, stateLoadParams : function( settings, data ) {
						delete data.colReorder;
						stripListingTableColumnControlState( data );
						if ( data.columns ) {
							data.columns.forEach( function( col ) {
								delete col.visible;
							} );
						}
						if ( hasFilterVal && allowFilter && typeof data.oFilter !== "undefined" ) {
							data.oFilter = undefined;
						}
						return true;
					}
					, stateSaveParams : function( settings, data ) {
						stripListingTableColumnControlState( data );
						if ( allowFilter ) {
							data.oFilter = {
								  filter     : $filterDiv.find( "[name=filter]" ).val()
								, favourites : getFavourites()
								, search     : getSearchQuery()
							};
						}
					}
					, stateLoadCallback : function( settings, callback ) {
						var key = "DataTables_listing_" + tableId
						  , raw, parsed, migrated;

						try {
							raw = window.localStorage.getItem( key );
						} catch ( e ) {
							raw = null;
						}

						if ( raw ) {
							try { parsed = JSON.parse( raw ); } catch( e ) { parsed = null; }
						}
						if ( !parsed && typeof PresideDatatables.migrateLegacyCookieState === "function" ) {
							migrated = PresideDatatables.migrateLegacyCookieState( tableId );
							if ( migrated ) {
								parsed = migrated;
							}
						}
						if ( parsed ) {
							delete parsed.colReorder;
							stripListingTableColumnControlState( parsed );
						}
						callback( parsed || false );
					}
					, stateSaveCallback : function( settings, data ) {
						delete data.colReorder;
						persistListingTableState( "DataTables_listing_" + tableId, data );
					}
					, preDrawCallback : function() {
						var $sheenTarget = $listingTable.closest( ".dt-container" );
						( $sheenTarget.length ? $sheenTarget : $container ).presideLoadingSheen( true );
					}
					, drawCallback : function() {
						$listingTable.closest( ".dt-container" ).presideLoadingSheen( false );
						$container.presideLoadingSheen( false );
						if ( dtApi ) {
							updateSelectAllOptionRecordCount( dtApi.page.info().recordsTotal );
						}
					}
					, footerCallback: function() {
						applyListingFooter();
					}
					, infoCallback: function( settings, start, end, max, total ) {
						var info = "";

						if ( total === 0 ) {
							info = i18n.translateResource( "cms:datatables.infoEmpty", { data : [objectTitle], defaultValue : "" } );
						} else if ( total == UNKNOWN_TOTAL ) {
							info = i18n.translateResource( "cms:datatables.infoCountUnknown", { data : [objectTitle], defaultValue : "" } );
						} else {
							info = i18n.translateResource( "cms:datatables.info", { data : [objectTitle], defaultValue : "" } );
						}

						info = info.replace( "_START_", Intl.NumberFormat().format( start ) );
						info = info.replace( "_END_"  , Intl.NumberFormat().format( end   ) );
						info = info.replace( "_TOTAL_", Intl.NumberFormat().format( total ) );

						return info;
					}
				} );

				dtApi = datatable;

				$listingTable.on( "xhr.dt", function( event, settings, json ){
					lastAjaxResult = json;

					if ( noRecordTableHide ) {
						if ( getSearchQuery().length == 0 ) {
							var iTotalRecords = ( json && ( json.iTotalRecords || json.recordsTotal ) ) || 0;
							if ( iTotalRecords == 0 ) {
								$container.parent().append( noRecordTableHideMessage );
								$container.hide();
							}
						}
					}
				} );
			};

			setupCheckboxBehaviour = function(){
				var $selectAllCBox   = $listingTable.find( "th input:checkbox" )
				  , $multiActionBtns = $listingTable.closest( ".multi-action-form" ).find( ".multi-action-buttons" );

				$selectAllCBox.on( "click" , function(){
					var $allCBoxes = $listingTable.find( "tr > td:first-child input:checkbox" )
					  , isChecked  = $selectAllCBox.is( ":checked" );

					$allCBoxes.each( function(){
						this.checked = isChecked;
						$( this ).closest( "tr" ).toggleClass( "selected", this.checked );
					});

					if ( isChecked ) {
						activateSelectAllOption();
					} else {
						deactivateSelectAllOption();
					}
				});

				$multiActionBtns.data( "hidden", true );
				$listingTable.on( "click", "th input:checkbox,tbody tr > td:first-child input:checkbox", function(){
					var anyBoxesTicked = $listingTable.find( "tr > td:first-child input:checkbox:checked" ).length;

					if ( anyBoxesTicked == $listingTable.find( "td input:checkbox" ).length ) {
						$selectAllCBox.prop( "checked", true );
						activateSelectAllOption();
					} else {
						$selectAllCBox.prop( "checked", false );
						deactivateSelectAllOption();
					}

					enabledContextHotkeys( !anyBoxesTicked );

					if ( anyBoxesTicked && $multiActionBtns.data( "hidden" ) ) {
						$multiActionBtns.slideDown( 250 ).data( "hidden", false ).find( "button" ).prop( "disabled", false );
					} else if ( !anyBoxesTicked && !$multiActionBtns.data( "hidden" ) ) {
						$multiActionBtns.slideUp( 250 ).data( "hidden", true ).find( "button" ).prop( "disabled", true );
					}
				} );
			};

			setupMultiActionButtons = function(){
				var $form              = $listingTable.closest( ".multi-action-form" )
				  , $hiddenActionField = $form.find( "[name=multiAction]" );

				$form.find( ".multi-action-buttons button" ).click( function(){
					$hiddenActionField.val( $( this ).attr( "name" ) );
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
				var $form = $listingTable.closest( ".multi-action-form" );
				if ( $form.length ) {
					$form.find( ".batch-update-select-all .matching-record-count" ).html( newCount );
				}
			};
			activateSelectAllOption = function(){
				var $form = $listingTable.closest( ".multi-action-form" );
				if ( $form.length ) {
					var $selectAllContainer = $form.find( ".batch-update-select-all" );
					if ( $selectAllContainer.length && dtApi && dtApi.page.info().pages > 1 && lastAjaxResult && lastAjaxResult.sBatchSource ) {
						$selectAllContainer.show();
					} else {
						deactivateSelectAllOption();
					}
				}
			};
			deactivateSelectAllOption = function(){
				var $form = $listingTable.closest( ".multi-action-form" );
				if ( $form.length ) {
					var $selectAllContainer = $form.find( ".batch-update-select-all" );
					if ( $selectAllContainer.length ) {
						$selectAllContainer.find( "input[name='batchAll']" ).prop( "checked", false );
						$selectAllContainer.hide();
					}
				}
			};

			enabledContextHotkeys = function( enabled ){
				$listingTable.find( "tbody > tr" ).each( function(){
					if ( enabled ) {
						$( this ).attr( "data-context-container", "1" );
					} else {
						$( this ).removeAttr( "data-context-container" );
					}
				} );
			};

			setupTableRowFocusBehaviour = function(){
				$listingTable.on( "click", "tbody :checkbox", function(){
					var $cbox = $( this );
					$cbox.closest( "tr" ).toggleClass( "selected", $cbox.is( ":checked" ) );
				} );
			};

			setupFilters = function(){
				$filterDiv.find( ".well" ).removeClass( "well" );
				$filterDiv.on( "change", function(){
					if ( listingViews ) {
						listingViews.refreshDirty();
					}
					pushListingUrl();
					redrawTable();
					if ( allowManageFilter ) {
						$filterDiv.find( ".save-filter-btn" ).prop( "disabled", !$filterDiv.find( "[name=filter]" ).val().length );
					}
				} );
				$filterDiv.on( "click", ".advanced-filter-close", function( e ){
					e.preventDefault();
					toggleAdvancedFilter();
				} );
				$toolbar.on( "click", ".advanced-filter-toggle", toggleAdvancedFilter );

				if ( allowManageFilter ) {
					setupQuickSaveFilterIframeModal( $filterDiv );
				}

				if ( hasFilterVal ) {
					$filterDiv.removeClass( "hide" );
					syncAdvancedFilterToggle();
				}

				var filterState;
				try {
					filterState = dtApi.state() && dtApi.state().oFilter;
				} catch( e ) {}

				if ( typeof filterState !== "undefined" && !listingUrlPending ) {
					if ( allowSavedViews ) {
						filtersPopulated = true;
						if ( everythingBar && filterState.search ) {
							everythingBar.setSearchQuery( filterState.search );
						}
					} else if ( allowUseFilter && filterState.filter && filterState.filter.length ) {
						prePopulateFilter( filterState.filter );
					} else {
						filtersPopulated = true;
					}
					if ( !allowSavedViews && everythingBar ) {
						if ( filterState.favourites ) {
							everythingBar.setFavourites( filterState.favourites );
						}
						if ( filterState.search ) {
							everythingBar.setSearchQuery( filterState.search );
						}
					}
				} else {
					filtersPopulated = true;
				}
			};

			setupDataExport = function(){
				var $uberContainer       = $container
				  , $dataExportContainer = $( ".object-listing-table-export", $uberContainer )
				  , $exportBtn           = $( ".object-listing-data-export-button", $uberContainer )
				  , iframeSrc            = $exportBtn.attr( "href" )
				  , $bottom              = $container.find( ".dt-layout-end, .dataTables_paginate, .dt-paging" ).first()
				  , modalOptions, callbacks, processExport, saveExport, exportConfigModal, configIframe;

				if ( $bottom.length ) {
					$bottom.prepend( $dataExportContainer.html() );
				} else {
					$container.find( ".dt-container" ).first().prepend( $dataExportContainer.html() );
				}

				modalOptions = {
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
				};

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
					  , config           = $configForm.serializeObject()
					  , order            = dtApi.order()
					  , sortOrder        = []
					  , key, $hiddenInput, i;

					if ( allowFilter ) {
						config.filterExpressions = getMergedFilterExpression();
						config.savedFilters      = getFavourites();
					}
					if ( allowSearch ) {
						config.searchQuery = getSearchQuery();
					}

					for( key in config ) {
						$hiddenInput = $submissionForm.find( "[name=" + key + "]" );
						if ( !$hiddenInput.length ) {
							$hiddenInput = $( '<input type="hidden" name="' + key + '">' );
							$submissionForm.append( $hiddenInput );
						}
						$hiddenInput.val( config[ key ] );
					}

					for( i=0; i<order.length; i++ ) {
						sortOrder.push( dtApi.column( order[ i ][ 0 ] ).dataSrc() + " " + order[ i ][ 1 ] );
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
					  , config           = $configForm.serializeObject()
					  , order            = dtApi.order()
					  , sortOrder        = []
					  , key, $hiddenInput, i;

					if ( allowFilter ) {
						config.filterExpressions = getMergedFilterExpression();
						config.savedFilters      = getFavourites();
					}
					if ( allowSearch ) {
						config.searchQuery = getSearchQuery();
					}
					for( key in config ) {
						$hiddenInput = $submissionForm.find( "[name=" + key + "]" );
						if ( !$hiddenInput.length ) {
							$hiddenInput = $( '<input type="hidden" name="' + key + '">' );
							$submissionForm.append( $hiddenInput );
						}
						$hiddenInput.val( config[ key ] );
					}
					for( i=0; i<order.length; i++ ) {
						sortOrder.push( dtApi.column( order[ i ][ 0 ] ).dataSrc() + " " + order[ i ][ 1 ] );
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
				$( ".object-listing-data-export-button", $uberContainer ).on( "click", function(e ){
					e.preventDefault();
					exportConfigModal.open();
				} );
				$dataExportContainer.remove();
			};

			refreshFavourites = function( callback ){
				$.ajax({
					  url     : tableSettings.favouritesUrl || cfrequest.favouritesUrl || buildAjaxLink( "rulesEngine.ajaxDataGridFavourites", { objectName : object } )
					, cache   : false
					, success : function( resp ) {
						$favouritesDiv.html( resp );
						if ( callback ) {
							callback.call();
						}
					  }
				});
			};

			prePopulateFilter = function( filter ) {
				if ( filter && filter.length ) {
					hasPreFilters = true;
					$( document ).on( "conditionBuilderInitialized", function(){
						filtersPopulated = true;
						$filterDiv.find( "[name=filter]" ).data( "conditionBuilder" ).load( filter );
						if ( dtApi ) {
							dtApi.draw();
						}
					} );
					$filterDiv.removeClass( "hide" );
					syncAdvancedFilterToggle();
				} else {
					filtersPopulated = true;
					hasPreFilters = false;
				}
			};

			toggleAdvancedFilter = function( e ){
				e && e.preventDefault();
				if ( allowUseFilter ) {
					$filterDiv.toggleClass( "hide" );
					syncAdvancedFilterToggle();
				}
			};

			syncAdvancedFilterToggle = function() {
				var open = !$filterDiv.hasClass( "hide" );
				$toolbar.find( ".advanced-filter-toggle i.fa" )
					.toggleClass( "fa-caret-right", !open )
					.toggleClass( "fa-caret-down", open );
			};

			setupQuickSaveFilterIframeModal = function( $filterDiv ) {
				$filterDiv.on( "click", ".save-filter-btn", function( e ){
					e.preventDefault();

					var iframemodal, rawIframe, dummyPresideObjectPicker
					  , expressionJson      = getMergedFilterExpression()
					  , iframeSrc           = $( this ).data( "saveFormEndpoint" ) + encodeURIComponent( expressionJson )
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
								modal.on("hidden.bs.modal", function() {
									modal.remove();
								} );
							}
						};

					dummyPresideObjectPicker = {
						  addRecordToControl  : function( recordId ){
							$filterDiv.find( "[name=filter]" ).data( "conditionBuilder" ).clear();
							if ( everythingBar ) {
								refreshFavourites( function(){
									everythingBar.setFavourites( [ recordId ] );
									toggleAdvancedFilter();
									redrawTable();
								} );
							} else {
								toggleAdvancedFilter();
								redrawTable();
							}
						  }
						, closeQuickAddDialog : function(){
							iframemodal.close();
							$.gritter.add({
								  title      : i18n.translateResource( "cms:info.notification.title" )
								, text       : i18n.translateResource( "cms:rulesEngine.save.filter.confirmation.message" )
								, class_name : "gritter-success"
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

	$( ".object-listing-table" ).dataListingTable();

} )( presideJQuery );
