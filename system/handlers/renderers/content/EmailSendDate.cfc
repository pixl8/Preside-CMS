component {

	property name="emailMassSendingService" inject="emailMassSendingService";
	property name="emailTemplateService"    inject="emailTemplateService"   ;

	public string function adminDatatable( event, rc, prc, args={} ){
		var theDate       = args.data                  ?: "";
		var sendingMethod = args.record.sending_method ?: "";
		var templateId    = args.record.id             ?: "";

		switch ( sendingMethod ) {
			case "auto":
				var sent = emailTemplateService.getSentCount( templateId );

				if ( sent ) {
					return '<span class="green">#translateResource( uri="cms:emailcenter.table.manual.actual.recipients", data=[ NumberFormat( sent ) ] )#</span>';
				} else {
					return '<em class="light-grey">#translateResource( uri="cms:emailcenter.table.not.sent" )#</em>';
				}

			case "manual":
				var sent   = emailTemplateService.getSentCount( templateId );
				var queued = emailTemplateService.getQueuedCount( templateId );

				if ( queued ) {
					return '<span class="orange">#translateResource( uri="cms:emailcenter.table.sending.alert", data=[ NumberFormat( queued ), NumberFormat( sent ) ] )#</span>';
				} else if ( sent ) {
					return '<span class="green">#translateResource( uri="cms:emailcenter.table.manual.actual.recipients", data=[ NumberFormat( sent ) ] )#</span>';
				}

				return '<em class="light-grey">#translateResource( uri="cms:emailcenter.table.not.sent" )#</em>';

			case "scheduled":
			default:
				var scheduleType = args.record.schedule_type ?: "";

				if ( scheduleType == "repeat" ) {
					var startDate = args.record.schedule_start_date ?: "";
					var endDate   = args.record.schedule_end_date   ?: "";
					var unit      = args.record.schedule_unit       ?: "";
					var measure   = Val( args.record.schedule_measure ?: "" );

					if ( measure > 1 ) {
						measure &= " ";
						unit    = translateResource( uri="enum.timeUnit:#unit#.label.plural" );
					} else {
						measure = "";
						unit    = translateResource( uri="enum.timeUnit:#unit#.label.singular" );
					}

					var sent      = emailTemplateService.getSentCount( templateId );
					var rangeDate = renderContent( renderer="dateTimeRange", data={ dateStarted=startDate, dateEnded=endDate } );

					if ( !isEmptyString( rangeDate ) ) {
						rangeDate = ", " & rangeDate;
					}

					return '<span class="#( sent ? "green" : "blue" )#">Every #measure##unit##rangeDate#</span>';
				} else {
					if ( IsDate( theDate ) ) {
						var formattedDate = DateTimeFormat( theDate, 'EEE, d mmm yy, HH:nn' );

						if ( Now() < theDate ) {
							var expectedRecipientCount = emailMassSendingService.getTemplateRecipientCount( templateId );

							return '<span class="blue">#formattedDate#</span> <em class="light-grey">#translateResource( uri="cms:emailcenter.table.estimated.recipients", data=[  NumberFormat( expectedRecipientCount ) ] )#</em>';
						}

						var sent   = emailTemplateService.getSentCount( templateId );
						var queued = emailTemplateService.getQueuedCount( templateId );

						if ( queued ) {
							return '<span class="orange">#translateResource( uri="cms:emailcenter.table.sending.alert", data=[ NumberFormat( queued ), NumberFormat( sent ) ] )#</span>';
						} else if ( sent ) {
							return '<span class="green">#formattedDate#</span> <em class="light-grey">#translateResource( uri="cms:emailcenter.table.actual.recipients", data=[ NumberFormat( sent ) ] )#</em>';
						}

						return '<span class="grey">#translateResource( uri="cms:emailcenter.table.send.date.in.past.alert", data=[ formattedDate ] )#</span>';
					} else {
						return '<em class="red">#translateResource( "cms:emailcenter.table.send.date.not.set" )#</em>';
					}
				}
		}
	}

}