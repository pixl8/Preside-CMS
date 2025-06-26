/**
 * @feature        cfflow
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	public string function umlToSvgDiagram( required string uml ) {
		var reader = _getPlantUmlObj( "net.sourceforge.plantuml.SourceStringReader" ).init( arguments.uml );
		var os     = CreateObject( "java", "java.io.ByteArrayOutputStream" );

		try {
			reader.generateImage( os, _getPlantUmlSvgFormat() );
		} finally {
			os.close();
		}

		return ToString( os.toByteArray() );
	}

// PRIVATE HELPERS
	private any function _getPlantUmlObj( className ) {
		return CreateObject( "java", arguments.className, _getPlantUmlLib() );
	}

	private array function _getPlantUmlLib() {
		if ( !StructKeyExists( variables, "_lib" ) ) {
			var libDir = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/lib/plantuml";
			variables._lib = DirectoryList( libDir, false, "path", "*.jar" );
		}

		return _lib;
	}

	private any function _getPlantUmlSvgFormat() {
		var format = _getPlantUmlObj( "net.sourceforge.plantuml.FileFormat" ).SVG;
		return _getPlantUmlObj( "net.sourceforge.plantuml.FileFormatOption" ).init( format );
	}

}