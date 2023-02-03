component {

	private string function default( event, rc, prc, args={} ){
		var ownerName    = args.data ?: "";

		if ( Len( ownerName ) ) {
			return '<i class="fa fa-fw fa-user grey"></i> ' & ownerName;
		}

		return '<em class="light-grey">#translateResource( "cms:not.applicable" )#</em>';
	}

}