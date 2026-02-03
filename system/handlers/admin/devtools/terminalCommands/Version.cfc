component hint="Display system version information" extends="preside.system.base.Command" {

	property name="updateManagerService" inject="UpdateManagerService";
	property name="dbInfoService"        inject="DbInfoService";


	private function index( event, rc, prc ) {
		var dbresult           = DbInfoService.getDatabaseVersion( getSetting('dsn') );
		var javaVersion        = server.java.version              ?: "";
		var osName             = server.os.name                   ?: "";
		var osVersion          = server.os.version                ?: "";
		var databaseName       = dbresult.database_productname    ?: "";
		var databaseVersion    = dbresult.database_version        ?: "";
		var productName        = server.coldfusion.productname    ?: "";
		var productVersion     = _getProductVersion();

		var headers  = [ "Service", "Version" ];
		var versions = [
			  [ translateResource( uri="cms:systemInformation.cms.th" )              , updateManagerService.getCurrentVersionAndBuildDate() ]
			, [ translateResource( uri="cms:systemInformation.applicationServer.th" ), productName & ' (' & productVersion & ')' ]
			, [ translateResource( uri="cms:systemInformation.dataBase.th" )         , databaseName & ' (' & databaseVersion & ')' ]
			, [ translateResource( uri="cms:systemInformation.java.th" )             , javaVersion ]
			, [ translateResource( uri="cms:systemInformation.os.th" )               , osName & ' (' & osVersion & ')' ]
		];

		announceInterception( "postPrepareDevToolsVersions", { versions=versions } );

		return NewLine() & writeTable( headers, versions );
	}


	private string function _getProductVersion() {
		switch( server.coldfusion.productName ) {
			case "lucee":
			case "railo":
				return server[ server.coldfusion.productName ].version ?: "unknown";
		}

		return server.coldfusion.productVersion;
	}

}