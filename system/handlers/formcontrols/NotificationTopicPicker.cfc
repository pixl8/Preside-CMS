component output=false {
	property name="notificationService" inject="notificationService";

	public string function index( event, rc, prc, args={} ) output=false {
		args.topics = notificationService.listTopics();

		return renderView( view="formcontrols/notificationTopicPicker/index", args=args );
	}
}