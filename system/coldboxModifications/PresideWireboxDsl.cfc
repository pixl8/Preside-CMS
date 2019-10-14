component implements="coldbox.system.ioc.dsl.IDSLBuilder" {

	public any function init( required any injector ) {
		_setInjector( arguments.injector );

		return this;
	}

	public any function process( required any definition, any targetObject ) {
		var dsl       = ListRest( definition.dsl, ":" );
		var namespace = ListFirst( dsl, ":" );

		switch( namespace ) {
			case "object":
				return _processPresideObjectDsl( ListRest( dsl, ":" ) );
			case "systemsetting":
				return _processSystemSettingDsl( ListRest( dsl, ":" ) );
			case "directories":
				return _processDirectoriesDsl( ListRest( dsl, ":" ) );
			case "dynamicservice":
				return _processDynamicService( ListRest( dsl, ":" ) );
		}

		return "";
	}

// PRIVATE HELPERS
	private any function _processPresideObjectDsl( required string objectName ) {
		return _getInjector().getInstance( "presideObjectService" ).getObject( arguments.objectName );
	}

	private string function _processSystemSettingDsl( required string settingString ) {
		var category = ListFirst( arguments.settingString, "." );
		var setting  = ListLast( arguments.settingString, "." );

		return _getInjector().getInstance( "systemConfigurationService" ).getSetting( category, setting );
	}

	private array function _processDirectoriesDsl( string subDir=""  ) {
		var cb         = _getInjector().getInstance( dsl="coldbox" );
		var extensions = cb.getSetting( name="activeExtensions", defaultValue=[] );
		var appMapping = "/" & cb.getSetting( name="appMapping", defaultValue="app" ).reReplace( "^/", "" );

		if ( !ReFind( "^/", subDir ) ) {
			subDir = "/" & subDir;
		}

		var directories = [ "/preside/system#subDir#" ];

		for( var extension in extensions ){
			directories.append( extension.directory & subDir );
		}

		directories.append( appMapping & subDir );

		for( var extension in extensions ){
			for( var dir in _findSiteTemplateDirectories( extension.directory, subDir ) ){
				directories.append( dir );
			}
		}
		for( var dir in _findSiteTemplateDirectories( appMapping, subDir ) ){
			directories.append( dir );
		}

		return directories;
	}

	private array function _findSiteTemplateDirectories( required string parentDir, required string subDir ) {
		var dirs             = [];
		var siteTemplatesDir = arguments.parentDir & "/site-templates";

		if ( DirectoryExists( siteTemplatesDir ) ) {
			for( var dir in DirectoryList( siteTemplatesDir, false, "query" ) ) {
				if ( dir.type == "dir" ) {
					var fullDir = siteTemplatesDir & "/#dir.name##arguments.subDir#";
					if ( DirectoryExists( fullDir ) ) {
						dirs.append( fullDir );
					}
				}
			}
		}

		return dirs;
	}

	private any function _processDynamicService( required string serviceName ) {
		var cb       = _getInjector().getInstance( dsl="coldbox" );
		var services = cb.getSetting( name="presideservices", default={} );

		if ( StructKeyExists( services, arguments.serviceName ) ) {
			if ( IsSimpleValue( services[ arguments.serviceName ] ) ) {
				return _getInjector().getInstance( services[ arguments.serviceName ] );
			} else {
				return _getInjector().getInstance( argumentCollection=services[ arguments.serviceName ] );
			}
		}

		throw( type="preside.missing.service", message="The service, [#arguments.serviceName#], does not exist. This error was caused by a wirebox injection using DSL: [presidecms:dynamicservice:#serviceName#]." );
	}


// GETTERS AND SETTERS
	private any function _getInjector() {
		return _injector;
	}
	private void function _setInjector( required any injector ) {
		_injector = arguments.injector;
	}

}