component {

	private string function adminPlaceholder( event, rc, prc, args={} ) {
		return '<i class="fa fa-fw #( args.action.iconclass ?: 'fa-send' )#"></i> ' & ( args.action.title ?: "" );
	}

}