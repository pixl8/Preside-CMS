component extends="preside.system.base.AdminHandler" output=false {

	property name="updateManagerService" inject="updateManagerService";	
	property name="DbInfoService"        inject="DbInfoService";

//public handlers
	public void function preHandler( event ) {		
		super.preHandler( argumentCollection = arguments );		
		_checkPermissions( event=event, key="navigate" );

		prc.pageIcon = "fa-info-circle";
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:systemInformation.menu.title" )
			, link  = event.buildAdminLink( linkTo="SystemInformation" )
		);
	}

	public void function index( event, rc, prc ) {
		var dbresult           = DbInfoService.getDatabaseVersion( getSetting('dsn') );
		var productName        = server.coldfusion.productname    ?: "";
		var productVersion     = server.coldfusion.productversion ?: "";
		var javaVersion        = server.java.version              ?: "";
		var osName             = server.os.name                   ?: "";
		var osVersion          = server.os.version                ?: "";
		var databaseName       = dbresult.database_productname    ?: "";
		var databaseVersion    = dbresult.database_version        ?: "";

		prc.pageTitle          = translateResource( "cms:systemInformation.menu.title" );
		prc.downloadedVersions = updateManagerService.listDownloadedVersions();
		prc.applicationServer  = productName & '(' & productVersion & ')';
		prc.java               = javaVersion;
		prc.os                 = osName & ' (' & osVersion & ')';
		prc.dataBase           = databaseName & ' (' & databaseVersion & ')';
		
	}
// private utility
	private void function _checkPermissions( required any event, required string key ) {

		if ( !hasCmsPermission( "systemInformation." & arguments.key ) ) {
			event.adminAccessDenied();
		}
	}

}