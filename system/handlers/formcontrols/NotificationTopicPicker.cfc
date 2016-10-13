component output=false {
	property name="notificationService" inject="notificationService";

	public string function index( event, rc, prc, args={} ) output=false {
		args.topics = notificationService.listTopics( userId=event.getAdminUserId() );
		args.style  = args.style ?: "full";

		if ( args.style == "select" ) {
			args.values = args.topics;
			args.labels = [];
			for( var topic in args.topics ) {
				args.labels.append( translateResource( 'notifications.#topic#:title', topic ) );
			}

			return renderView( view="formcontrols/select/index", args=args );
		}

		return renderView( view="formcontrols/notificationTopicPicker/index", args=args );
	}
}