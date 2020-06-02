component output=false {

	public void function configure( bundle ) output=false {

		// REGISTER ASSETS
		bundle.addAsset( id="i18n-resource-bundle"        , url="/preside/system/assets/_dynamic/i18nBundle.js" );
		bundle.addAsset( id="ckeditor"                    , path="/ckeditor/ckeditor.js" );
		bundle.addAsset( id="/js/admin/lib/jquery/"       , path="/js/admin/lib/jquery-2*.min.js" );
		bundle.addAsset( id="/js/admin/lib/jquery-for-ie/", path="/js/admin/lib/jquery-1*.min.js" );
		bundle.addAsset( id="/js/admin/lib/jquery-ui/"    , path="/js/admin/lib/jquery-ui*.min.js" );
		bundle.addAsset( id="/js/admin/lib/ace/"          , path="/js/admin/lib/ace*.min.js" );
		bundle.addAsset( id="/js/admin/lib/bootstrap/"    , path="/js/admin/lib/bootstrap*.min.js" );
		bundle.addAsset( id="/js/admin/lib/plotly/"       , path="/js/admin/lib/plotly*.min.js" );
		bundle.addAsset( id="/js/admin/lib/plugins/"      , path="/js/admin/lib/plugins*.min.js" );
		bundle.addAsset( id="recaptcha-js"                , url="https://www.google.com/recaptcha/api.js" );

		bundle.addAsset( id="highlightjs-css"             , url="/preside/system/assets/ckeditorExtensions/plugins/codesnippet/lib/highlight/styles/preside-atelier-dune.dark.css" );
		bundle.addAsset( id="highlightjs-js"              , url="/preside/system/assets/ckeditorExtensions/plugins/codesnippet/lib/highlight/highlight.pack.js" );
		bundle.addAsset( id="highlightjs"                 , path="/js/frontend/hljs/initHighlight.js" );

		bundle.addAssets(
			  directory   = "/js"
			, match       = function( path ){ return ReFindNoCase( "_[0-9a-f]{8}\..*?\.min.js$", arguments.path ); }
			, idGenerator = function( path ) {
				return ListDeleteAt( path, ListLen( path, "/" ), "/" ) & "/";
			}
		);

		bundle.addAssets(
			  directory   = "/css"
			, match       = function( path ){ return ReFindNoCase( "_[0-9a-f]{8}\..*?\.min.css$", arguments.path ); }
			, idGenerator = function( path ) {
				return ListDeleteAt( path, ListLen( path, "/" ), "/" ) & "/";
			}
		);


		// SET INTERNET EXPLORER RESTRICTIONS
		bundle.asset( "/js/admin/coretop/ie/"        ).setIe( "IE" );
		bundle.asset( "/js/admin/lib/jquery-for-ie/" ).setIe( "IE" );
		bundle.asset( "/js/admin/lib/jquery/"        ).setIe( "!IE" );


		// DEFINE DEPENDENCIES AND SORT ORDERS
		bundle.asset( "/js/admin/lib/jquery/"    ).before( "ckeditor" );
		bundle.asset( "/js/admin/lib/jquery-ui/" ).dependsOn( "/js/admin/lib/jquery/", "/js/admin/lib/jquery-for-ie/" );
		bundle.asset( "/js/admin/lib/bootstrap/" ).dependsOn( "/js/admin/lib/jquery/", "/js/admin/lib/jquery-for-ie/" );
		bundle.asset( "/js/admin/lib/ace/"       ).dependsOn( "/js/admin/lib/bootstrap/", "/js/admin/lib/jquery-ui/" );
		bundle.asset( "/js/admin/lib/plugins/"   ).dependsOn( "/js/admin/lib/bootstrap/" );
		bundle.asset( "/js/admin/presidecore/"   ).dependsOn( "/js/admin/lib/ace/", "/js/admin/lib/plugins/", "/js/admin/lib/bootstrap/", "/js/admin/lib/jquery-ui/" )
			                                      .after    ( "i18n-resource-bundle", "ckeditor" )
			                                      .before   ( "/js/admin/specific/*", "/js/admin/devtools/*", "/js/admin/frontend/*", "/js/admin/flot/*" );

		bundle.asset( "/js/admin/specific/assetmanager/editasset/" ).dependsOn( "/js/admin/specific/owlcarousel/" );
		bundle.asset( "/js/frontend/formbuilder/" ).after( "*jquery*" );
		bundle.asset( "/js/admin/specific/passwordscore/" ).after( "*jquery*" );
		bundle.asset( "highlightjs" ).dependsOn( "highlightjs-js" ).dependsOn( "highlightjs-css" );
	}

}