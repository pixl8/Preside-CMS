<cfparam name="args.viewRecordLink"    type="string" />
<cfparam name="args.deleteRecordLink"  type="string" />
<cfparam name="args.editRecordLink"    type="string" />
<cfparam name="args.deleteRecordTitle" type="string" />
<cfparam name="args.objectName"        type="string" />

<cfoutput>
	<div class="action-buttons">
		<cfif hasPermission( permissionKey="datamanager.view", context="datamanager", contextKeys=[ args.objectName ] )>
			<a class="green" href="#args.viewRecordLink#" data-context-key="v">
				<i class="fa fa-search bigger-130"></i>
			</a>
		</cfif>

		<cfif hasPermission( permissionKey="datamanager.edit", context="datamanager", contextKeys=[ args.objectName ] )>
			<a class="blue" href="#args.editRecordLink#" data-context-key="e">
				<i class="fa fa-pencil bigger-130"></i>
			</a>
		</cfif>

		<cfif hasPermission( permissionKey="datamanager.delete", context="datamanager", contextKeys=[ args.objectName ] )>
			<a class="red confirmation-prompt" data-context-key="d" href="#args.deleteRecordLink#" title="#htmleditformat(args.deleteRecordTitle)#">
				<i class="fa fa-trash-o bigger-130"></i>
			</a>
		</cfif>
	</div>
</cfoutput>