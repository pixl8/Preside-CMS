component output=false {

	public void function configure( bundle ) output=false {
		bundle.addAsset( id="ckeditor"                    , path="/ckeditor/ckeditor.js" );
		bundle.addAsset( id="/js/admin/lib/jquery/"       , path="/js/admin/lib/jquery-2*.min.js" );
		bundle.addAsset( id="/js/admin/lib/jquery-for-ie/", path="/js/admin/lib/jquery-1*.min.js" );
		bundle.addAsset( id="/js/admin/lib/jquery-ui/"    , path="/js/admin/lib/jquery-ui*.min.js" );

		bundle.addAssets(
			  directory   = "/js/admin"
			, match       = function( path ){ return ReFindNoCase( "_[0-9a-f]{8}\..*?\.min.js$", arguments.path ); }
			, idGenerator = function( path ) {
				return ListDeleteAt( path, ListLen( path, "/" ), "/" ) & "/";
			}
		);

		bundle.addAssets(
			  directory   = "/css/admin"
			, match       = function( path ){ return ReFindNoCase( "_[0-9a-f]{8}\..*?\.min.css$", arguments.path ); }
			, idGenerator = function( path ) {
				return ListDeleteAt( path, ListLen( path, "/" ), "/" ) & "/";
			}
		);

		bundle.addAssets(
			  directory   = "/js/admin/i18n"
			, match       = "bundle.js"
			, idGenerator = function( path ) {
				return ListDeleteAt( path, ListLen( path, "/" ), "/" ) & "/";
			}
		);

		bundle.asset( "/js/admin/coretop/ie/"        ).setIe( "IE" );
		bundle.asset( "/js/admin/lib/jquery-for-ie/" ).setIe( "IE" );
		bundle.asset( "/js/admin/lib/jquery/"        ).setIe( "!IE" );


		bundle.asset( "/css/admin/core/"             ).before( "*" );
		bundle.asset( "/js/admin/lib/jquery/"        ).before( "ckeditor" );
		bundle.asset( "/js/admin/lib/jquery-ui/"     ).dependsOn( "/js/admin/lib/jquery/", "/js/admin/lib/jquery-for-ie/" );

		bundle.asset( "/js/admin/core/" )
			.after    ( "/js/admin/i18n/*", "ckeditor" )
			.before   ( "/js/admin/specific/*", "/js/admin/devtools/*", "/js/admin/frontend/*", "/js/admin/flot/*" )
			.dependsOn( "/js/admin/lib/jquery-ui/" );
	}

}