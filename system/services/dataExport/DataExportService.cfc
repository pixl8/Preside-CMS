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

		if ( !arguments.selectFields.len() ) {
			arguments.append( getDefaultExportFieldsForObject( arguments.objectName ) );
		}

		var selectDataArgs       = Duplicate( arguments );
		var presideObjectService = $getPresideObjectService();

		selectDataArgs.delete( "exporter" );
		selectDataArgs.delete( "meta" );
		selectDataArgs.delete( "fieldTitles" );
		selectDataArgs.delete( "exportPagingSize" );
		selectDataArgs.maxRows  = arguments.exportPagingSize;
		selectDataArgs.startRow = 1;

		var batchedRecordIterator = function(){
			var results = presideObjectService.selectData(
				argumentCollection=selectDataArgs
			);

			selectDataArgs.startRow += selectDataArgs.maxRows;

			return results;
		};

		if ( coldboxController.handlerExists( exporterHandler ) ) {
			return coldboxController.runEvent(
				  private        = true
				, prepostExempt  = true
				, event          = exporterHandler
				, eventArguments = {
					  selectFields          = arguments.selectFields
					, fieldTitles           = arguments.fieldTitles
					, meta                  = arguments.meta
					, batchedRecordIterator = batchedRecordIterator
				  }
			);
		}

		return "";
	}

	public struct function getDefaultExportFieldsForObject( required string objectName ) {
		var titles       = {};
		var uriRoot      = $getPresideObjectService().getResourceBundleUriRoot( arguments.objectName );
		var exportFields = $getPresideObjectService().getObjectAttribute(
			  objectName = arguments.objectName
			, attribute  = "dataExportFieldList"
		).listToArray();

		if ( !exportFields.len() ) {
			var objectProperties = $getPresideObjectService().getObjectProperties( arguments.objectName );

			for( var propId in objectProperties ) {
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