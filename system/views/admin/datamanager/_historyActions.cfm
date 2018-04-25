<cfparam name="args.objectName"     type="string" />
<cfparam name="args.recordId"       type="string" />
<cfparam name="args.editRecordLink" type="string" />
<cfparam name="args.viewRecordLink" type="string" />
<cfparam name="args.canEdit"        type="boolean" />
<cfparam name="args.canView"        type="boolean" />

<cfoutput>
	<div class="action-buttons btn-group">
		<cfif args.canEdit>
			<a href="#args.editRecordLink#" data-context-key="e" title="#HtmlEditFormat( translateResource( uri="cms:datatable.contextmenu.edit" ) )#">
				<i class="fa fa-pencil"></i>
			</a>
		</cfif>
		<cfif args.canView>
			<a href="#args.viewRecordLink#" data-context-key="v" title="#HtmlEditFormat( translateResource( uri="cms:datatable.contextmenu.view" ) )#">
				<i class="fa fa-eye"></i>
			</a>
		</cfif>
	</div>
</cfoutput>