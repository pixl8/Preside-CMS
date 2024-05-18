/**
 * @feature emailCenter
 */
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
					return '<span class="green">#translateResource( uri="cms:emailcenter.table.sent" )#</span> <em class="light-grey">#translateResource( uri="cms:emailcenter.table.actual.recipients", data=[ NumberFormat( sent ) ] )#</em>';
				} else {
					return '<span class="blue">#translateResource( uri="cms:emailcenter.table.not.sent" )#</span>';
				}

			case "manual":
				var sent   = emailTemplateService.getSentCount( templateId );
				var queued = emailTemplateService.getQueuedCount( templateId );

				if ( queued ) {
					return '<span class="orange">#translateResource( uri="cms:emailcenter.table.sending.alert", data=[ NumberFormat( queued ), NumberFormat( sent ) ] )#</span>';
				} else if ( sent ) {
					return '<span class="green">#translateResource( uri="cms:emailcenter.table.sent" )#</span> <em class="light-grey">#translateResource( uri="cms:emailcenter.table.actual.recipients", data=[ NumberFormat( sent ) ] )#</em>';
				}

				return '<span class="blue">#translateResource( uri="cms:emailcenter.table.not.sent" )#</span>';

			case "scheduled":
			default:
				var scheduleType = args.record.schedule_type  ?: "";
				var queued       = emailTemplateService.getQueuedCount( templateId );
				var sent         = emailTemplateService.getSentCount( templateId );

				if ( queued ) {
					return '<span class="orange">#translateResource( uri="cms:emailcenter.table.sending.alert", data=[ NumberFormat( queued ), NumberFormat( sent ) ] )#</span>';
				}


				var formattedDate = "";

				if ( scheduleType == "repeat" ) {
					var startDate = args.record.schedule_start_date ?: "";
					var endDate   = args.record.schedule_end_date   ?: "";

					if ( IsDate( startDate ) ) {
						formattedDate = DateTimeFormat( startDate, 'EEE, d mmm yyyy HH:nn' ) ;
					}

					if ( IsDate( endDate ) ) {
						if ( !isEmptyString( formattedDate ) ) {
							formattedDate &= " #translateResource( uri="cms:emailcenter.table.scheduled.repeat.to" )# ";
						}

						formattedDate &= DateTimeFormat( endDate, 'd mmm yyyy HH:nn' );
					}

					if ( isEmptyString( formattedDate ) ) {
						formattedDate = translateResource( uri="cms:emailcenter.table.not.sent" );
					}
				} else {
					if ( !IsDate( theDate ) ) {
						return '<em class="red">#translateResource( "cms:emailcenter.table.send.date.not.set" )#</em>';
					}

					formattedDate = DateTimeFormat( theDate, 'EEE, d mmm yyyy HH:nn' );
				}

				if ( sent ) {
					return '<span class="green">#formattedDate#</span> <em class="light-grey">#translateResource( uri="cms:emailcenter.table.actual.recipients", data=[ NumberFormat( sent ) ] )#</em>';
				}

				var estimatedRecipientCount = emailMassSendingService.getTemplateRecipientCount( templateId );

				return '<span class="blue">#formattedDate#</span> <em class="light-grey">#translateResource( uri="cms:emailcenter.table.estimated.recipients", data=[  NumberFormat( estimatedRecipientCount ) ] )#</em>';
		}
	}

}