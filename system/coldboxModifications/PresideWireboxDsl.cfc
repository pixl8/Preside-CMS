component implements="coldbox.system.ioc.dsl.IDSLBuilder" output=false {

	public any function init( required any injector ) output=false {
		_setInjector( arguments.injector );

		return this;
	}

	public any function process( required any definition, any targetObject ) output=false {
		var dsl       = ListRest( definition.dsl, ":" );
		var namespace = ListFirst( dsl, ":" );

		switch( namespace ) {
			case "systemsetting":
				return _processSystemSettingDsl( ListRest( dsl, ":" ) );
		}

		return "";
	}

// PRIVATE HELPERS
	private string function _processSystemSettingDsl( required string settingString ) output=false {
		var category = ListFirst( arguments.settingString, "." );
		var setting  = ListLast( arguments.settingString, "." );

		return _getInjector().getInstance( "systemConfigurationService" ).getSetting( category, setting );
	}

// GETTERS AND SETTERS
	private any function _getInjector() output=false {
		return _injector;
	}
	private void function _setInjector( required any injector ) output=false {
		_injector = arguments.injector;
	}

}