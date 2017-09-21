component {

	property name="emailLoggingService" inject="emailLoggingService";

	public string function index( event, rc, prc, args={} ) {
		var storageSize = emailLoggingService.getEmailContentStorageSize();

		switch( Ucase( args.unitSize ?: 'GB' ) ){
			case "KB":
				args.defaultValue = storageSize / 1024 & " Kb";
			break;

			case "MB":
				args.defaultValue = storageSize / 1024 / 1024  & " Mb";
			break;

			default:
				args.defaultValue = storageSize / 1024 / 1024 / 1024  & " Gb";
			break;
		}

		return renderView( view="formcontrols/readOnly/index", args=args );

	}
}