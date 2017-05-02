/**
 * @singleton      true
 * @autodoc        true
 * @presideservice true
 *
 * Service that discovers and reads available data exporters within a Preside application
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
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

		exporter.title       = $translateResource( uri="dataexporter.#exporter.id#:title"      , defaultValue=exporter.id   );
		exporter.description = $translateResource( uri="dataexporter.#exporter.id#:description", defaultValue=""            );
		exporter.iconClass   = $translateResource( uri="dataexporter.#exporter.id#:iconClass"  , defaultValue="fa-download" );

		return exporter;
	}

// PRIVATE HELPERS

// GETTERS AND SETTERS

}