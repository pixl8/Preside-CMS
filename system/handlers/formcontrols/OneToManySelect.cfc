component {

	property name="presideObjectService" inject="presideObjectService";

	public string function index( event, rc, prc, args={} ) {
		if ( Len( Trim( args.savedData.id ?: "" ) ) ) {
			var sourceObject = args.sourceObject ?: "";
			var useVersioning = Val( rc.version ?: "" ) && presideObjectService.objectIsVersioned( sourceObject );

			args.savedValue = presideObjectService.selectData(
				  id               = args.savedData.id
				, objectName       = sourceObject
				, selectFields     = [ "#args.name#.id" ]
				, useCache         = false
				, fromVersionTable = useVersioning
				, specificVersion  = Val( rc.version ?: "" )
			);

			args.defaultValue = args.savedValue = ValueList( args.savedValue.id );
		}

		args.object   = args.relatedTo ?: "";
		args.multiple = true;
		args.sortable = false;

		return renderFormControl( argumentCollection=args, type="objectPicker", layout="" );
	}
}