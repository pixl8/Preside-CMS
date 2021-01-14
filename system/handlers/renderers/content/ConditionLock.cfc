component {

	public string function default( event, rc, prc, args={} ) {
		var isLocked = IsTrue( args.data ?: "" );
		var iconClass = isLocked ? "fa-lock red" : "fa-lock-open light-grey";

		return '<i class="fa fa-fw #iconClass#"></i>';
	}

}