<!---@feature admin and formbuilder--->
<cfscript>
	removeDays                 = Val( args.submission_remove_after    ?: "" );
	submissionToBeRemovedCount = Val( args.submissionToBeRemovedCount ?: "" );
	submissionRemovalNextRun   = args.submissionRemovalNextRun ?: "";
	dateTimeFormat             = "#translateResource( uri="cms:dateFormat" )# #translateResource( uri="cms:timeFormat" )#";
</cfscript>

<cfoutput>
	<div class="alert alert-danger">
		<i class="fa fa-fw fa-info-circle"></i> #translateResource(
			  uri  = "preside-objects.formbuilder_form:removal.enabled.alert#IsDate( submissionRemovalNextRun ) ? ".withNextRun" : ""#"
			, data = [ removeDays, submissionToBeRemovedCount, IsDate( submissionRemovalNextRun ) ? DateTimeFormat( submissionRemovalNextRun, dateTimeFormat ) : "" ]
		)#
	</div>
</cfoutput>