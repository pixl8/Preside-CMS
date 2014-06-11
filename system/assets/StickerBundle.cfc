component output=false {

	public void function configure( bundle ) output=false {
		bundle.addAsset( id="ckeditor", path="/ckeditor/ckeditor.js" );

		bundle.addAssets(
			  directory   = "/compiled"
			, match       = function( path ){ return ReFindNoCase( "[0-9a-f]{8}\..*?\.min.(js|css)$", arguments.path ); }
			, idGenerator = function( path ) {
				var filename = ListLast( path, "/" );
				var id       = ReReplace( filename, "^[0-9a-f]{8}\.(.*?)\.min\.(css|js)$", "\1" );

				id = Replace( id, ".", "/", "all" );
				id = "/#ListLast( arguments.path, "." )#/admin/#id#/";

				return id;
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