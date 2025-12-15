<cfscript>
	alertType      = args.alertType      ?: "warning";
	alertIconClass = args.alertIconClass ?: "fa-edit";

	objectName  = args.objectName  ?: "";
	objectTitle = args.objectTitle ?: translateResource( uri="preside-objects.#objectName#:title.singular", defaultValue=objectName );
	recordId    = args.recordId    ?: "";
</cfscript>

<cfoutput>
	<div class="alert alert-block alert-#alertType# clearfix">
		<p>
			<i class="fa fa-lg fa-fw #alertIconClass#"></i>
			#translateResource( uri="draftManager:alert.draft.description", data=[ objectTitle ] )#
		</p>

		<cfif not isEmptyString( recordId )>
			<br />
			<i class="fa fa-lg fa-fw"></i>
			<a class="btn btn-sm btn-primary" href="#event.buildAdminLink( objectName=objectName, operation="viewRecord", recordId=recordId )#"><i class="fa fa-fw fa-eye"></i> #translateResource( uri="draftManager:button.view.record.label" )#</a>
		</cfif>
	</div>
</cfoutput>