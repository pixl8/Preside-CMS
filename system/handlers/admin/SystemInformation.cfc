component extends="preside.system.base.AdminHandler" {

	property name="updateManagerService"    inject="updateManagerService";
	property name="DbInfoService"           inject="DbInfoService";
	property name="extensionManagerService" inject="extensionManagerService";
	property name="hearbeatExecutor"        inject="presideScheduledThreadpoolExecutor";
	property name="healthCheckService"      inject="healthCheckService";

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
		var tab = rc.tab ?: "";
		var tabs = [ "general", "extensions", "healthchecks", "heartbeats" ];

		if ( !tabs.findNoCase( tab ) ) {
			tab = tabs[ 1 ];
		}

		prc.renderedTab = renderViewlet( event="admin.systemInformation._#tab#Tab", args={} );

		prc.pageTitle = translateResource( "cms:systemInformation.menu.title" );
		prc.tabs = [];

		for( var theTab in tabs ) {
			prc.tabs.append({
				  active    = theTab == tab
				, link      = event.buildAdminLink( linkto="systemInformation", queryString="tab=#theTab#" )
				, title     = translateResource( "cms:systemInformation.tab.#theTab#.title" )
				, iconClass = translateResource( "cms:systemInformation.tab.#theTab#.iconClass" )
			});
		}
	}

// viewlets
	private string function _generalTab( event, rc, prc, args={} ) {
		var dbresult           = DbInfoService.getDatabaseVersion( getSetting('dsn') );
		var javaVersion        = server.java.version              ?: "";
		var osName             = server.os.name                   ?: "";
		var osVersion          = server.os.version                ?: "";
		var databaseName       = dbresult.database_productname    ?: "";
		var databaseVersion    = dbresult.database_version        ?: "";
		var productName        = server.coldfusion.productname    ?: "";
		var productVersion     = _getProductVersion();


		args.presideCmsVersion  = updateManagerService.getCurrentVersion();
		args.applicationServer  = productName & ' (' & productVersion & ')';
		args.java               = javaVersion;
		args.os                 = osName & ' (' & osVersion & ')';
		args.dataBase           = databaseName & ' (' & databaseVersion & ')';

		return renderView( view="/admin/systemInformation/_generalTab", args=args );
	}

	private string function _extensionsTab( event, rc, prc, args={} ) {
		args.extensions = extensionManagerService.listExtensions();
		return renderView( view="/admin/systemInformation/_extensionsTab", args=args );
	}

	private string function _healthChecksTab( event, rc, prc, args={} ) {
		args.healthChecks = healthCheckService.getAllStatuses();
		return renderView( view="/admin/systemInformation/_healthChecksTab", args=args );
	}

	private string function _heartbeatsTab( event, rc, prc, args={} ) {
		args.heartbeats = hearbeatExecutor.getTaskStatuses();
		return renderView( view="/admin/systemInformation/_heartbeatsTab", args=args );
	}

// private utility
	private void function _checkPermissions( required any event, required string key ) {

		if ( !hasCmsPermission( "systemInformation." & arguments.key ) ) {
			event.adminAccessDenied();
		}
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