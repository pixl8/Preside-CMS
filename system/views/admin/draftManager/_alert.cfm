<cfscript>
	recordLink  = args.recordLink  ?: "";
	alertAction = args.alertAction ?: "view";
	objectName  = args.objectName  ?: "draftmanager_draft";
	objectTitle = args.objectTitle ?: "";
	objectType  = objectName == "draftmanager_draft" ? "draft" : "record";
</cfscript>

<cfoutput>
	<div class="alert alert-warning"><i class="fa fa-fw fa-exclamation-triangle"></i>
		#translateResource( uri="draftManager:alert.#objectType#.#alertAction#.description", data=[ objectTitle ] )#

		<cfif not isEmptyString( recordLink )>
			#translateResource( uri="draftManager:alert.#objectType#.#alertAction#.link", data=[ recordLink ] )#
		</cfif>
	</div>
</cfoutput>