component implements="coldbox.system.ioc.dsl.IDSLBuilder" output=false {

	public any function init( required any injector ) output=false {
		_setInjector( arguments.injector );

		return this;
	}

	public any function process( required any definition, any targetObject ) output=false {
		var dsl       = ListRest( definition.dsl, ":" );
		var namespace = ListFirst( dsl, ":" );

		switch( namespace ) {
			case "object":
				return _processPresideObjectDsl( ListRest( dsl, ":" ) );
			case "systemsetting":
				return _processSystemSettingDsl( ListRest( dsl, ":" ) );
			case "directories":
				return _processDirectoriesDsl( ListRest( dsl, ":" ) );
		}

		return "";
	}

// PRIVATE HELPERS
	private any function _processPresideObjectDsl( required string objectName ) output=false {
		return _getInjector().getInstance( "presideObjectService" ).getObject( arguments.objectName );
	}

	private string function _processSystemSettingDsl( required string settingString ) output=false {
		var category = ListFirst( arguments.settingString, "." );
		var setting  = ListLast( arguments.settingString, "." );

		return _getInjector().getInstance( "systemConfigurationService" ).getSetting( category, setting );
	}

	private array function _processDirectoriesDsl( string subDir=""  ) output=false {
		var cb         = _getInjector().getInstance( dsl="coldbox" );
		var extensions = cb.getSetting( name="activeExtensions", defaultValue=[]     );
		var appMapping = cb.getSetting( name="appMapping"      , defaultValue="/app" );

		if ( !ReFind( "^/", subDir ) ) {
			subDir = "/" & subDir;
		}

		var directories = [ "/preside/system#subDir#" ];

		for( var i=extensions.len(); i > 0; i-- ){
			directories.append( extensions[i].directory & subDir );
		}

		directories.append( appMapping & subDir );

		for( var i=extensions.len(); i > 0; i-- ){
			for( var dir in _findSiteTemplateDirectories( extensions[i].directory, subDir ) ){
				directories.append( dir );
			}
		}
		for( var dir in _findSiteTemplateDirectories( appMapping, subDir ) ){
			directories.append( dir );
		}

		return directories;
	}

	private array function _findSiteTemplateDirectories( required string parentDir, required string subDir ) output=false {
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


// GETTERS AND SETTERS
	private any function _getInjector() output=false {
		return _injector;
	}
	private void function _setInjector( required any injector ) output=false {
		_injector = arguments.injector;
	}

}