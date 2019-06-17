component {

	property name="presideObjectService" inject="PresideObjectService";

	public string function index( event, rc, prc, args={} ) {
		var targetObject   = args.relatedTo ?: "";
		var sourceIdField  = presideObjectService.getIdField( args.sourceObject );
		var hasSortOrder   = StructKeyExists( presideObjectService.getObjectProperties( targetObject ), "sort_order" );

		args.labelRenderer = args.labelRenderer ?: presideObjectService.getObjectAttribute( targetObject, "labelRenderer" );
		args.defaultValue  = args.savedValue = presideObjectService.getOneToManyConfiguratorJsonString(
			  sourceObject    = args.sourceObject
			, sourceId        = args.savedData[ sourceIdField ] ?: ""
			, relatedTo       = args.relatedTo                  ?: nullValue()
			, relationshipKey = args.relationshipKey            ?: nullValue()
			, labelRenderer   = args.labelRenderer
			, specificVersion = rc.version                      ?: nullValue()
		);

		args.object        = targetObject;
		args.multiple      = args.multiple ?: true;
		args.sortable      = ( args.sortable ?: false ) && hasSortOrder;
		args.formName      = args.formName      ?: presideObjectService.getObjectAttribute( targetObject, "configuratorFormName" );
		args.fields        = args.fields        ?: "";
		args.targetFields  = args.targetFields  ?: "";
		args.add           = args.add           ?: true;
		args.edit          = args.edit          ?: true;
		args.removable     = args.removable     ?: true;

		return renderView( view="formcontrols/oneToManyConfigurator/index", args=args );
	}
}