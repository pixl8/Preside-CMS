/**
 * @singleton      true
 * @autodoc        true
 * @presideservice true
 *
 * Service that provides data export logic
 */
component {

// CONSTRUCTOR
	/**
	 * @dataExporterReader.inject dataExporterReader
	 *
	 */
	public any function init( required any dataExporterReader ) {
		_setExporters( arguments.dataExporterReader.readExportersFromDirectories() );
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
		,          struct  meta               = {}
		,          struct  fieldTitles        = {}
		,          array   selectFields       = []
		,          numeric exportPagingSize   = 1000
		,          any     recordsetDecorator = ""
		,          string  exportFileName     = ""
		,          string  orderBy            = ""
		,          string  mimetype           = ""
		,          any     logger
		,          any     progress
	) {
		var exporterHandler      = "dataExporters.#arguments.exporter#.export";
		var coldboxController    = $getColdbox();
		var pageNumber           = 1;
		var canLog               = StructKeyExists( arguments, "logger" );
		var canInfo              = canLog && logger.canInfo();
		var canReportProgress    = StructKeyExists( arguments, "progress" );

		if ( !coldboxController.handlerExists( exporterHandler ) ) {
			throw( type="preside.dataExporter.missing.action", message="No 'export' action could be found for the [#arguments.exporter#] exporter. The exporter should provide an 'export' handler action at /handlers/dataExporters/#arguments.exporter#.cfc to process the export. See documentation for further details." );
		}

		if ( !arguments.selectFields.len() ) {
			arguments.append( getDefaultExportFieldsForObject( arguments.objectName ) );
		}

		$announceInterception( "preDataExportPrepareData", arguments );

		var selectDataArgs       = Duplicate( arguments );
		var cleanedSelectFields  = [];
		var presideObjectService = $getPresideObjectService();
		var propertyDefinitions  = presideObjectService.getObjectProperties( arguments.objectName );

		selectDataArgs.delete( "exporter" );
		selectDataArgs.delete( "meta" );
		selectDataArgs.delete( "fieldTitles" );
		selectDataArgs.delete( "exportPagingSize" );
		selectDataArgs.maxRows     = arguments.exportPagingSize;
		selectDataArgs.startRow    = 1;
		selectDataArgs.autoGroupBy = true;
		selectDataArgs.useCache    = false;
		selectDataArgs.selectFields = _expandRelationshipFields( arguments.objectname, selectDataArgs.selectFields );
		selectDataArgs.distinct     = true;
		selectDataArgs.orderBy      = _getOrderBy( arguments.objectName, arguments.orderBy );

		if ( canReportProgress || canLog ) {
			var totalRecordsToExport = presideObjectService.selectData(
				  argumentCollection = selectDataArgs
				, recordCountOnly    = true
				, maxRows            = 0
			);
			var totalPagesToExport = Ceiling( totalRecordsToExport / selectDataArgs.maxRows );
		}

		var simpleFormatField = function( required string fieldName, required any value ){
			var dataExportRenderer = Trim( propertyDefinitions[ arguments.fieldName ].dataExportRenderer ?: "" );
			if ( dataExportRenderer.len() ) {
				return $renderContent( dataExportRenderer, arguments.value, "dataexport" );
			}

			switch( propertyDefinitions[ arguments.fieldName ].type ?: "" ) {
				case "boolean":
					return IsBoolean( arguments.value ) ? ( arguments.value ? "true" : "false" ) : "";
				case "date":
				case "time":
					if ( !IsDate( arguments.value ) ) {
						return "";
					}

					switch( propertyDefinitions[ arguments.fieldName ].dbtype ?: "" ) {
						case "date":
							return DateFormat( arguments.value, "yyyy-mm-dd" );
						case "time":
							return TimeFormat( arguments.value, "HH:mm" );
						default:
							return DateTimeFormat( arguments.value, "yyyy-mm-dd HH:nn:ss" );
					}
			}

			return value;
		};

		var batchedRecordIterator = function(){
			if ( canReportProgress && progress.isCancelled() ) {
				abort;
			}

			var results = presideObjectService.selectData(
				argumentCollection=selectDataArgs
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

			for( var i=1; i<=results.recordCount; i++ ) {
				for( var field in cleanedSelectFields ) {
					if ( ListFindNoCase( results.columnList, field ) ) {
						results[ field ][ i ] = simpleFormatField( field, results[ field ][ i ] );
					}
				}
			}

			return results;
		};


		for( var field in arguments.selectFields ) {
			cleanedSelectFields.append( field.listLast( " " ) );
		}
		arguments.fieldTitles = _setDefaultFieldTitles( arguments.objectname, cleanedSelectFields, arguments.fieldTitles );

		$announceInterception( "postDataExportPrepareData", arguments );

		var result = coldboxController.runEvent(
			  private        = true
			, prepostExempt  = true
			, event          = exporterHandler
			, eventArguments = {
				  selectFields          = cleanedSelectFields
				, fieldTitles           = arguments.fieldTitles
				, meta                  = arguments.meta
				, batchedRecordIterator = batchedRecordIterator
				, objectName            = arguments.objectName
			  }
		);

		if ( canReportProgress ) {
			progress.setResult( {
				  exportFileName = arguments.exportFileName
				, mimetype       = arguments.mimetype
				, filePath       = result
			} );
		}

		return result;
	}

	public struct function getDefaultExportFieldsForObject( required string objectName ) {
		var titles       = {};
		var uriRoot      = $getPresideObjectService().getResourceBundleUriRoot( arguments.objectName );
		var exportFields = $getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "dataExportFields"
		).listToArray();

		if ( !exportFields.len() ) {
			var objectProperties = $getPresideObjectService().getObjectProperties( arguments.objectName );
			var propertyNames    = $getPresideObjectService().getObjectAttribute(
				  objectName    = arguments.objectName
				, attributeName = "propertyNames"
			);

			for( var propId in propertyNames ) {
				var prop = objectProperties[ propId ];

				if ( IsBoolean( prop.excludeDataExport ?: "" ) && prop.excludeDataExport ) {
					continue;
				}

				switch( prop.relationship ?: "" ) {
					case "one-to-many":
					case "many-to-many":
						continue;
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

				exportFields.append( propId );
			}
		}


		for( var field in exportFields ) {
			titles[ field ] = $translateResource( uri=uriRoot & "field.#field#.title", defaultValue=field );
		}

		return {
			  selectFields = exportFields
			, fieldTitles  = titles
		};
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

// PRIVATE HELPERS
	private array function _expandRelationshipFields(
		  required string objectName
		, required array  selectFields
	) {
		var props = $getPresideObjectService().getObjectProperties( arguments.objectName );
		var prop  = {};
		var i     = 0;

		for( var field in arguments.selectFields ) {
			i++;
			prop = props[ field ] ?: {};

			switch( prop.relationship ?: "none" ) {
				case "one-to-many":
				case "many-to-many":
					selectFields[ i ] = "'' as " & field;
				break;

				case "many-to-one":
					selectFields[ i ] = "#field#.${labelfield} as " & field;
				break;
			}
		}

		return arguments.selectFields;
	}

	private struct function _setDefaultFieldTitles(
		  required string objectName
		, required array  fieldNames
		, required struct existingTitles
	) {
		var baseUri = $getPresideObjectService().getResourceBundleUriRoot( arguments.objectName );
		for( var field in arguments.fieldNames ) {
			arguments.existingTitles[ field ] = arguments.existingTitles[ field ] ?: $translateResource(
				  uri          = baseUri & "field.#field#.title"
				, defaultValue = field
			);
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

// GETTERS AND SETTERS
	private array function _getExporters() {
		return _exporters;
	}
	private void function _setExporters( required array exporters ) {
		_exporters = arguments.exporters;
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
