/**
 * @singleton      true
 * @autodoc        true
 * @presideservice true
 *
 * Service that discovers and reads available data exporters within a Preside application
 */
component {

// CONSTRUCTOR
	/**
	 * @exporterDirectories.inject presidecms:directories:handlers/dataExporters
	 *
	 */
	public any function init( required array exporterDirectories ) {
		_setExporterDirectories( arguments.exporterDirectories );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Reads exporters from all the preside handlers/dataexporters
	 * directories in an application. Returns an array of exporter
	 * definitions, ordered by title.
	 *
	 * @autodoc true
	 */
	public array function readExportersFromDirectories() {
		var rawExporters   = {};
		var finalExporters = [];

		for( var dir in _getExporterDirectories() ) {
			var mappingBase  = dir.reReplace( "^/", "" ).reReplace( "/$", "" ).replace( "/", ".", "all" );
			var handlerFiles = DirectoryList( dir, false, "name", "*.cfc" );

			for( var handlerFile in handlerFiles ) {
				var handlerMapping = mappingBase & "." & handlerFile.reReplace( "\.cfc$", "" );
				var metaData       = getComponentMetadata( handlerMapping );
				var exporter       = readExporterFromCfcMetadata( metaData );

				rawExporters[ exporter.id ] = rawExporters[ exporter.id ] ?: {};
				rawExporters[ exporter.id ].append( exporter );
			}
		}

		for( var exporterId in rawExporters ) {
			finalExporters.append( rawExporters[ exporterId ] );
		}

		finalExporters.sort( function( a, b ){
			return a.title > b.title ? 1 : -1;
		} );

		return finalExporters;
	}

	/**
	 * Reads exporter information from the metadata
	 * of an exporter handler CFC
	 *
	 * @autodoc       true
	 * @metadata.hint Metadata of the CFC to be read
	 */
	public struct function readExporterFromCfcMetadata( required struct metaData ) {
		var exporter = {
			id = ListLast( arguments.metaData.name ?: "", "." )
		};

		if ( !Len( Trim( arguments.metaData.exportFileExtension ?: "" ) ) ) {
			throw( type="preside.dataExporter.missing.param", message="The data exporter [#( arguments.metaData.name ?: '' )#] does not define a file extension for exported files. All exporters must define an extension with the @exportFileExtension attribute on the CFC file (see documentation for further details)." );
		}
		if ( !Len( Trim( arguments.metaData.exportMimeType ?: "" ) ) ) {
			throw( type="preside.dataExporter.missing.param", message="The data exporter [#( arguments.metaData.name ?: '' )#] does not define an export file mimetype. All exporters must define an export mime type with the @exportMimeType attribute on the CFC file (see documentation for further details)." );
		}

		exporter.fileExtension = arguments.metaData.exportFileExtension;
		exporter.mimeType      = arguments.metaData.exportMimeType;

		exporter.title       = $translateResource( uri="dataexporters.#exporter.id#:title"      , defaultValue=exporter.id   );
		exporter.description = $translateResource( uri="dataexporters.#exporter.id#:description", defaultValue=""            );
		exporter.iconClass   = $translateResource( uri="dataexporters.#exporter.id#:iconClass"  , defaultValue="fa-download" );

		return exporter;
	}

// PRIVATE HELPERS

// GETTERS AND SETTERS
	private array function _getExporterDirectories() {
		return _exporterDirectories;
	}
	private void function _setExporterDirectories( required array exporterDirectories ) {
		_exporterDirectories = arguments.exporterDirectories;
	}

}