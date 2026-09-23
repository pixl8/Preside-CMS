/**
 * @feature emailCenter
 */
component {

	public string function adminDatatable( event, rc, prc, args={} ){
		var method = args.data ?: "";

		var icon  = renderEnum( data=method, enum="emailSendingMethod", property="iconClass" );
		var label = renderEnum( data=method, enum="emailSendingMethod", property="shortlabel" );

		var type = args.record.schedule_type ?: "";

		if ( method == "scheduled" && !isEmptyString( type ) ) {
			icon  = renderEnum( data=type, enum="emailSendingScheduleType", property="iconClass" );
			label = renderEnum( data=type, enum="emailSendingScheduleType", property="shortlabel" );

			if ( type == "repeat" ) {
				var unit      = args.record.schedule_unit ?: "";
				var measure   = Val( args.record.schedule_measure ?: "" );

				if ( measure > 1 ) {
					measure &= " ";
					unit    = renderEnum( data=unit, enum="timeUnit", property="label.plural" );
				} else {
					measure = "";
					unit    = renderEnum( data=unit, enum="timeUnit", property="label.singular" );
				}

				label = renderEnum(
					  data            = "scheduled"
					, enum            = "emailSendingMethod"
					, property        = "withtype"
					, translationData = [ translateResource( uri="cms:emailcenter.table.scheduled.repeat", data=[ "#measure##unit#" ] ) ]
				);
			}
		}

		return '<i class="fa fa-fw #icon#"></i> #label#';
	}

}