component extends="coldbox.system.Interceptor" output=false {

// PUBLIC
	public void function configure(){}

	public boolean function onStickerInit( event, interceptData ){
		_generateAdminI18nFiles();

		return true;
	}

// PRIVATE HELPERS
	private void function _generateAdminI18nFiles(){
		var bundles    = "";
		var bundle     = "";
		var locales    = "";
		var locale     = "";
		var widgetSvc  = getModel( "widgetsService" );
		var poSvc      = getModel( "presideObjectService" );
		var rsSvc      = getModel( "resourceBundleService" );
		var rootFolder = "";
		var newFolder  = "";
		var js         = "";
		var json       = "";

		if ( not StructKeyExists( request, '_presideCfStaticI18nGenerated' ) ) {
			rootFolder = "/preside/system/assets/js/admin/i18n";
			if ( not DirectoryExists( rootFolder ) ) {
				directory action="create" directory=rootFolder;
			}

			bundles = ["cms"];
			for( var widget in widgetSvc.getWidgets() ) {
				ArrayAppend( bundles, "widgets." & widget );
			}
			for( var po in poSvc.listObjects() ) {
				ArrayAppend( bundles, "preside-objects." & po );
			}

			locales = rsSvc.listLocales();
			ArrayAppend( locales, "en" ); // our default locale

			for( locale in locales ) {
				newFolder = rootFolder & "/" & locale;
				if ( not DirectoryExists( newFolder ) ) {
					directory action="create" directory=newFolder;
				}

				js = "var _resourceBundle = ( function(){ var rb = {}, bundle, el;";

				for( bundle in bundles ) {
					json = rsSvc.getBundleAsJson(
						  bundle   = bundle
						, language = ListFirst( locale, "-_" )
						, country  = ListRest( locale, "-_" )
					);

					js &= "bundle = #json#; for( el in bundle ) { rb[el] = bundle[el]; }";
				}

				js &= "return rb; } )();"

				file action="write" file=newFolder & "/bundle.js" output=js;
			}
		}
	}

}