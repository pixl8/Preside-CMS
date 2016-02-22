component output=false {

	property name="userDao" inject="presidecms:object:security_user";

	private string function default( event, rc, prc, args={} ){
		var userId = args.data ?: "";

		args.userRecord = Len( Trim( userId ) ) ? userDao.selectData( id=userId ) : QueryNew( '' );

		return renderView( view="renderers/content/adminUser/default", args=args );
	}

	private string function adminDataTable( event, rc, prc, args={} ){
		var userId = args.data ?: "";

		args.userRecord = Len( Trim( userId ) ) ? userDao.selectData( id=userId ) : QueryNew( '' );

		return renderView( view="renderers/content/adminUser/adminDataTable", args=args );
	}

}