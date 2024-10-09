/**
 * @feature presideForms
 */
component {

	property name="presideObjectService" inject="PresideObjectService";

	public string function index( event, rc, prc, args={} ) {
		var targetObject   = args.relatedTo ?: "";
		var sourceIdField  = presideObjectService.getIdField( args.sourceObject );
		var sortOrderField = presideObjectService.getObjectAttribute( targetObject, "datamanagerSortField", "sort_order" );
		var hasSortOrder   = StructKeyExists( presideObjectService.getObjectProperties( targetObject ), sortOrderField );
		var isEdit         = isEmptyString( args.savedData[ "datecreated" ] ?: "" );

		args.labelRenderer = args.labelRenderer ?: presideObjectService.getObjectAttribute( targetObject, "labelRenderer" );

		args.defaultValue = args.defaultValue ?: "";
		args.savedValue   = args.savedValue   ?: "";

		try {
			var sourceProperty = presideObjectService.getObjectProperty( objectName=args.sourceObject, propertyName=args.name );
		} catch ( any e ) {
			logError( e );
		}

		if ( !isEdit || isTrue( sourceProperty.cloneable ?: true ) ) {
			args.defaultValue  = args.savedValue = presideObjectService.getOneToManyConfiguratorJsonString(
				  sourceObject    = args.sourceObject
				, sourceId        = args.savedData[ sourceIdField ] ?: ""
				, relatedTo       = args.relatedTo                  ?: NullValue()
				, relationshipKey = args.relationshipKey            ?: NullValue()
				, specificVersion = rc.version                      ?: NullValue()
				, labelRenderer   = args.labelRenderer
			);
		}

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