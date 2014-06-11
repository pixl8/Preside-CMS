component output=false {

	public void function configure( bundle ) output=false {
		bundle.addAsset( id="ckeditor", path="/ckeditor/ckeditor.js" );

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

		bundle.asset( "/js/admin/coretop/ie/" ).setIe( "IE" );
		bundle.asset( "/js/admin/jquery/20/"  ).setIe( "!IE" );
		bundle.asset( "/js/admin/jquery/110/"  ).setIe( "IE" );

		bundle.asset( "/js/admin/jquery/20/" ).after( "ckeditor" );
		bundle.asset( "/js/admin/jquery/110/" ).after( "ckeditor", "/js/admin/jquery/20/" );
		bundle.asset( "/js/admin/core/" ).before( "*" ).dependsOn( "/js/admin/jquery/20/", "/js/admin/jquery/110/" );
		bundle.asset( "/css/admin/core/" ).before( "*" );
	}

}