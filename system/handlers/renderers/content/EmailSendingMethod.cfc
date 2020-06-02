component {

	public string function adminDatatable( event, rc, prc, args={} ){
		var method = args.data ?: "";

		var icon     = translateResource( "enum.emailSendingMethod:#method#.iconClass" );
		var label    = translateResource( "enum.emailSendingMethod:#method#.shortlabel" );
		var rendered = '<i class="fa fa-fw #icon#"></i> #label#';

		if ( method =="scheduled" && Len( Trim( args.record.schedule_type ?: "" ) ) ) {
			rendered &= ' <em class="light-grey">(#translateResource( "enum.emailSendingScheduleType:#args.record.schedule_type#.label" )#)</em>'
		}

		return rendered;
	}

}