/**
 * Service that provides data export logic
 *
 * @singleton      true
 * @autodoc        true
 * @presideservice true
 * @feature        dataExport
 */
component {

// CONSTRUCTOR
	/**
	 * @dataExporterReader.inject              dataExporterReader
	 * @dataExportTemplateService.inject       dataExportTemplateService
	 * @dataManagerCustomizationService.inject dataManagerCustomizationService
	 * @scheduledExportService.inject          scheduledExportService
	 * @defaultDataExportSettings.inject       coldbox:setting:dataExport.defaults
	 */
	public any function init(
		  required any    dataExporterReader
		, required any    dataExportTemplateService
		, required any    dataManagerCustomizationService
		, required any    scheduledExportService
		, required struct defaultDataExportSettings
	) {
		_setExporters( arguments.dataExporterReader.readExportersFromDirectories() );
		_setDataExportTemplateService( arguments.dataExportTemplateService );
		_setDataManagerCustomizationService( arguments.dataManagerCustomizationService );
		_setScheduledExportService( arguments.scheduledExportService );
		_setDefaultDataExportSettings( arguments.defaultDataExportSettings );
		_setupExporterMap();

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Returns export filepath for the given exporter
	 * and arguments.
	 *
	 * @autodoc
	 * exporter.hint           ID of the exporter to use (i.e. csv, excel, etc.)
	 * objectName.hint         Name of the object from which the data is to be exported
	 * meta.hint               Abitrary struct of data that an exporter may use to decorate the export document (e.g. could contain author, timestamp, etc.)
	 * fieldTitles.hint        Struct of field titles where keys are raw field names and values are translated titles for columns
	 * selectFields.hint       Array of select fields that will be selected against the object
	 * exportPagingSize.hint   Number of records to fetch at a time during the export build process. Default is 1000.
	 * recordsetDecorator.hint Closure that accepts a single 'recordset' argument that can be used to add columns to the recordset. Useful when a single query is not enough to populate the export data.
	 */
	public any function exportData(
		  required string  exporter
		, required string  objectName
		,          string  exportTemplate     = "default"
		,          struct  meta               = {}
		,          struct  fieldTitles        = {}
		,          array   selectFields       = []
		,          numeric exportPagingSize   = 1000
		,          any     recordsetDecorator = ""
		,          string  exportFilterString = ""
		,          string  exportFileName     = ""
		,          string  orderBy            = ""
		,          string  mimetype           = ""
		,          struct  templateConfig     = {}
		,          string  historyExportId    = ""
		,          boolean expandNestedFields = false
		,          any     logger
		,          any     progress
	) {
		var exporterHandler      = "dataExporters.#arguments.exporter#.export";
		var coldboxController    = $getColdbox();
		var pageNumber           = 1;
		var canLog               = StructKeyExists( arguments, "logger" );
		var canInfo              = canLog && logger.canInfo();
		var canReportProgress    = StructKeyExists( arguments, "progress" );
		var canTrackRecords      = len( arguments.historyExportId );
		var templateService      = _getDataExportTemplateService();

		if ( !coldboxController.handlerExists( exporterHandler ) ) {
			throw( type="preside.dataExporter.missing.action", message="No 'export' action could be found for the [#arguments.exporter#] exporter. The exporter should provide an 'export' handler action at /handlers/dataExporters/#arguments.exporter#.cfc to process the export. See documentation for further details." );
		}

		arguments.selectFields = templateService.getSelectFields(
			  templateId     = arguments.exportTemplate
			, objectName     = arguments.objectName
			, templateConfig = arguments.templateConfig
			, suppliedFields = arguments.selectFields
		);

		if ( !arguments.selectFields.len() ) {
			arguments.append( getDefaultExportFieldsForObject( arguments.objectName ) );
		}

		$announceInterception( "preDataExportPrepareData", arguments );

		var selectDataArgs            = StructCopy( arguments );
		var cleanedSelectFields       = [];
		var presideObjectService      = $getPresideObjectService();
		var propertyDefinitions       = Duplicate( presideObjectService.getObjectProperties( arguments.objectName ) );
		var propertyRendererMap       = {};
		var templateHasCustomRenderer = templateService.templateMethodExists( arguments.exportTemplate, "renderRecords" );

		selectDataArgs.delete( "exporter" );
		selectDataArgs.delete( "meta" );
		selectDataArgs.delete( "fieldTitles" );
		selectDataArgs.delete( "exportPagingSize" );
		selectDataArgs.delete( "exportFilterString" );
		selectDataArgs.delete( "exportTemplate" );
		selectDataArgs.delete( "templateConfig" );
		selectDataArgs.delete( "expandNestedFields" );
		selectDataArgs.delete( "logger" );
		selectDataArgs.delete( "progress" );
		for( var key in selectDataArgs ) {
			if ( IsObject( selectDataArgs[ key ] ) ) {
				selectDataArgs.delete( key );
			}
		}

		selectDataArgs.maxRows      = arguments.exportPagingSize;
		selectDataArgs.startRow     = 1;
		selectDataArgs.autoGroupBy  = true;
		selectDataArgs.useCache     = false;
		selectDataArgs.selectFields = _expandRelationshipFields( arguments.objectname, selectDataArgs.selectFields, arguments.expandNestedFields );
		selectDataArgs.distinct     = true;
		selectDataArgs.orderBy      = _getOrderBy( arguments.objectName, arguments.orderBy );
		selectDataArgs.extraFilters = selectDataArgs.extraFilters ?: [];
		selectDataArgs.gridFields   = selectDataArgs.gridFields   ?: [];

		if ( len( arguments.exportFilterString ) ) {
			var rc = $getRequestContext().getCollection();
			var keyValues = listToArray( arguments.exportFilterString, "&" );
			for( var keyValue in keyValues ) {
				rc[ listFirst( keyValue, "=" ) ] = listRest( keyValue, "=" );
			}
		}

		_getDataManagerCustomizationService().runCustomization(
			  objectName = arguments.objectName
			, action     = "preFetchRecordsForGridListing"
			, args       = selectDataArgs
		);

		templateService.prepareSelectDataArgs(
			  templateId     = arguments.exportTemplate
			, objectName     = arguments.objectName
			, templateConfig = arguments.templateConfig
			, selectDataArgs = selectDataArgs
		);

		if ( canReportProgress || canLog || canTrackRecords ) {
			var totalRecordsToExport = presideObjectService.selectData(
				  argumentCollection = selectDataArgs
				, recordCountOnly    = true
				, maxRows            = 0
			);
			var totalPagesToExport = Ceiling( totalRecordsToExport / selectDataArgs.maxRows );

			if ( canTrackRecords ) {
				_getScheduledExportService().saveNumberOfRecordsToHistoryExport( totalRecordsToExport, arguments.historyExportId );
			}
		}

		var simpleFormatField = function( required string fieldName, required any value ){
			if ( StructKeyExists( propertyRendererMap, arguments.fieldName ) && propertyRendererMap[ arguments.fieldName ] != "none" ) {
				var renderType = propertyRendererMap[ arguments.fieldName ];

				if ( renderType == "renderer" ) {
					return $renderContent( propertyDefinitions[ arguments.fieldName ].dataExportRenderer, arguments.value, "dataexport" );
				}

				if ( renderType == "boolean" ) {
					return IsBoolean( arguments.value ) ? ( arguments.value ? "true" : "false" ) : "";
				}

				if ( renderType == "date" ) {
					if ( IsDate( arguments.value ) ) {
						return DateFormat( arguments.value, "yyyy-mm-dd" );
					}
					return "";
				}

				if ( renderType == "time" ) {
					if ( IsDate( arguments.value ) ) {
						return TimeFormat( arguments.value, "HH:mm" );
					}
					return "";
				}

				if ( renderType == "datetime" ) {
					if ( IsDate( arguments.value ) ) {
						return DateTimeFormat( arguments.value, "yyyy-mm-dd HH:nn:ss" );
					}
					return "";
				}

				if ( renderType == "enum" ) {
					return $translateResource( uri="enum.#propertyDefinitions[ arguments.fieldName ].enum#:#arguments.value#.label", defaultValue=arguments.value );
				}
			}

			return arguments.value;
		};

		var batchedRecordIterator = function(){
			if ( canReportProgress && progress.isCancelled() ) {
				abort;
			}

			var results = presideObjectService.selectData(
				argumentCollection=selectDataArgs
			);

			_getDataManagerCustomizationService().runCustomization(
				  objectName = selectDataArgs.objectName
				, action     = "postFetchRecordsForGridListing"
				, args       = { records=results, objectName=selectDataArgs.objectName }
			);

			if ( canInfo || canReportProgress ) {
				var currentPage = ( ( selectDataArgs.startRow-1 ) + selectDataArgs.maxRows ) / selectDataArgs.maxRows;
				if ( canInfo ) {
					if ( results.recordCount ) {
						logger.info( "Fetched next [#NumberFormat( results.recordCount )#] of [#NumberFormat( totalRecordsToExport )#] records (page [#NumberFormat( currentPage )#] of [#NumberFormat( totalPagesToExport )#])" );
					} else {
						logger.info( "Completed export" );
					}
				}
				if ( canReportProgress ) {
					if ( results.recordCount ) {
						progress.setProgress( Ceiling( ( 100 / totalPagesToExport ) * currentPage-1 ) );
					} else {
						progress.setProgress( 100 );
					}
				}
			}

			if ( results.recordCount && IsClosure( selectDataArgs.recordsetDecorator ) ) {
				selectDataArgs.recordsetDecorator( results );
			}

			selectDataArgs.startRow += selectDataArgs.maxRows;

			if ( templateHasCustomRenderer ) {
				templateService.renderRecords(
					  templateId     = exportTemplate
					, objectName     = objectName
					, templateConfig = templateConfig
					, records        = results
				);
			} else {
				var columns = ListToArray( results.columnList );
				for( var i=1; i<=results.recordCount; i++ ) {
					for( var field in cleanedSelectFields ) {
						var fieldName = field;
						if ( expandNestedFields && ListLen( fieldName, "." ) > 1 ) {
							fieldName = _nestedFieldName( ListFirst( fieldName, "." ), ListLast( fieldName, "." ) );
						}

						if ( ArrayFindNoCase( columns, fieldName ) ) {
							results[ fieldName ][ i ] = simpleFormatField( fieldName, results[ fieldName ][ i ] );
						}
					}
				}
			}

			return results;
		};


		for( var field in arguments.selectFields ) {
			var fieldName = field.listLast( " " );
			ArrayAppend( cleanedSelectFields, fieldName );

			if ( arguments.expandNestedFields &&
				 ( ListLen( fieldName, "." ) > 1 ) &&
				 !StructKeyExists( propertyDefinitions, fieldName ) &&
				 StructKeyExists( propertyDefinitions, ListFirst( fieldName, "." ) )
			) {
				var relatedObjectName = propertyDefinitions[ ListFirst( fieldName, "." ) ].relatedTo ?: "";

				if ( Len( relatedObjectName ) && presideObjectService.objectExists( objectName=relatedObjectName ) ) {
					propertyDefinitions[ _nestedFieldName( ListFirst( fieldName, "." ), ListLast( fieldName, "." ) ) ] = presideObjectService.getObjectProperty(
						  objectName   = relatedObjectName
						, propertyName = ListLast( fieldName, "." )
					);
				}
			}
		}

		if ( !templateHasCustomRenderer ) {
			for( var field in cleanedSelectFields ) {
				var fieldName = field;
				if ( arguments.expandNestedFields && ListLen( fieldName, "." ) > 1 ) {
					fieldName = _nestedFieldName( ListFirst( fieldName, "." ), ListLast( fieldName, "." ) );
				}

				propertyRendererMap[ fieldName ] = "none";

				if ( StructKeyExists( propertyDefinitions, fieldName ) ) {
					if ( StructKeyExists( propertyDefinitions[ fieldName ], "dataExportRenderer" ) && Len( propertyDefinitions[ fieldName ].dataExportRenderer )  ) {
						propertyRendererMap[ fieldName ] = "renderer";
						continue;
					}

					if ( StructKeyExists( propertyDefinitions[ fieldName ], "type" ) && Len( propertyDefinitions[ fieldName ].type )  ) {
						switch( propertyDefinitions[ fieldName ].type ?: "" ) {
							case "boolean":
								propertyRendererMap[ fieldName ] = "boolean";
								continue;
							case "date":
							case "time":
								switch( propertyDefinitions[ fieldName ].dbtype ?: "" ) {
									case "date":
										propertyRendererMap[ fieldName ] = "date";
										continue;
									case "time":
										propertyRendererMap[ fieldName ] = "time";
										continue;
									default:
										propertyRendererMap[ fieldName ] = "datetime";
										continue;
								}
							case "string":
								if ( Len( Trim( propertyDefinitions[ fieldName ].enum ?: "" ) ) ) {
									propertyRendererMap[ fieldName ] = "enum";
									continue;
								}
								break;
						}
					}
				}
			}
		}

		structAppend( arguments.fieldTitles, templateService.prepareFieldTitles(
			  templateId     = arguments.exportTemplate
			, objectName     = arguments.objectName
			, templateConfig = arguments.templateConfig
			, selectFields   = cleanedSelectFields
		) );
		arguments.fieldTitles = _setDefaultFieldTitles( arguments.objectname, cleanedSelectFields, arguments.fieldTitles, arguments.expandNestedFields );

		$announceInterception( "postDataExportPrepareData", arguments );

		var exportMeta = templateService.getExportMeta(
			  templateId     = arguments.exportTemplate
			, objectName     = arguments.objectName
			, templateConfig = arguments.templateConfig
		);
		StructAppend( exportMeta, arguments.meta, false );

		var result = coldboxController.runEvent(
			  private        = true
			, prepostExempt  = true
			, event          = exporterHandler
			, eventArguments = {
				  selectFields          = cleanedSelectFields
				, fieldTitles           = arguments.fieldTitles
				, meta                  = exportMeta
				, batchedRecordIterator = batchedRecordIterator
				, objectName            = arguments.objectName
				, propertyRendererMap   = propertyRendererMap
			  }
		);

		if ( canReportProgress ) {
			progress.setResult( {
				  exportFileName  = arguments.exportFileName
				, mimetype        = arguments.mimetype
				, filePath        = result
			} );
		}

		return result;
	}

	public struct function getDefaultExportFieldsForObject(
		  required string  objectName
		,          boolean expandNestedRelationField = true
		,          boolean isNested                  = false
	) {
		var titles       = {};
		var poService    = $getPresideObjectService();
		var uriRoot      = poService.getResourceBundleUriRoot( arguments.objectName );
		var defaults     = _getDefaultDataExportSettings();
		var exportFields = poService.getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "dataExportFields"
		).listToArray();

		if ( !exportFields.len() ) {
			var defaultIncludeFields        = ListToArray( poService.getObjectAttribute( objectName=arguments.objectName, attributeName="dataExportDefaultIncludeFields" ) );
			var defaultExcludeFields        = ListToArray( poService.getObjectAttribute( objectName=arguments.objectName, attributeName="dataExportDefaultExcludeFields" ) );
			var defaultFieldsOrder          = poService.getObjectAttribute( objectName=arguments.objectName, attributeName="dataExportDefaultFieldsOrder" );
			var defaultExpandManyToOneField = false;
			var objectAllowExpandFields     = poService.getObjectAttribute( objectName=arguments.objectName, attributeName="dataExportExpandManytoOneFields" );
			    objectAllowExpandFields     = IsBoolean( objectAllowExpandFields ) ? objectAllowExpandFields : defaultExpandManyToOneField;

			var objectProperties = poService.getObjectProperties( arguments.objectName );
			var propertyNames    = StructKeyArray( objectProperties );

			if ( ListLen( defaultFieldsOrder ) ) {
				propertyNames = ListToArray( ListRemoveDuplicates( ListAppend( defaultFieldsOrder, ArrayToList( propertyNames ) ) ) );
			}

			if ( !ArrayLen( defaultExcludeFields ) ) {
				defaultExcludeFields = defaults.excludeFields ?: [];
			}

			for( var propId in propertyNames ) {
				if ( !StructKeyExists( objectProperties, propId ) ) {
					continue;
				}

				var prop = objectProperties[ propId ];

				if ( ArrayFindNoCase( defaultExcludeFields, propId ) || ( IsBoolean( prop.excludeDataExport ?: "" ) && prop.excludeDataExport ) ) {
					continue;
				}

				if ( arguments.isNested && $helpers.isTrue( prop.excludeNestedDataExport ?: "" ) ) {
					continue;
				}

				switch( prop.relationship ?: "" ) {
					case "one-to-many":
					case "many-to-many":
						continue;
					break;
					case "many-to-one":
						if ( arguments.expandNestedRelationField ) {
							var fieldExportDetail = _processRelatedFieldExportDetail( propAttributes=prop, objectAllowExpandFields=objectAllowExpandFields );
							var expandFields      = fieldExportDetail.expandFields;
							var shouldExpand      = fieldExportDetail.shouldExpand;

							if ( shouldExpand ) {
								var linkedFields = getDefaultExportFieldsForObject( objectName=prop.relatedTo, expandNestedRelationField=false, isNested=true );

								if ( ArrayLen( linkedFields.selectFields ?: [] ) ) {
									for ( var field in linkedFields.selectFields ) {
										if ( ArrayLen( expandFields ) && !ArrayFindNoCase( expandFields, field ) ) {
											continue;
										}

										ArrayAppend( exportFields, "#propId#.#field#" );
										titles[ "#propId#.#field#" ] = linkedFields.fieldTitles[ field ] ?: "";
									}

									continue;
								}
							}
						}
					break;
				}

				switch( prop.type ?: "" ) {
					case "string":
						switch( prop.dbType ?: "varchar" ) {
							case "text":
							case "longtext":
							case "mediumtext":
							case "mediumblob":
							case "longblob":
							case "tinyblob":
								continue;
							break;
							case "varchar":
								if ( Val( prop.maxLength ?: "" ) > 800 ) {
									continue;
								}
							break;
						}
					break;
				}

				ArrayAppend( exportFields, propId );
			}
		}


		for( var field in exportFields ) {
			titles[ field ] = titles[ field ] ?: $translateResource( uri=uriRoot & "field.#field#.title", defaultValue=field );
		}

		return {
			  selectFields = exportFields
			, fieldTitles  = titles
		};
	}

	public array function getAllowExportObjectProperties(
		  required string  objectName
		,          boolean expandNestedRelationField = true
		,          boolean isNested                  = false
	) {
		var poService = $getPresideObjectService();
		var fields    = [];
		var props     = poService.getObjectProperties( arguments.objectName );
		var propNames = StructKeyArray( props );

		var defaultIncludeFields        = ListToArray( poService.getObjectAttribute( objectName=arguments.objectName, attributeName="dataExportDefaultIncludeFields" ) );
		var defaultExcludeFields        = ListToArray( poService.getObjectAttribute( objectName=arguments.objectName, attributeName="dataExportDefaultExcludeFields" ) );
		var defaultFieldsOrder          = poService.getObjectAttribute( objectName=arguments.objectName, attributeName="dataExportDefaultFieldsOrder" );
		var defaultExportConfig         = _getDefaultDataExportSettings();
		var defaultExpandManyToOneField = false;
		var objectAllowExpandFields     = poService.getObjectAttribute( objectName=arguments.objectName, attributeName="dataExportExpandManytoOneFields" );
		    objectAllowExpandFields     = IsBoolean( objectAllowExpandFields ) ? $helpers.isTrue( objectAllowExpandFields ) : defaultExpandManyToOneField;

		if ( !ArrayLen( defaultExcludeFields ) ) {
			defaultExcludeFields = defaultExportConfig.excludeFields ?: [];
		}

		if ( ListLen( defaultFieldsOrder ) ) {
			propNames = ListToArray( ListRemoveDuplicates( ListAppend( defaultFieldsOrder, ArrayToList( propNames ) ) ) );
		}

		for ( var prop in propNames ) {
			if ( !StructKeyExists( props, prop ) ) {
				continue;
			}

			var shouldInclude = !ArrayFindNoCase( defaultExcludeFields, prop ) && !$helpers.isTrue( props[ prop ].excludeDataExport ?: "" );
			if ( ArrayLen( defaultIncludeFields ) ) {
				shouldInclude = shouldInclude && ArrayFindNoCase( shouldInclude, prop );
			}

			if ( shouldInclude && arguments.isNested ) {
				shouldInclude = !$helpers.isTrue( props[ prop ].excludeNestedDataExport ?: "" );
			}

			if ( shouldInclude && !( props[ prop ].relationship ?: "" ).reFindNoCase( "to\-many$" ) ) {
				var hasPermission     = true;
				var requiredRoleCheck = StructKeyExists( props[ prop ], "limitToAdminRoles" )
				                     && ( args.context ?: "" ) == "admin"
				                     && !$getAdminLoginService().isSystemUser();

				if ( requiredRoleCheck ) {
					hasPermission = $getAdminPermissionService().userHasAssignedRoles(
						  userId = $getAdminLoginService().getLoggedInUserId()
						, roles  = ListToArray( props[ prop ].limitToAdminRoles )
					);
				}

				if ( hasPermission ) {
					var shouldExpand = arguments.expandNestedRelationField && ( ( props[ prop ].relationship ?: "" ) == "many-to-one" );
					var expandFields = [];

					if ( shouldExpand ) {
						var fieldExportDetail = _processRelatedFieldExportDetail( propAttributes=props[ prop ], objectAllowExpandFields=objectAllowExpandFields );

						shouldExpand = fieldExportDetail.shouldExpand;
						expandFields = fieldExportDetail.expandFields;
					}

					if ( shouldExpand ) {
						var relatedFields   = [];
						var relatedLabels   = [];
						var relatedObjName  = props[ prop ].relatedTo;
						var relatedObjProps = getAllowExportObjectProperties( objectName=relatedObjName, expandNestedRelationField=false, isNested=true );
						var relatedI18nUri  = poService.getResourceBundleUriRoot( objectName=relatedObjName );

						for ( var field in relatedObjProps ) {
							if ( ArrayLen( expandFields ) && !ArrayFindNoCase( expandFields, field ) ) {
								continue;
							}

							ArrayAppend( relatedFields, field );
							ArrayAppend( relatedLabels, $translateResource(
								  uri          = relatedI18nUri & "field.#field#.title"
								, defaultValue = $translateResource( uri="cms:preside-objects.default.field.#field#.title", defaultValue=field )
							) );
						}

						if ( ArrayLen( relatedFields ) ) {
							ArrayAppend( fields, { "#prop#"={ fields=relatedFields, labels=relatedLabels } } );
						} else {
							ArrayAppend( fields, prop );
						}
					} else {
						ArrayAppend( fields, prop );
					}
				}
			}
		}

		return fields;
	}

	/**
	 * Lists all the available exporters as read by the dataExporterReader
	 *
	 * @autodoc
	 */
	public array function listExporters() {
		return _getExporters();
	}

	/**
	 * Returns details of the given exporter (mimetype, title, etc.)
	 *
	 * @autodoc
	 * @exporterId.hint ID of the exporter, e.g. 'excel'
	 */
	public struct function getExporterDetails( required string exporterid ) {
		var exporters = _getExporterMap();

		return exporters[ arguments.exporterid ] ?: {};
	}

	/**
	 * Returns the number of saved exports there are for a given
	 * object.
	 *
	 * @autodoc true
	 * @objectName.hint The name of the object whose saved export count you wish to get.
	 */
	public numeric function getSavedExportCountForObject( required string objectName ) {
		return $getPresideObject( "saved_export" ).selectData(
			  filter          = { object_name = arguments.objectName }
			, selectFields    = [ "1 as record" ]
			, recordCountOnly = true
		);
	}

// PRIVATE HELPERS
	private array function _expandRelationshipFields(
		  required string  objectName
		, required array   selectFields
		,          boolean expandNestedFields = false
	) {
		var props = $getPresideObjectService().getObjectProperties( arguments.objectName );
		var prop  = {};
		var i     = 0;

		for( var field in arguments.selectFields ) {
			var fieldName = arguments.expandNestedFields ? ListFirst( field, "." ) : field;

			i++;
			prop = props[ fieldName ] ?: {};

			switch( prop.relationship ?: "none" ) {
				case "one-to-many":
				case "many-to-many":
					selectFields[ i ] = "'' as " & fieldName;
				break;

				case "many-to-one":
					if ( arguments.expandNestedFields && ListLen( field, "." ) > 1 ) {
						selectFields[ i ] = "#field# as " & _nestedFieldName( fieldName, ListLast( field, "." ) );
					} else {
						selectFields[ i ] = "#fieldName#.${labelfield} as " & fieldName;
					}
				break;
			}
		}

		return arguments.selectFields;
	}

	private struct function _setDefaultFieldTitles(
		  required string  objectName
		, required array   fieldNames
		, required struct  existingTitles
		,          boolean expandNestedFields = false
	) {
		var baseUri = $getPresideObjectService().getResourceBundleUriRoot( arguments.objectName );
		for( var field in arguments.fieldNames ) {
			if ( !StructKeyExists( arguments.existingTitles, field ) ) {
				var fieldKey   = field;
				var fieldName  = ListFirst( field, "." );
				var fieldTitle = $translateResource(
					  uri          = baseUri & "field.#fieldName#.title"
					, defaultValue = $translateResource( uri="cms:preside-objects.default.field.#fieldName#.title", defaultValue=fieldName )
				);

				if ( arguments.expandNestedFields && ListLen( field, "." ) > 1 ) {
					var nestedField       = ListLast( field, "." );
					var relatedObjectName = $getPresideObjectService().getObjectPropertyAttribute( arguments.objectName, fieldName, "relatedTo" );
					    fieldKey          = _nestedFieldName( fieldName, nestedField );

					if ( Len( relatedObjectName ) && $getPresideObjectService().objectExists( relatedObjectName ) ) {
						var nestedFieldTitle = $translateResource(
							  uri          = $getPresideObjectService().getResourceBundleUriRoot( relatedObjectName ) & "field.#nestedField#.title"
							, defaultValue = $translateResource( uri="cms:preside-objects.default.field.#nestedField#.title", defaultValue=nestedField )
						);

						fieldTitle = $translateResource( uri="cms:dataexport.expanded.field.title.default", data=[ fieldTitle, nestedFieldTitle ] );
					}
				}

				arguments.existingTitles[ fieldKey ] = fieldTitle;
			}
		}

		return arguments.existingTitles;
	}

	private string function _getOrderBy( required string objectName, required string orderBy ) {
		var orderElements    = ListToArray( arguments.orderBy );
		var validDirections  = [ "asc", "desc" ];
		var validatedOrderBy = arguments.orderBy;
		var objectProperties = $getPresideObjectService().getObjectProperties( arguments.objectName );

		for( var el in orderElements ) {
			var fieldName         = Trim( ListFirst( el, " " ) );
			var fieldRelationship = objectProperties[fieldName].relationship ?: "";
			var dir               = ListLen( el, " " ) > 1 ? LCase( Trim( ListRest( el, " " ) ) ) : "asc";

			if ( !ArrayFind( validDirections, dir ) ) {
				validatedOrderBy = "";
				break;
			}

			if ( !StructKeyExists( objectProperties, fieldName ) ) {
				validatedOrderBy = "";
				break;
			}

			if( fieldRelationship == "many-to-one" ){
				var fieldRelatedTo = objectProperties[fieldName].relatedto ?: "";
				if( Len( fieldRelatedTo ) ){
					var fieldRelatedToLabel = $getPresideObjectService().getLabelField( fieldRelatedTo );

					if( Len( fieldRelatedToLabel ) ){
						validatedOrderBy = replace( validatedOrderBy, fieldName, "#fieldName#.#fieldRelatedToLabel#" );
					}
				}
			}
		}

		if ( !Len( Trim( validatedOrderBy ) ) ) {
			validatedOrderBy = $getPresideObjectService().getObjectAttribute(
				  objectName    = arguments.objectName
				, attributeName = "dataExportDefaultSortOrder"
			);
		}

		return validatedOrderBy;
	}

	private string function _nestedFieldName( required string objectName, required string fieldName ) {
		return arguments.objectName & "__" & arguments.fieldName;
	}

	private struct function _processRelatedFieldExportDetail(
		  required struct  propAttributes
		,          boolean objectAllowExpandFields = false
	) {
		var processed = {
			  shouldExpand = false
			, expandFields = []
		};

		if ( StructKeyExists( arguments.propAttributes, "dataExportExpandFields" ) ) {

			if ( IsBoolean( arguments.propAttributes.dataExportExpandFields ) ) {
				processed.shouldExpand = arguments.propAttributes.dataExportExpandFields;
			} else if ( ListLen( arguments.propAttributes.dataExportExpandFields ) ) {
				processed.shouldExpand = true;
				processed.expandFields = ListToArray( arguments.propAttributes.dataExportExpandFields );
			}

		} else {
			processed.shouldExpand = arguments.objectAllowExpandFields;
		}

		return processed;
	}

// GETTERS AND SETTERS
	private array function _getExporters() {
		return _exporters;
	}
	private void function _setExporters( required array exporters ) {
		_exporters = arguments.exporters;
	}

	private any function _getDataExportTemplateService() {
	    return _dataExportTemplateService;
	}
	private void function _setDataExportTemplateService( required any dataExportTemplateService ) {
	    _dataExportTemplateService = arguments.dataExportTemplateService;
	}

	private any function _getDataManagerCustomizationService() {
		return _dataManagerCustomizationService;
	}
	private void function _setDataManagerCustomizationService( required any dataManagerCustomizationService ) {
		_dataManagerCustomizationService = arguments.dataManagerCustomizationService;
	}

	private any function _getScheduledExportService() {
		return _scheduledExportService;
	}
	private void function _setScheduledExportService( required any scheduledExportService ) {
		_scheduledExportService = arguments.scheduledExportService;
	}

	private struct function _getDefaultDataExportSettings() {
		return _defaultDataExportSettings;
	}
	private void function _setDefaultDataExportSettings( required struct defaultDataExportSettings ) {
		_defaultDataExportSettings = arguments.defaultDataExportSettings;
	}

	private struct function _getExporterMap() {
		return _exporterMap;
	}
	private void function _setupExporterMap() {
		var exporters = _getExporters();
		_exporterMap = {};

		for( var exporter in exporters ) {
			_exporterMap[ exporter.id ] = exporter;
		}
	}

}
