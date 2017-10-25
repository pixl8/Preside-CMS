component output=false hint="Reload all or part of your preside application" {

	property name="jsonRpc2Plugin"           inject="coldbox:myPlugin:JsonRpc2";
	property name="applicationReloadService" inject="applicationReloadService";

	private function index( event, rc, prc ) {
		var params       = jsonRpc2Plugin.getRequestParams();
		var environment  = controller.getConfigSettings().environment;
		var target       = "";
		var validTargets = {
			  all       = { reloadMethod="reloadAll"           , flagRequiredInProduction=true , description="Reloads the entire application"                           , successMessage="Application cleared, please refresh the page to complete the reload" }
			, db        = { reloadMethod="dbSync"              , flagRequiredInProduction=true , description="Synchronises the database with Preside Object definitions", successMessage="Database objects synchronized" }
			, caches    = { reloadMethod="clearCaches"         , flagRequiredInProduction=false, description="Flushes all caches"                                       , successMessage="Caches cleared" }
			, forms     = { reloadMethod="reloadForms"         , flagRequiredInProduction=false, description="Reloads the form definitions"                             , successMessage="Form definitions reloaded" }
			, i18n      = { reloadMethod="reloadI18n"          , flagRequiredInProduction=false, description="Reloads the i18n resource bundles"                        , successMessage="Resource bundles reloaded" }
			, objects   = { reloadMethod="reloadPresideObjects", flagRequiredInProduction=false, description="Reloads the preside object definitions"                   , successMessage="Preside object definitions reloaded" }
			, widgets   = { reloadMethod="reloadWidgets"       , flagRequiredInProduction=false, description="Reloads the widget definitions"                           , successMessage="Widget definitions reloaded" }
			, pageTypes = { reloadMethod="reloadPageTypes"     , flagRequiredInProduction=false, description="Reloads the page type definitions"                        , successMessage="Page type definitions reloaded" }
			, static    = { reloadMethod="reloadStatic"        , flagRequiredInProduction=false, description="Rescans and compiles JS and CSS"                          , successMessage="Static assets rescanned and recompiled" }
		};

		params = IsArray( params.commandLineArgs ?: "" ) ? params.commandLineArgs : [];

		if ( !params.len() || !StructKeyExists( validTargets, params[1] ) ) {
			var usageMessage = Chr(10) & "[[b;white;]Usage:] reload [#StructKeyList( validTargets, '|' )#]" & Chr(10) & Chr(10)
			                           & "Reload types:" & Chr(10) & Chr(10);

			for( var target in validTargets ) {
				usageMessage &= "    [[b;white;]#target#]#RepeatString( ' ', 12-Len(target) )#: #validTargets[ target ].description#" & Chr(10);
			}

			return usageMessage;
		}

		target        = validTargets[ params[1] ];
		var forceFlag = ( params[2] ?: "" ) == "--force";

		if ( environment == "production" && ( target.flagRequiredInProduction ?: false ) && !forceFlag ) {
			return Chr(10) & "[[b;red;]--force flag is required to perform this action in a production environment]" & Chr(10);
		}

		var start = GetTickCount();
		applicationReloadService[ target.reloadMethod ]();
		var timeTaken = GetTickCount() - start;

		return Chr(10) & "[[b;white;]Reload completed with message: ]" & target.successMessage & Chr(10)
		               & "[[b;white;]Time taken:] #NumberFormat( timeTaken )# ms" & Chr( 10 );
	}
}