/**
 * @feature admin and emailCenter
 */
component {

	property name="formsService" inject="formsService";

	private string function preRenderListing( event, rc, prc, args={} ) {
		if ( isFeatureEnabled( "emailcenter" ) ) {
			if ( isFeatureEnabled( "customEmailTemplates" ) ) {
				setNextEvent( url=event.buildAdminLink( linkto="emailcenter.customTemplates" ) );
			}

			setNextEvent( url=event.buildAdminLink( linkto="emailcenter.systemTemplates" ) );
		}

		return "";
	}

	private array function getCloneRecordActionButtons( event, rc, prc, args={} ) {
		var actions = [{
			  type      = "link"
			, href      = event.buildAdminLink( linkto="emailcenter.customTemplates" )
			, class     = "btn-default"
			, globalKey = "c"
			, iconClass = "fa-reply"
			, label     = translateResource( uri="cms:cancel.btn" )
		}];

		actions.append({
			  type      = "button"
			, class     = "btn-info"
			, iconClass = "fa-save"
			, name      = "_saveAction"
			, value     = "savedraft"
			, label     = translateResource( uri="cms:emailcenter.customTemplates.clone.record.btn" )
		} );

		return actions;
	}

	private string function getCloneRecordFormName( event, rc, prc, args={} ) {
		var formName           = "preside-objects.email_template.admin.clone";
		var emailSendingMethod = prc.record.sending_method ?: "";
		var scheduleType       = prc.record.schedule_type ?: "";

		if ( emailSendingMethod == "scheduled" ) {
			if ( scheduleType == "fixeddate" ) {
				formName = formsService.getMergedFormName( formName, "preside-objects.email_template.admin.clone.fixed.schedule" );
			} else {
				formName = formsService.getMergedFormName( formName, "preside-objects.email_template.admin.clone.repeat.schedule" );
			}
		}

		return formName;
	}

	private string function getAdditionalQueryStringForBuildAjaxListingLink( event, rc, prc, args={} ) {
		var interceptArgs = {
			  objectName            = prc.objectName ?: ""
			, recordId              = prc.recordid   ?: ""
			, additionalQueryString = ""
		};
		
		announceInterception( "onEmailTemplateGetAdditionalQueryStringForBuildAjaxListingLink", interceptArgs );
	
		return interceptArgs.additionalQueryString;
	}

	public void function preFetchRecordsForGridListing( event, rc, prc, args={} ) {
		var interceptArgs = {
			  args = arguments.args
			, rc   = arguments.rc
		}

		announceInterception( "onEmailTemplatePreFetchRecordsForGridListing", interceptArgs );
	}
}