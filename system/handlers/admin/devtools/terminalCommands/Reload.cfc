component output=false hint="Reload all or part of your preside application" {

	property name="jsonRpc2Plugin"           inject="coldbox:myPlugin:JsonRpc2";
	property name="applicationReloadService" inject="applicationReloadService";

	private function index( event, rc, prc ) {
		var params       = jsonRpc2Plugin.getRequestParams();
		var target       = "";
		var validTargets = {
			  all       = { reloadMethod="reloadAll"           , description="Reloads the entire application"                           , successMessage="Full application reloaded" }
			, db        = { reloadMethod="dbSync"              , description="Synchronises the database with Preside Object definitions", successMessage="Database objects synchronized" }
			, caches    = { reloadMethod="clearCaches"         , description="Flushes all caches"                                       , successMessage="Caches cleared" }
			, forms     = { reloadMethod="reloadForms"         , description="Reloads the form definitions"                             , successMessage="Form definitions reloaded" }
			, i18n      = { reloadMethod="reloadI18n"          , description="Reloads the i18n resource bundles"                        , successMessage="Resource bundles reloaded" }
			, objects   = { reloadMethod="reloadPresideObjects", description="Reloads the preside object definitions"                   , successMessage="Preside object definitions reloaded" }
			, widgets   = { reloadMethod="reloadWidgets"       , description="Reloads the widget definitions"                           , successMessage="Widget definitions reloaded" }
			, pageTypes = { reloadMethod="reloadPageTypes"     , description="Reloads the page type definitions"                        , successMessage="Page type definitions reloaded" }
			, static    = { reloadMethod="reloadStatic"        , description="Rescans and compiles JS and CSS"                          , successMessage="Static assets rescanned and recompiled" }
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

		target = validTargets[ params[1] ];

		var start = GetTickCount();
		applicationReloadService[ target.reloadMethod ]();
		var timeTaken = GetTickCount() - start;

		return Chr(10) & "[[b;white;]Reload completed with message: ]" & target.successMessage & Chr(10)
		               & "[[b;white;]Time taken:] #NumberFormat( timeTaken )# ms" & Chr( 10 );
	}
}