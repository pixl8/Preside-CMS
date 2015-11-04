/**
 * The document metadata service provides methods for extracting metadata from documents such as PDFs and word documents.
 * Its purpose in the context of PresideCMS is for metadata and content extraction from uploaded documents.
 * \n
 * In its current form, only the extraction of image EXIF metadata is supported. Extensions such as the Tika extension
 * can override/extend this service to provide full functionality.
 *
 * @singleton true
 * @autodoc   true
 */
component displayName="Document metadata service" {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	/**
	 * This method returns any metadata as a cfml structure. This is currently only supported
	 * natively for images. For full support see Pixl8s Apache Tika extension.
	 *
	 * @fileContent.hint Binary content of the file for which you want to extract meta data
	 * @autodoc true
	 */
	public struct function getMetaData( required any fileContent ) {
		var result = _parse( fileContent = arguments.fileContent, includeText = false );

		return result.metadata ?: {};
	}

	/**
	 * This method returns raw text read from the document, useful for populating search engines, etc.
	 * This method is currently unsupported in the core PresideCMS platform and must be supported
	 * through Apache Tika extension or similar.
	 *
	 * @fileContent.hint Binary content of the file for which you want to extract meta data
	 * @autodoc true
	 */
	public string function getText( required any fileContent ) {
		var result = _parse( fileContent = arguments.fileContent, includeMeta=false );

		return result.text ?: "";
	}

// PRIVATE HELPERS
	private struct function _parse( required any fileContent, boolean includeMeta=true, boolean includeText=true ) {
		var result  = {};

		if ( arguments.includeMeta ) {
			try {
				var img  = ImageReadBase64( ToBase64( arguments.fileContent ) );

				return { metadata = ImageGetEXIFMetadata( img ) };
			} catch( any e ) {}
		}

		return {};
	}
}