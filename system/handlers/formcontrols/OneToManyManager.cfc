component output=false {

	public string function index( event, rc, prc, args={} ) output=false {
		args.object       = args.relatedTo    ?: "";
		args.sourceObject = args.sourceObject ?: "";
		args.sourceId     = args.savedData.id ?: "";

		if ( !Len( Trim( args.sourceId ) ) || !Len( Trim( args.object ) ) && !Len( Trim( args.sourceObject ) ) ) {
			return "";
		}

		args.objectName = translateResource( uri="preside-objects.#args.object#:title", defaultValue=args.object );
		args.linkTitle  = translateResource( uri="cms:formcontrol.oneToManyManager.link.title", data=[ args.objectName ] );

		return renderView( view="formcontrols/oneToManyManager/index", args=args );
	}
}