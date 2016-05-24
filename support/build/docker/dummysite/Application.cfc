component {

	public any function onRequest( required string requestedTemplate ) {
		var systemInfo = {
			  javaVersion    = server.java.version           ?: ""
			, osName         = server.os.name                ?: ""
			, osVersion      = server.os.version             ?: ""
			, productName    = server.coldfusion.productname ?: ""
			, productVersion = server.lucee.version          ?: ""
			, presideVersion = _getPresideVersion()
		};

		include template=arguments.requestedTemplate;
	}

	private string function _getPresideVersion() {
		var versionFile = ExpandPath( "/preside/version.json" );
		var versionInfo = "";

		if ( !FileExists( versionFile ) ) {
			return "unknown";
		}

		try {
			versionInfo = DeSerializeJson( FileRead( versionFile ) );
		} catch ( any e ) {
			return "unknown";
		}

		return versionInfo.version ?: "unknown";
	}
}
