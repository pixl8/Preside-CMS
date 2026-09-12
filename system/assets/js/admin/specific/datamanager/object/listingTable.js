/**
 * Object listing table: DataTables 3 + ColumnControl header filters/colVis,
 * Everything bar for search / saved / segmentation filters.
 * Public plugin remains $.fn.dataListingTable on .object-listing-table.
 */
( function( $ ){

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
			  , listingKey               = tableSettings.listingKey               || object
			  , saveListingColumnsUrl    = tableSettings.saveListingColumnsUrl    || ""
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
			  , columnUiReady = false
			  , saveColumnsTimer
			  , toolbarConfig = {}
			  , filtersPopulated = false
			  , hasPreFilters    = false
			  , hasFilterVal     = $filterDiv.find( "[name=filter]" ).length > 0 && $filterDiv.find( "[name=filter]" ).val().length > 0
			  , setupDatatable, setupCheckboxBehaviour, setupMultiActionButtons, setupTableRowFocusBehaviour
			  , setupFilters, setupDataExport, setupQuickSaveFilterIframeModal, setupEverythingBar, setupHeaderColumnUi
			  , registerListingColumnControlPlugins, searchContentForField, headingContent, expressionsFromColumnControl
			  , columnSearchToExpressions, getVisibleGridFields, saveVisibleColumns, applyDefaultColumnVisibility
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
				  , column   = expressionsFromColumnControl( lastDtRequest )
				  , raw      = $filterDiv.find( "[name=filter]" ).val();

				if ( raw && raw.length ) {
					try { advanced = JSON.parse( raw ); } catch( e ) { advanced = []; }
				}
				if ( !advanced.length ) {
					return column.length ? JSON.stringify( column ) : "";
				}
				if ( !column.length ) {
					return JSON.stringify( advanced );
				}
				return JSON.stringify( advanced.concat( [ "and" ], column ) );
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

			redrawTable = function() {
				if ( dtApi ) {
					dtApi.draw();
				}
			};

			setupEverythingBar = function() {
				if ( !$toolbar.length || typeof PresideEverythingBar === "undefined" ) {
					return;
				}

				everythingBar = new PresideEverythingBar( {
					  $toolbar : $toolbar
					, config   : toolbarConfig
					, onChange : function(){ redrawTable(); }
				} );
			};

			registerListingColumnControlPlugins = function() {
				var DT = window.DataTable
				  , resetLabel, columnsTitle;

				if ( !DT || !DT.ColumnControl ) {
					return;
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

						function render() {
							var html     = []
							  , idxs     = userIndexes()
							  , moveUp   = i18n.translateResource( "cms:datatables.columns.move.up", { defaultValue : "Move up" } )
							  , moveDown = i18n.translateResource( "cms:datatables.columns.move.down", { defaultValue : "Move down" } )
							  , i, idx, col, label, locked, visible;

							for( i=0; i<idxs.length; i++ ) {
								idx     = idxs[ i ];
								col     = dt.column( idx );
								label   = $( "<div>" ).text( $.trim( col.title() ) ).html();
								locked  = $( col.header() ).hasClass( "listing-locked-column" );
								visible = col.visible();

								html.push(
									'<div class="listing-column-row" data-index="' + idx + '">' +
										'<label class="listing-column-label">' +
											'<input type="checkbox" class="listing-column-toggle no-ace"' + ( visible ? ' checked' : '' ) + ( locked ? ' disabled' : '' ) + ' />' +
											'<span>' + label + '</span>' +
										'</label>' +
										'<span class="listing-column-order">' +
											'<button type="button" class="listing-column-move" data-dir="up" title="' + moveUp + '"><i class="fa fa-chevron-up"></i></button>' +
											'<button type="button" class="listing-column-move" data-dir="down" title="' + moveDown + '"><i class="fa fa-chevron-down"></i></button>' +
										'</span>' +
									'</div>'
								);
							}

							$list.html( html.join( "" ) );
							filterRows();
						}

						function filterRows() {
							var q = $.trim( $search.val() ).toLowerCase();
							$list.find( ".listing-column-row" ).each( function() {
								var match = !q.length || $( this ).text().toLowerCase().indexOf( q ) !== -1;
								$( this ).toggleClass( "hide", !match );
							} );
						}

						$wrap.on( "click", ".listing-column-move", function( e ) {
							var from = parseInt( $( this ).closest( ".listing-column-row" ).attr( "data-index" ), 10 )
							  , dir  = $( this ).data( "dir" )
							  , idxs = userIndexes()
							  , pos  = idxs.indexOf( from )
							  , swap = dir === "up" ? pos - 1 : pos + 1;

							e.preventDefault();
							e.stopPropagation();

							if ( pos < 0 || swap < 0 || swap >= idxs.length || !dt.colReorder ) {
								return;
							}

							dt.colReorder.move( from, idxs[ swap ] );
						} );

						$wrap.on( "click", ".listing-column-label, .listing-column-toggle", function( e ) {
							e.stopPropagation();
						} );

						$wrap.on( "change", ".listing-column-toggle", function() {
							var idx = parseInt( $( this ).closest( ".listing-column-row" ).attr( "data-index" ), 10 );
							dt.column( idx ).visible( $( this ).is( ":checked" ) );
						} );

						$search.on( "input", function( e ) {
							e.stopPropagation();
							filterRows();
						} );

						dt.on( "columns-reordered", render );
						render();

						return $wrap.get( 0 );
					}
				};
			};

			searchContentForField = function( field ) {
				var filter = null
				  , options, i;

				if ( !allowFilter ) {
					return [];
				}

				( toolbarConfig.quickFilters || [] ).forEach( function( item ) {
					if ( item.field === field ) {
						filter = item;
					}
				} );

				if ( !filter || filter.type === "object" ) {
					return [];
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

			headingContent = function( extras ) {
				var content = [ "order" ];

				if ( extras && extras.length ) {
					content.push( {
						  extend     : "dropdown"
						, icon       : "search"
						, iconActive : "searchActive"
						, text       : i18n.translateResource( "cms:datatables.filter.btn", { defaultValue : "Filter" } )
						, content    : extras
					} );
				}

				return [ { target : 0, content : content } ];
			};

			columnSearchToExpressions = function( filter, search ) {
				var expressions = []
				  , list        = []
				  , logic, value, i, fields, key, timePeriod, numericOp, stringOp;

				if ( !filter || !filter.expressionId || !search ) {
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

			saveVisibleColumns = function() {
				var fields;

				if ( !allowColumnPicker || !saveListingColumnsUrl || !columnUiReady ) {
					return;
				}

				fields = getVisibleGridFields();
				clearTimeout( saveColumnsTimer );
				saveColumnsTimer = setTimeout( function() {
					$.ajax( {
						  url  : saveListingColumnsUrl
						, type : "POST"
						, data : { object : object, listingKey : listingKey, columns : fields.join( "," ) }
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

			setupHeaderColumnUi = function() {
				if ( !dtApi ) {
					return;
				}

				$listingTable.on( "column-visibility.dt", function() {
					if ( columnUiReady ) {
						saveVisibleColumns();
						dtApi.columns.adjust();
						applyListingFooter();
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
						, data : { object : object, listingKey : listingKey, columns : "" }
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
					fieldName     = $header.data( "field" );
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
						  data           : fieldName
						, name           : fieldName
						, title          : $.trim( $header.text() )
						, defaultContent : ""
						, className      : classNames.join( " " )
						, visible        : $header.data( "visible" ) !== false && $header.data( "visible" ) !== "false"
						, columnControl  : headingContent( searchContent )
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
					  } )
					, createdRow : function( row ){
						var $row = $( row );
						$row.attr( "data-context-container", "1" );
						if( clickableRows ) {
							$row.addClass( "clickable" );
						}
					}
					, initComplete : function(){
						dtApi = this.api ? this.api() : datatable;
						setupEverythingBar();
						setupHeaderColumnUi();
						if ( allowFilter ) {
							setupFilters();
						}
						dtApi.on( "preXhr", function( e, settings, data ) {
							lastDtRequest = data;
							if ( allowFilter ) {
								data.sFilterExpression = getMergedFilterExpression();
							}
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
						if ( !hasPreFilters ) {
							dtApi.draw();
						}
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
							  first    : i18n.translateResource( "cms:datatables.first", { data : [objectTitle], defaultValue : "" } )
							, last     : i18n.translateResource( "cms:datatables.last", { data : [objectTitle], defaultValue : "" } )
							, next     : i18n.translateResource( "cms:datatables.next", { data : [objectTitle], defaultValue : "" } )
							, previous : i18n.translateResource( "cms:datatables.previous", { data : [objectTitle], defaultValue : "" } )
						  }
					  }
					, stateLoadParams : function( settings, data ) {
						delete data.colReorder;
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
						  , raw = window.localStorage.getItem( key )
						  , parsed, migrated;

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
						}
						callback( parsed || false );
					}
					, stateSaveCallback : function( settings, data ) {
						delete data.colReorder;
						window.localStorage.setItem( "DataTables_listing_" + tableId, JSON.stringify( data ) );
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

				if ( typeof filterState !== "undefined" ) {
					if ( allowUseFilter && filterState.filter && filterState.filter.length ) {
						prePopulateFilter( filterState.filter );
					} else {
						filtersPopulated = true;
					}
					if ( everythingBar ) {
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
