<cfscript>
	id              = args.id            ?: "";
	object          = rc.object          ?: "";
	parentId        = rc.parentId        ?: "";
	relationshipKey = rc.relationshipKey ?: "";

	commonQueryString = "object=#object#&parentId=#parentId#&relationshipKey=#relationshipKey#";
	objectTitleSingular = translateResource( "preside-objects.#object#:title.singular" );

	deleteRecordLink  = event.buildAdminLink( linkTo="datamanager.deleteOneToManyRecordAction", queryString="#commonQueryString#&id=#args.id#" )
	editRecordLink    = event.buildAdminLink( linkTo="datamanager.editOneToManyRecord", queryString="#commonQueryString#&id=#args.id#" )
	deleteRecordTitle = translateResource( uri="cms:datamanager.deleteRecord.prompt", data=[ objectTitleSingular, args.label ?: "" ] )

	canEdit           = true; //datamanagerService.isOperationAllowed( object, "edit"   ) && hasCmsPermission( permissionKey="datamanager.edit", context="datamanager", contextKeys=[ object ] )
	canDelete         = true; //datamanagerService.isOperationAllowed( object, "delete" ) && hasCmsPermission( permissionKey="datamanager.delete", context="datamanager", contextKeys=[ object ] )
</cfscript>
<cfoutput>
	<div class="action-buttons btn-group">
		<cfif canEdit>
			<a href="#editRecordLink#" data-context-key="e">
				<i class="fa fa-pencil"></i>
			</a>
		</cfif>

		<cfif canDelete>
			<a class="confirmation-prompt" data-context-key="d" href="#deleteRecordLink#" title="#htmleditformat(deleteRecordTitle)#">
				<i class="fa fa-trash-o"></i>
			</a>
		</cfif>
	</div>
</cfoutput>