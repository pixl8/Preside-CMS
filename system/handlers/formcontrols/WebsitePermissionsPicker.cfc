component output=false {
	property name="websitePermissionService" inject="websitePermissionService";

	public string function index( event, rc, prc, args={} ) output=false {
		var permissions = websitePermissionService.listPermissionKeys();

		args.permissions = [];

		for( var perm in permissions ){
			args.permissions.append( {
				  id          : perm
				, title       : translateResource( uri="permissions:#perm#.title" )
				, description : translateResource( uri="permissions:#perm#.description" )
			} );
		}

		args.permissions.sort( function( a, b ){ return a.title > b.title ? 1 : -1; } );

		return renderView( view="formcontrols/websitePermissionsPicker/index", args=args );
	}
}