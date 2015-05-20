component output=false {

	property name="presideObjectService" inject="presideObjectService";

	public string function index( event, rc, prc, args={} ) output=false {
		args.object       = args.relatedTo    ?: "";
		args.sourceObject = args.sourceObject ?: "";
		args.sourceId     = args.savedData.id ?: "";

		if ( !Len( Trim( args.sourceId ) ) || !Len( Trim( args.object ) ) && !Len( Trim( args.sourceObject ) ) ) {
			return "";
		}

		if ( presideObjectService.isPageType( args.object ) ) {
			args.objectName = translateResource( uri="page-types.#args.object#:name", defaultValue=args.object );
			args.linkTitle  = translateResource( uri="cms:formcontrol.oneToManyManager.pagetype.link.title", data=[ args.objectName ] );
			args.modalTitle = translateResource( uri="cms:formcontrol.oneToManyManager.pagetype.modal.title", data=[ args.objectName ] );;
		} else {
			args.objectName = translateResource( uri="preside-objects.#args.object#:title", defaultValue=args.object );
			args.linkTitle  = translateResource( uri="cms:formcontrol.oneToManyManager.link.title", data=[ args.objectName ] );
			args.modalTitle = translateResource( uri="cms:formcontrol.oneToManyManager.modal.title", data=[ args.objectName ] );
		}

		args.managerUrl = event.buildAdminLink( linkTo='datamanager.manageOneToManyRecords', queryString="object=#args.objectName#&parentObject=#args.sourceObject#&parentId=#args.sourceId#" );

		event.include( "/js/admin/specific/oneToManyManager/" );

		return renderView( view="formcontrols/oneToManyManager/index", args=args );
	}
}