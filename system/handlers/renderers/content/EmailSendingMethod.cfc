component {

	public string function adminDatatable( event, rc, prc, args={} ){
		var method = args.data ?: "";

		var icon  = translateResource( "enum.emailSendingMethod:#method#.iconClass" );
		var label = translateResource( "enum.emailSendingMethod:#method#.shortlabel" );

		var type = args.record.schedule_type ?: "";

		if ( method == "scheduled" && !isEmptyString( type ) ) {
			icon  = translateResource( "enum.emailSendingScheduleType:#type#.iconClass" );
			label = translateResource( "enum.emailSendingScheduleType:#type#.shortlabel" )
		}

		return '<i class="fa fa-fw #icon#"></i> #label#';
	}

}