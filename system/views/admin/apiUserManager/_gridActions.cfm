<cfparam name="args.deleteRecordLink"  type="string" />
<cfparam name="args.editRecordLink"    type="string" />
<cfparam name="args.viewRecordLink"    type="string" />
<cfparam name="args.deleteRecordTitle" type="string" />
<cfparam name="args.objectName"        type="string" />
<cfparam name="args.canEdit"           type="boolean" />
<cfparam name="args.canDelete"         type="boolean" />

<cfoutput>
	<div class="action-buttons btn-group">
		<a href="#args.viewRecordLink#" data-context-key="v">
			<i class="fa fa-eye blue"></i>
		</a>
		<cfif args.canEdit>
			<a href="#args.editRecordLink#" data-context-key="e">
				<i class="fa fa-pencil green"></i>
			</a>
		</cfif>

		<cfif args.canDelete>
			<a class="confirmation-prompt" data-context-key="d" href="#args.deleteRecordLink#" title="#htmleditformat(args.deleteRecordTitle)#">
				<i class="fa fa-trash-o red"></i>
			</a>
		</cfif>
	</div>
</cfoutput>