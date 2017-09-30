component {

	property name="presideObjectService" inject="PresideObjectService";

	public string function index( event, rc, prc, args={} ) {
		var targetObject  = args.relatedTo ?: "";
		var sourceIdField = presideObjectService.getIdField( args.sourceObject );
		var hasSortOrder  = presideObjectService.getObjectProperties( targetObject ).keyExists( "sort_order" );

		args.defaultValue = args.savedValue = presideObjectService.getOneToManyConfiguratorJsonString(
			  sourceObject    = args.sourceObject
			, sourceId        = args.savedData[ sourceIdField ] ?: ""
			, relatedTo       = args.relatedTo                  ?: nullValue()
			, relationshipKey = args.relationshipKey            ?: nullValue()
			, labelRenderer   = args.labelRenderer              ?: nullValue()
			, specificVersion = rc.version                      ?: nullValue()
		);

		args.object           = targetObject;
		args.multiple         = args.multiple ?: true;
		args.sortable         = ( args.sortable ?: false ) && hasSortOrder;
		args.formName         = args.formName      ?: presideObjectService.getObjectAttribute( targetObject, "configuratorFormName" );
		args.fields           = args.fields        ?: "";
		args.targetFields     = args.targetFields  ?: "";

		return renderView( view="formcontrols/oneToManyConfigurator/index", args=args );
	}
}