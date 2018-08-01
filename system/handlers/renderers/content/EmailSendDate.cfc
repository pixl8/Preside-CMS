component {

	property name="emailMassSendingService" inject="emailMassSendingService";
	property name="emailTemplateService"    inject="emailTemplateService"   ;

	public string function adminDatatable( event, rc, prc, args={} ){
		var theDate       = args.data                  ?: "";
		var sendingMethod = args.record.sending_method ?: "";
		var templateId    = args.record.id             ?: "";

		if ( sendingMethod == "auto" ) {
			var sent  = emailTemplateService.getSentCount( templateId );

			if ( sent ) {
				return '<span class="green">#translateResource( uri="cms:emailcenter.table.manual.actual.recipients", data=[ NumberFormat( sent ) ] )#</span>';
			} else {
				return '<em class="light-grey">#translateResource( uri="cms:emailcenter.table.not.sent" )#</em>';
			}
		}

		if ( sendingMethod == "manual" ) {
			var sent   = emailTemplateService.getSentCount( templateId );
			var queued = emailTemplateService.getQueuedCount( templateId );

			if ( queued ) {
				return '<span class="orange">#translateResource( uri="cms:emailcenter.table.sending.alert", data=[ NumberFormat( queued ), NumberFormat( sent ) ] )#</span>';
			} else if ( sent ) {
				return '<span class="green">#translateResource( uri="cms:emailcenter.table.manual.actual.recipients", data=[ NumberFormat( sent ) ] )#</span>';
			}

			return '<em class="light-grey">#translateResource( uri="cms:emailcenter.table.not.sent" )#</em>';
		}

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