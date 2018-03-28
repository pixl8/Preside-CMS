component {

	function init( required any injector ) {
		variables.injector = arguments.injector;

		// Create a ColdBox DSL builder to proxy everything else to
		variables.coldboxDSL = createObject("component","coldbox.system.ioc.dsl.ColdBoxDSL").init( arguments.injector );
		return this;
	}

	function process( required any definition, targetObject ) {
		var dsl = arguments.definition.dsl;

		if( reFindNoCase( '^coldbox:myplugin:.*', dsl ) ) {
			var plugin = ListLast( dsl, ":" );
			switch( plugin ) {
				case "JQueryDatatablesHelpers":
				case "jsonRpc2":
					return injector.getInstance( plugin );
			}
		// intercept the coldbox:myplugin namespace
		} else if( reFindNoCase( '^coldbox:plugin:.*', dsl ) ) {
			var plugin = ListLast( dsl, ":" );
			switch( plugin ) {
				case "i18n":
				case "sessionStorage":
					return injector.getInstance( plugin );
				case "renderer":
					return injector.getInstance( "presideRenderer" );
				case "messagebox":
					return injector.getInstance( "messagebox@cbmessagebox" );
			}
		}
		return coldboxDSL.process(argumentCollection=arguments);
	}
}