component {

	property name="presideObjectService" inject="PresideObjectService";
	property name="labelRendererService" inject="LabelRendererService";

	public string function index( event, rc, prc, args={} ) {
		var targetObject  = args.relatedTo ?: "";
		var targetFk      = args.relationshipKey ?: args.sourceObject;
		var targetIdField = presideObjectService.getIdField( targetObject );
		var sourceIdField = presideObjectService.getIdField( args.sourceObject );
		var useVersioning = Val( rc.version ?: "" ) && presideObjectService.objectIsVersioned( targetObject );
		var hasSortOrder  = presideObjectService.getObjectProperties( targetObject ).keyExists( "sort_order" );
		var orderBy       = hasSortOrder ? "sort_order" : "";
		var labelRenderer = args.labelRenderer = args.labelRenderer ?: presideObjectService.getObjectAttribute( targetObject, "labelRenderer" );
		var labelFields   = labelRendererService.getSelectFieldsForLabel( labelRenderer );

		if ( Len( Trim( args.savedData[ sourceIdField ] ?: "" ) ) ) {
			var records       = presideObjectService.selectData(
				  objectName       = targetObject
				, filter           = { "#targetFk#"=args.savedData[ sourceIdField ] }
				, selectFields     = labelFields.append( "#targetObject#.#targetIdField# as id" )
				, orderBy          = orderBy
				, useCache         = false
				, fromVersionTable = useVersioning
				, specificVersion  = Val( rc.version ?: "" )
			);

			args.savedValue   = [];
			for( var record in records ) {
				var item = {
					  id       = record.id
					, __fromDb = true
					, __label  = labelRendererService.renderLabel( labelRenderer=labelRenderer, args=record )
				};
				args.savedValue.append( serializeJSON( item ) );
			}
			args.defaultValue = args.savedValue = ArrayToList( args.savedValue );
		}

		args.object           = targetObject;
		args.multiple         = args.multiple ?: true;
		args.sortable         = ( args.sortable ?: false ) && hasSortOrder;
		args.formName         = args.formName      ?: presideObjectService.getObjectAttribute( targetObject, "configuratorFormName" );
		args.fields           = args.fields        ?: "";
		args.targetFields     = args.targetFields  ?: "";

		return renderView( view="formcontrols/oneToManyConfigurator/index", args=args );
	}
}