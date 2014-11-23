component output=false {

    property name="presideObjectService" inject="presideObjectService";

    public string function index( event, rc, prc, args={} ) output=false {
        args.multiple = true;

        if ( Len( Trim( args.savedData.id ?: "" ) ) && Len( Trim( args.sourceObject ?: "" ) ) ) {
            args.savedValue = presideObjectService.selectManyToManyData(
                  objectName   = args.sourceObject
                , propertyName = args.name
                , id           = args.savedData.id
                , selectFields = [ "#args.name#.id" ]
            );

            args.defaultValue = args.savedValue = ValueList( args.savedValue.id );
        }

        return renderViewlet( event="formcontrols.LinkPicker.index", args=args );
    }

}