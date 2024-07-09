/**
 * Global actions/viewlets for email center functionality
 *
 * @feature admin and emailCenter
 */
component extends="preside.system.base.AdminHandler" {

	property name="emailTemplateService"       inject="emailTemplateService";
	property name="emailStatsService"          inject="emailStatsService";
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
			args.interactionStats = emailTemplateService.getStats(
				  templateId = args.templateId
				, dateFrom   = args.dateFrom
				, dateTo     = args.dateTo
				, stats      = args.stats ?: []
				, timepoints = 0
			);

			args.interactionStatsData = [];
			var statColourMappings = {
				  sent         = "grey"
				, delivered    = "purple"
				, failed       = "black"
				, opened       = "blue"
				, clicks       = "green"
				, unsubscribes = "orange"
				, complaints   = "red"
			};
			for( var stat in [ "sent", "delivered", "failed", "opened", "clicks", "unsubscribes", "complaints" ] ) {
				if ( StructKeyExists( args.interactionStats, stat ) ) {
					ArrayAppend( args.interactionStatsData, {
						  x    = args.interactionStats.dates
						, y    = args.interactionStats[ stat ]
						, name = translateResource( 'cms:emailcenter.stats.chart.#stat#' )
						, mode = 'lines+markers'
						, line = { color = statColourMappings[ stat ] }
					} );
				}
			}

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

	private string function statsv2( event, rc, prc, args={} ) {
		var templateId = args.templateId ?: "";

		prc.record = prc.record ?: emailTemplateService.getTemplate( id=templateId );

		args.recipientStatField  = emailRecipientTypeService.getRecipientIdLogPropertyForRecipientType( prc.record.recipient_type );
		args.stats               = emailStatsService.getSummaryStats( templateId );
		args.clickReport         = emailStatsService.getLinkClickReport( templateId );


		return renderView( view="/admin/emailcenter/statsv2", args=args );
	}

	public void function getFilteredRecipientsForStatsTables() {
		if ( !_hasBasicNavPermissions() ) {
			event.adminAccessDenied();
		}

		var templateId   = rc.id ?: "";
		var template     = emailTemplateService.getTemplate( id=templateId );
		var extraFilters = [ { filter={ email_template=templateId } } ];
		var orderBy      = "";
		var gridFields   = [];
		var dateFields = {
			  bounces      = "hard_bounced_date"
			, unsubscribes = "unsubscribed_date"
			, complaints   = "marked_as_spam_date"
		};

		if ( StructIsEmpty( template ) ) {
			template = emailTemplateService.getTemplate( id=templateId, allowDrafts=true );
		}

		prc.emailRecipientTypeObject = emailRecipientTypeService.getFilterObjectForRecipientType( template.recipient_type );
		prc.emailRecipientTypeFk = emailRecipientTypeService.getRecipientIdLogPropertyForRecipientType( template.recipient_type );

		ArrayAppend( gridFields, prc.emailRecipientTypeFk );

		switch( rc.statType ?: "" ) {
			case "bounces":
				ArrayAppend( extraFilters, { filter={ hard_bounced=true } } );
			break;
			case "unsubscribes":
				ArrayAppend( extraFilters, { filter={ unsubscribed=true } } );
			break;
			case "complaints":
				ArrayAppend( extraFilters, { filter={ marked_as_spam=true } } );
			break;
			case "mostActive":
				orderBy = "click_count desc,open_count desc";
				ArrayAppend( gridFields, [ "click_count", "open_count" ], true );
				ArrayAppend( extraFilters, { filter="click_count > 0" } );
			break;
		}
		if ( StructKeyExists( dateFields, rc.statType ?: "" ) ) {
			ArrayAppend( gridFields, dateFields[ rc.statType ] );
		}

		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object        = "email_template_send_log"
				, gridFields    = ArrayToList( gridFields )
				, actionsView   = "admin.emailCenter._recipientStatsTableActions"
				, draftsEnabled = false
				, extraFilters  = extraFilters
				, useCache      = false
				, orderBy       = orderBy
			}
		);
	}

	private string function _recipientStatsTableActions() {
		var objName = prc.emailRecipientTypeObject ?: "";
		var fkField = prc.emailRecipientTypeFk ?: "";
		var rawFieldValue = args[ "__raw_#fkField#" ] ?: "";

		args.actions = [];

		if ( Len( objName ) && Len( rawFieldValue ) ) {
			var viewLink = event.buildAdminLink( objectName=objName, recordId=rawFieldValue );

			if ( Len( viewLink ) ) {
				ArrayAppend( args.actions, { link=viewLink, icon="fa-eye" } )
				return renderView( view="/admin/datamanager/_listingActions", args=args );
			}
		}

		return serializeJson( args );
	}

	private boolean function _hasBasicNavPermissions() {
		return hasCmsPermission( "emailCenter.customTemplates.navigate" ) ||
		       hasCmsPermission( "emailcenter.systemTemplates.navigate" );
	}
}