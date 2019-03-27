/**
 * Global actions/viewlets for email center functionality
 *
 */
component extends="preside.system.base.AdminHandler" {

	property name="emailTemplateService"       inject="emailTemplateService";
	property name="systemEmailTemplateService" inject="systemEmailTemplateService";
	property name="emailRecipientTypeService"  inject="emailRecipientTypeService";

	private string function emailParamsHelper( event, rc, prc, args={} ) {
		var systemTemplate = Trim( args.systemTemplate ?: "" );
		var recipientType  = Trim( args.recipientType  ?: "" );

		args.params = [];

		if ( systemTemplate.len() ) {
			args.params.append( systemEmailTemplateService.listTemplateParameters( systemTemplate ), true );
		}
		if ( recipientType.len() ) {
			args.params.append( emailRecipientTypeService.listRecipientTypeParameters( recipientType ), true );
		}

		args.params.sort( function( a, b ){
			return  a.required == b.required ? ( a.title > b.title ? 1 : -1 ) : ( a.required ? -1 : 1 );
		} );

		return renderView( view="/admin/emailcenter/_emailParamsHelper", args=args );
	}

	private string function templateStatsFilter( event, rc, prc, args={} ) {
		var templateId = args.templateId ?: "";

		args.minDate  = prc.minDate = prc.minDate ?: emailTemplateService.getFirstStatDate( templateId );
		args.maxDate  = prc.maxDate = prc.maxDate ?: emailTemplateService.getLastStatDate( templateId );
		args.dateFrom = IsDate( rc.dateFrom ?: "" ) ? rc.dateFrom : "";
		args.dateTo   = IsDate( rc.dateTo   ?: "" ) ? rc.dateTo   : "";

		return renderView( view="/admin/emailcenter/_templateStatsFilter", args=args );
	}

	private string function templateStatsSummary( event, rc, prc, args={} ) {
		args.dateFrom = IsDate( rc.dateFrom ?: "" ) ? rc.dateFrom : "";
		args.dateTo   = IsDate( rc.dateTo   ?: "" ) ? rc.dateTo   : "";

		args.stats    = emailTemplateService.getStats(
			  templateId = args.templateId ?: ""
			, dateFrom   = args.dateFrom
			, dateTo     = args.dateTo
		);

		return renderView( view="/admin/emailcenter/_templateStatsSummary", args=args );
	}

	private string function templateInteractionStatsChart( event, rc, prc, args={} ) {
		var templateId = args.templateId ?: "";

		args.minDate        = prc.minDate = prc.minDate ?: emailTemplateService.getFirstStatDate( templateId );
		args.maxDate        = prc.maxDate = prc.maxDate ?: emailTemplateService.getLastStatDate( templateId );
		args.dateFrom       = IsDate( rc.dateFrom ?: "" ) ? rc.dateFrom : args.minDate;
		args.dateTo         = IsDate( rc.dateTo   ?: "" ) ? rc.dateTo   : args.maxDate;
		args.statsAvailable = IsDate( args.minDate ) && IsDate( args.maxDate );

		if ( args.statsAvailable ) {
			var timepoints = Round( DateDiff( "h", args.dateFrom, args.dateTo ) );

			if ( timepoints > 20 ) {
				timepoints = 20;
			} else if ( timepoints < 5 ) {
				timepoints = 5;
			}

			args.interactionStats = emailTemplateService.getStats(
				  templateId = args.templateId
				, timePoints = timepoints
				, dateFrom   = args.dateFrom
				, dateTo     = args.dateTo
			);

			event.include( "/js/admin/lib/plotly/" );
		}

		return renderView( view="/admin/emailcenter/_templateInteractionStatsChart", args=args );
	}

	private string function templateClickStatsTable( event, rc, prc, args={} ) {
		var templateId = args.templateId ?: "";

		args.dateFrom = IsDate( rc.dateFrom ?: "" ) ? rc.dateFrom : "";
		args.dateTo   = IsDate( rc.dateTo   ?: "" ) ? rc.dateTo   : "";

		args.clickStats = emailTemplateService.getLinkClickStats(
			  templateId = templateId
			, dateFrom   = args.dateFrom
			, dateTo     = args.dateTo
		);


		return renderView( view="/admin/emailcenter/_templateClickStatsTable", args=args );
	}

}