<cfscript>
	objectName  = args.objectName  ?: "draftmanager_draft";
	objectTitle = args.objectTitle ?: "";
	recordLink  = args.recordLink  ?: "";
	alertType   = objectName == "draftmanager_draft" ? "draft" : "record";
</cfscript>

<cfoutput>
	<div class="alert alert-info"><i class="fa fa-fw fa-save"></i>
		#translateResource( uri="draftManager:alert.#alertType#.description", data=[ objectTitle ] )#

		<cfif not isEmptyString( recordLink )>
			#translateResource( uri="draftManager:alert.#alertType#.link", data=[ recordLink ] )#
		</cfif>
	</div>
</cfoutput>