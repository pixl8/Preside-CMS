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
	 * Returns export file content for the given exporter
	 * and arguments.
	 *
	 * @autodoc
	 */
	public any function exportData(
		  required string  exporter
		, required string  objectName
		,          struct  meta             = {}
		,          struct  fieldTitles      = {}
		,          array   selectFields     = []
		,          numeric exportPagingSize = 1000
	) {
		var exporterHandler      = "dataExporters.#arguments.exporter#.export";
		var coldboxController    = $getColdbox();
		var pageNumber           = 1;

		if ( !coldboxController.handlerExists( exporterHandler ) ) {
			throw( type="preside.dataExporter.missing.action", message="No 'export' action could be found for the [#arguments.exporter#] exporter. The exporter should provide an 'export' handler action at /handlers/dataExporters/#arguments.exporter#.cfc to process the export. See documentation for further details." );
		}

		if ( !arguments.selectFields.len() ) {
			arguments.append( getDefaultExportFieldsForObject( arguments.objectName ) );
		}

		var selectDataArgs       = Duplicate( arguments );
		var presideObjectService = $getPresideObjectService();

		selectDataArgs.delete( "exporter" );
		selectDataArgs.delete( "meta" );
		selectDataArgs.delete( "fieldTitles" );
		selectDataArgs.delete( "exportPagingSize" );
		selectDataArgs.maxRows   = arguments.exportPagingSize;
		selectDataArgs.startRow  = 1;
		selectDataArgs.autoGroup = true;
		selectDataArgs.useCache  = false;
		selectDataArgs.selectFields = _expandRelationshipFields( arguments.objectname, selectDataArgs.selectFields );

		var batchedRecordIterator = function(){
			var results = presideObjectService.selectData(
				argumentCollection=selectDataArgs
			);

			selectDataArgs.startRow += selectDataArgs.maxRows;

			return results;
		};

		var cleanedSelectFields  = [];
		for( var field in arguments.selectFields ) {
			cleanedSelectFields.append( field.listLast( " " ) );
		}

		return coldboxController.runEvent(
			  private        = true
			, prepostExempt  = true
			, event          = exporterHandler
			, eventArguments = {
				  selectFields          = cleanedSelectFields
				, fieldTitles           = arguments.fieldTitles
				, meta                  = arguments.meta
				, batchedRecordIterator = batchedRecordIterator
			  }
		);
	}

	public struct function getDefaultExportFieldsForObject( required string objectName ) {
		var titles       = {};
		var uriRoot      = $getPresideObjectService().getResourceBundleUriRoot( arguments.objectName );
		var exportFields = $getPresideObjectService().getObjectAttribute(
			  objectName    = arguments.objectName
			, attributeName = "dataExportFieldList"
		).listToArray();

		if ( !exportFields.len() ) {
			var objectProperties = $getPresideObjectService().getObjectProperties( arguments.objectName );
			var propertyNames    = $getPresideObjectService().getObjectAttribute(
				  objectName    = arguments.objectName
				, attributeName = "propertyNames"
			);

			for( var propId in propertyNames ) {
				var prop = objectProperties[ propId ];

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
								continue;
							break;
							case "varchar":
								if ( Val( prop.maxLength ?: "" ) > 200 ) {
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
		var i     = 0;

		for( var field in arguments.selectFields ) {
			i++;

			if ( ( props[ field ].relationship ?: "" ) == "many-to-one" ) {
				arguments.selectFields[ i ] = "#field#.${labelfield} as #field#";
			}
		}

		return arguments.selectFields;
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