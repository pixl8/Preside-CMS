<cfscript>
	alertType      = args.alertType      ?: "warning";
	alertIconClass = args.alertIconClass ?: "fa-edit";

	objectName  = args.objectName  ?: "";
	objectTitle = args.objectTitle ?: translateResource( uri="preside-objects.#objectName#:title.singular", defaultValue=objectName );
	recordId    = args.recordId    ?: "";
	draftId     = args.draftId     ?: "";

	hasDraft = !isEmptyString( draftId );
</cfscript>

<cfoutput>
	<cfif hasDraft>
		<div class="alert alert-block alert-#alertType# clearfix">
			<p>
				<i class="fa fa-lg fa-fw #alertIconClass#"></i>
				#translateResource( uri="draftManager:alert.live.description", data=[ objectTitle ] )#
			</p>

			<br />
			<i class="fa fa-lg fa-fw"></i>
			<a class="btn btn-sm btn-primary" href="#event.buildAdminLink( objectName="draftmanager_draft", operation="viewRecord", recordId=draftId )#"><i class="fa fa-fw fa-eye-slash"></i> #translateResource( uri="draftManager:button.view.draft.label" )#</a>
			<a class="btn btn-sm btn-danger confirmation-prompt" href="#event.buildAdminLink( objectName="draftmanager_draft", operation="deleteRecordAction", recordId=draftId )#" title="#translateResource( uri="draftManager:button.discard.title" )#"><i class="fa fa-fw fa-trash"></i> #translateResource( uri="draftManager:button.discard.label" )#</a>
		</div>
	</cfif>
</cfoutput>