/**
 * @feature presideForms
 */
component {

	property name="presideObjectService" inject="PresideObjectService";

	public string function index( event, rc, prc, args={} ) {
		var targetObject   = args.relatedTo    ?: "";
		var sourceObject   = args.sourceObject ?: "";
		var sourceIdField  = presideObjectService.getIdField( sourceObject );
		var sortOrderField = presideObjectService.getObjectAttribute( targetObject, "datamanagerSortField", "sort_order" );
		var hasSortOrder   = StructKeyExists( presideObjectService.getObjectProperties( targetObject ), sortOrderField );

		args.labelRenderer = args.labelRenderer ?: presideObjectService.getObjectAttribute( targetObject, "labelRenderer" );
		args.defaultValue  = args.defaultValue  ?: "";
		args.savedValue    = args.savedValue    ?: args.defaultValue;

		if ( isEmptyString( args.defaultValue ?: "" ) ) {
			var shouldHaveDefaultValue = true;

			if ( REFindNoCase("\.cloneRecord\b", rc.event ?: "" ) ) {
				try {
					var sourceProperty = presideObjectService.getObjectProperty( objectName=sourceObject, propertyName=args.name );

					shouldHaveDefaultValue = isFalse( sourceProperty.cloneable ?: true );
				} catch ( any e ) {
					logError( e );
				}
			}

			if ( shouldHaveDefaultValue ) {
				var recordExtraFilters         = [];
				var configuratorFiltersViewlet = Trim( presideObjectService.getObjectAttribute( targetObject, "configuratorFiltersViewlet" ) );

				if ( Len( configuratorFiltersViewlet ) && getController().viewletExists( configuratorFiltersViewlet ) ) {
					recordExtraFilters = renderViewlet( event=configuratorFiltersViewlet, args=args );
				}

				args.defaultValue  = args.savedValue = presideObjectService.getOneToManyConfiguratorJsonString(
					  sourceObject    = args.sourceObject
					, sourceId        = args.savedData[ sourceIdField ] ?: ""
					, relatedTo       = args.relatedTo                  ?: NullValue()
					, relationshipKey = args.relationshipKey            ?: NullValue()
					, specificVersion = rc.version                      ?: NullValue()
					, labelRenderer   = args.labelRenderer
					, extraFilters    = IsArray( recordExtraFilters ) ? recordExtraFilters : []
				);
			}
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