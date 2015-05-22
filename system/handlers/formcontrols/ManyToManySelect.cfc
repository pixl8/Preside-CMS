component output=false {

	property name="presideObjectService" inject="presideObjectService";

	public string function index( event, rc, prc, args={} ) output=false {
		if ( Len( Trim( args.savedData.id ?: "" ) ) ) {
			var sourceObject = args.sourceObject ?: "";
			var useVersioning = Val( rc.version ?: "" ) && presideObjectService.objectIsVersioned( sourceObject );

			args.savedValue = presideObjectService.selectManyToManyData(
				  objectName       = sourceObject
				, propertyName     = args.name
				, id               = args.savedData.id
				, selectFields     = [ "#args.name#.id" ]
				, useCache         = false
				, fromVersionTable = useVersioning
				, specificVersion  = Val( rc.version ?: "" )
			);

			args.defaultValue = args.savedValue = ValueList( args.savedValue.id );
		}

		args.object   = args.relatedTo ?: "";
		args.multiple = true;

		return renderFormControl( argumentCollection=args, type="objectPicker", layout="" );
	}
}