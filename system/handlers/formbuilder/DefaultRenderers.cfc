component {

	private string function input() {
		return "";
	}

	private string function adminPlaceholder( event, rc, prc, args={} ) {
		if ( Len( args.configuration.label ?: "" ) ) {
			return args.configuration.label;
		}
		return args.type.title ?: "";
	}

	private string function response( event, rc, prc, args={} ) {
		return renderContent( renderer="plaintext", data=( args.response ?: "" ) );
	}

	private array function responseForExport( event, rc, prc, args={} ) {
		return [ renderContent( renderer="plaintext", data=( args.response ?: "" ) ) ];
	}
}