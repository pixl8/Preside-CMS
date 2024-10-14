<!---@feature admin and formbuilder--->
<cfparam name="args.id"      type="string" />

<cfoutput>
	<cfif canEdit>
		<a class="blue" href="#event.buildAdminLink( linkto="formbuilder.manageForm", querystring="id=#args.id#" )#" data-context-key="e">
		<i class="fa fa-fw fa-pencil"></i></a>
		<a class="green" href="#event.buildAdminLink( linkto="formbuilder.cloneForm", querystring="id=#args.id#" )#" data-context-key="c">
		<i class="fa fa-fw fa-clone"></i></a>
	</cfif>
	<cfif canDelete>
		<a title="#translateResource( "formbuilder:action.form.delete.prompt" )#" class="red confirmation-prompt" href="#event.buildAdminLink( linkto="formbuilder.deleteRecordAction", querystring="id=#args.id#" )#" data-context-key="d">
		<i class="fa fa-fw fa-trash-o"></i></a>
	</cfif>
</cfoutput>