component output=false {

	property name="userDao" inject="presidecms:object:website_user";

	private string function default( event, rc, prc, args={} ){
		var userId = args.data ?: "";

		args.userRecord = Len( Trim( userId ) ) ? userDao.selectData( id=userId ) : QueryNew( '' );

		return renderView( view="renderers/content/websiteUser/default", args=args );
	}

	private string function adminDataTable( event, rc, prc, args={} ){
		var userId = args.data ?: "";

		args.userRecord = Len( Trim( userId ) ) ? userDao.selectData( id=userId ) : QueryNew( '' );

		return renderView( view="renderers/content/websiteUser/adminDataTable", args=args );
	}

}