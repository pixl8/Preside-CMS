<cfparam name="args.objectName"     type="string" />
<cfparam name="args.recordId"       type="string" />
<cfparam name="args.editRecordLink" type="string" />

<cfoutput>
	<div class="action-buttons btn-group">
		<a href="#args.editRecordLink#" data-context-key="e" title="#HtmlEditFormat( translateResource( uri="cms:datatable.contextmenu.edit" ) )#">
			<i class="fa fa-pencil"></i>
		</a>
	</div>
</cfoutput>