/**
 * @feature emailCenter
 */
component {

	public string function adminDatatable( event, rc, prc, args={} ){
		var method = args.data ?: "";

		var icon  = translateResource( "enum.emailSendingMethod:#method#.iconClass" );
		var label = translateResource( "enum.emailSendingMethod:#method#.shortlabel" );

		var type = args.record.schedule_type ?: "";

		if ( method == "scheduled" && !isEmptyString( type ) ) {
			icon  = translateResource( "enum.emailSendingScheduleType:#type#.iconClass" );
			label = translateResource( "enum.emailSendingScheduleType:#type#.shortlabel" )

			if ( type == "repeat" ) {
				var unit      = args.record.schedule_unit ?: "";
				var measure   = Val( args.record.schedule_measure ?: "" );

				if ( measure > 1 ) {
					measure &= " ";
					unit    = translateResource( uri="enum.timeUnit:#unit#.label.plural" );
				} else {
					measure = "";
					unit    = translateResource( uri="enum.timeUnit:#unit#.label.singular" );
				}

				label = translateResource(
					  uri  = "enum.emailSendingMethod:scheduled.withtype"
					, data = [ translateResource( uri="cms:emailcenter.table.scheduled.repeat", data=[ "#measure##unit#" ] ) ]
				);
			}
		}

		return '<i class="fa fa-fw #icon#"></i> #label#';
	}

}