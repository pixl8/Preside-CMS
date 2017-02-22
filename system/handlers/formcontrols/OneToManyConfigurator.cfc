component {

	property name="presideObjectService" inject="presideObjectService";

	public string function index( event, rc, prc, args={} ) {
		var targetObject  = args.relatedTo ?: "";
		var targetFk      = args.relationshipKey ?: args.sourceObject;
		var useVersioning = Val( rc.version ?: "" ) && presideObjectService.objectIsVersioned( targetObject );
		var hasSortOrder  = presideObjectService.getObjectProperties( targetObject ).keyExists( "sort_order" );
		var orderBy       = hasSortOrder ? "sort_order" : "";
		
		if ( Len( Trim( args.savedData.id ?: "" ) ) ) {
			var records       = presideObjectService.selectData(
				  objectName       = targetObject
				, filter           = { "#targetFk#"=args.savedData.id }
				, selectFields     = [ "id", "label" ]
				, orderBy          = orderBy
				, useCache         = false
				, fromVersionTable = useVersioning
				, specificVersion  = Val( rc.version ?: "" )
			);

			args.savedValue   = [];
			for( var record in records ) {
				record.__fromDb = true;
				args.savedValue.append( serializeJSON( record ) );
			}
			args.defaultValue = args.savedValue = ArrayToList( args.savedValue );
		}

		args.object           = targetObject;
		args.multiple         = args.multiple ?: true;
		args.sortable         = ( args.sortable ?: false ) && hasSortOrder;
		args.selectedTemplate = args.labelTemplate ?: presideObjectService.getObjectAttribute( targetObject, "configuratorLabelTemplate" );
		args.formName         = args.formName      ?: presideObjectService.getObjectAttribute( targetObject, "configuratorFormName" );
		args.fields           = args.fields        ?: "";
		args.targetFields     = args.targetFields  ?: "";

		return renderView( view="formcontrols/oneToManyConfigurator/index", args=args );
	}
}