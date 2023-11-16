component hint="Reload all or part of your preside application" extends="preside.system.base.Command" {

	property name="jsonRpc2Plugin"           inject="JsonRpc2";
	property name="applicationReloadService" inject="applicationReloadService";
	property name="disableMajorReloads"      inject="coldbox:setting:disableMajorReloads";

	private function index( event, rc, prc ) {
		var params       = jsonRpc2Plugin.getRequestParams();
		var environment  = controller.getConfigSettings().environment;
		var targetName   = "";
		var target       = "";
		var validTargets = {
			  all       = { reloadMethod="reloadAll"           , flagRequiredInProduction=true,  isMajorReload=true , description="Reloads the entire application"                           , successMessage="Application cleared, please refresh the page to complete the reload" }
			, db        = { reloadMethod="dbSync"              , flagRequiredInProduction=true,  isMajorReload=true,  description="Synchronises the database with Preside Object definitions", successMessage="Database objects synchronized" }
			, caches    = { reloadMethod="clearCaches"         , flagRequiredInProduction=false, isMajorReload=false, description="Flushes all caches"                                       , successMessage="Caches cleared" }
			, forms     = { reloadMethod="reloadForms"         , flagRequiredInProduction=false, isMajorReload=false, description="Reloads the form definitions"                             , successMessage="Form definitions reloaded" }
			, i18n      = { reloadMethod="reloadI18n"          , flagRequiredInProduction=false, isMajorReload=false, description="Reloads the i18n resource bundles"                        , successMessage="Resource bundles reloaded" }
			, objects   = { reloadMethod="reloadPresideObjects", flagRequiredInProduction=false, isMajorReload=true,  description="Reloads the preside object definitions"                   , successMessage="Preside object definitions reloaded" }
			, widgets   = { reloadMethod="reloadWidgets"       , flagRequiredInProduction=false, isMajorReload=false, description="Reloads the widget definitions"                           , successMessage="Widget definitions reloaded" }
			, pageTypes = { reloadMethod="reloadPageTypes"     , flagRequiredInProduction=false, isMajorReload=true,  description="Reloads the page type definitions"                        , successMessage="Page type definitions reloaded" }
			, static    = { reloadMethod="reloadStatic"        , flagRequiredInProduction=false, isMajorReload=false, description="Rescans and compiles JS and CSS"                          , successMessage="Static assets rescanned and recompiled" }
		};

		params = IsArray( params.commandLineArgs ?: "" ) ? params.commandLineArgs : [];

		if ( !params.len() || !StructKeyExists( validTargets, params[1] ) ) {
			var usageMessage = newLine();

			usageMessage &= writeText( text="Usage: ", type="help", bold=true );
			usageMessage &= writeText( text="reload <type>", type="help", newline=2 );

			usageMessage &= writeText( text="Reload types:", type="help", newline=2 );

			for( var target in validTargets ) {
				usageMessage &= writeText( text="    #target##RepeatString( ' ', 12-Len(target) )#", type="help", bold=true );
				usageMessage &= writeText( text=": #validTargets[ target ].description#", type="help", newline=true );
			}

			return usageMessage;
		}

		target        = validTargets[ params[1] ];
		var forceFlag = ( params[2] ?: "" ) == "--force";

		if ( environment == "production" && ( target.flagRequiredInProduction ?: false ) && !forceFlag ) {
			return newLine() & writeText( text="--force flag is required to perform this action in a production environment", type="error", bold=true, newline=true );
		}

		if ( target.isMajorReload && isBoolean( disableMajorReloads ) && disableMajorReloads ) {
			return newLine() & writeText( text="Major reloads are disallowed", type="error", bold=true, newline=true );
		}

		var start = GetTickCount();
		applicationReloadService[ target.reloadMethod ]();
		var timeTaken = GetTickCount() - start;

		var message = newLine();
		message &= writeText( text="Reload completed with message: ", type="info", bold=true );
		message &= writeText( text=target.successMessage, type="info", newline=true );
		message &= writeText( text="Time taken: ", type="info", bold=true );
		message &= writeText( text="#NumberFormat( timeTaken )# ms", type="info", newline=true );
		return message;
	}
}