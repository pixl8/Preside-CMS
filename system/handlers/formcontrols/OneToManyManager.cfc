component output=false {

	property name="presideObjectService" inject="presideObjectService";

	public string function index( event, rc, prc, args={} ) output=false {
		args.object          = args.relatedTo    ?: "";
		args.sourceObject    = args.sourceObject ?: "";
		args.sourceId        = args.savedData.id ?: "";
		args.relationshipKey = args.relationshipKey ?: "";

		var sourceRecord = presideObjectService.selectData(
			  objectName   = args.sourceObject
			, id           = args.sourceId
			, selectFields = [ "${labelfield} as label" ]
		);
		var recordLabel = sourceRecord.label ?: "";



		if ( !Len( Trim( args.sourceId ) ) || !Len( Trim( args.object ) ) && !Len( Trim( args.sourceObject ) ) ) {
			return "";
		}


		if ( presideObjectService.isPageType( args.sourceObject ) ) {
			args.sourceObjectName = translateResource( uri="page-types.#args.sourceObject#:name", defaultValue=args.sourceObject );
		} else {
			args.sourceObjectName = translateResource( uri="preside-objects.#args.sourceObject#:title.singular", defaultValue=args.sourceObject );
		}

		if ( presideObjectService.isPageType( args.object ) ) {
			args.objectName = translateResource( uri="page-types.#args.object#:name", defaultValue=args.object );
			args.linkTitle  = translateResource( uri="cms:formcontrol.oneToManyManager.pagetype.link.title", data=[ args.objectName ] );
			args.modalTitle = translateResource( uri="cms:formcontrol.oneToManyManager.pagetype.modal.title", data=[ args.objectName, args.sourceObjectName, recordLabel ] );
		} else {
			args.objectName = translateResource( uri="preside-objects.#args.object#:title", defaultValue=args.object );
			args.linkTitle  = translateResource( uri="cms:formcontrol.oneToManyManager.link.title", data=[ args.objectName ] );
			args.modalTitle = translateResource( uri="cms:formcontrol.oneToManyManager.modal.title", data=[ args.objectName, args.sourceObjectName, recordLabel ] );
		}

		args.managerUrl = event.buildAdminLink(
			  linkTo      = 'datamanager.manageOneToManyRecords'
			, queryString = "object=#args.object#&parentObject=#args.sourceObject#&parentId=#args.sourceId#&relationshipKey=#args.relationshipKey#"
		);

		event.include( "/js/admin/specific/oneToManyManager/" );

		return renderView( view="formcontrols/oneToManyManager/index", args=args );
	}
}