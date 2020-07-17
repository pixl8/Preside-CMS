component extends="preside.system.base.AdminHandler" {
	property name="taskManagerService"       inject="TaskManagerService";
	property name="scheduledReportService"   inject="ScheduledReportService";

	public void function preHandler( event, rc, prc, args={} ) {
		super.preHandler( argumentCollection=arguments );

		prc.pageIcon  = "clock";
		prc.pageTitle = translateResource( "cms:scheduledReportExport.page.title" );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:savedreport.breadcrumb" )
			, link  = event.buildAdminLink( objectName="saved_report" )
		);
	}

	public void function create( event, rc, prc, args={} ) {
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:scheduledReportExport.create" )
			, link  = event.buildAdminLink( linkto="scheduledReport.create" )
		);
		prc.pageIcon  = "plus";
		prc.pageTitle = translateResource( "cms:scheduledReportExport.create.title" );
		prc.formName  = "dataExport.createScheduledReport";
		var reportId  = rc.reportId ?: "";

		if ( isEmpty( reportId ) ) {
			messageBox.warn( translateResource( uri="cms:scheduledReportExport.unknown.error" ) );
			setNextEvent( url=event.buildAdminLink( objectName="saved_report" ) );
		}

		prc.savedData = {
			  label        = "Scheduled report: #renderLabel( "saved_report", reportId )#"
			, saved_report = reportId
			, schedule     = "* * * * * *"
		};
	}

	public void function createAction( event, rc, prc, args={} ) {
		var formName         = "dataExport.createScheduledReport";
		var formData         = event.getCollectionForForm( formName );
		var reportId         = rc.reportId ?: ( formData.saved_report ?: "" );
		var validationResult = validateForm( formName, formData );
		var cronDefineError  = taskManagerService.getValidationErrorMessageForPotentiallyBadCrontabExpression( formData.schedule ?: "" );

		if ( Len( Trim( cronDefineError ) ) ) {
			validationResult.addError( fieldName="schedule", message=cronDefineError );
		}

		if ( !validationResult.validated() ) {
			var persist                  = formData;
			    persist.validationResult = validationResult;

			setNextEvent(
				  url           = event.buildAdminLink( linkTo="scheduledReport.create", queryString="reportId=" & reportId )
				, persistStruct = persist
			);
		}

		scheduledReportService.saveScheduledReport( data=formData );

		messageBox.info( translateResource( uri="cms:scheduledReportExport.create.success" ) );
		setNextEvent( url=event.buildAdminLink( objectName="scheduled_report_export" ) );
	}
}