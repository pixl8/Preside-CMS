component {
	public any function init() {
		_setupYamlParser();

		return this;
	}

	public any function yamlToCfml( required string yaml ) {
		return _getYamlParser().load( arguments.yaml );
	}

// PRIVATE
	private void function _setupYamlParser() {
		var javaLib = [ "../lib/snakeyaml-1.15.jar" ];
		var parser  = CreateObject( "java", "org.yaml.snakeyaml.Yaml", javaLib ).init();

		_setYamlParser( parser );
	}

	private any function _getYamlParser() output=false {
		return _yamlParser;
	}
	private void function _setYamlParser( required any yamlParser ) output=false {
		_yamlParser = arguments.yamlParser;
	}
}