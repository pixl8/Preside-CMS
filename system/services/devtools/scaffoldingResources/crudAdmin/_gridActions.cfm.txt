<cfparam name="args.deleteRecordLink"  type="string" />
<cfparam name="args.editRecordLink"    type="string" />
<cfparam name="args.viewHistoryLink"   type="string" />
<cfparam name="args.deleteRecordTitle" type="string" />
<cfparam name="args.objectName"        type="string" />
<cfparam name="args.canEdit"           type="boolean" />
<cfparam name="args.canDelete"         type="boolean" />
<cfparam name="args.canViewHistory"    type="boolean" />

<cfoutput>
	<div class="action-buttons btn-group">
		<cfif args.canEdit>
			<a href="#args.editRecordLink#" data-context-key="e">
				<i class="fa fa-pencil"></i>
			</a>
		</cfif>

		<cfif args.canDelete>
			<a class="confirmation-prompt" data-context-key="d" href="#args.deleteRecordLink#" title="#htmleditformat(args.deleteRecordTitle)#">
				<i class="fa fa-trash-o"></i>
			</a>
		</cfif>

		<cfif args.canViewHistory>
			<a data-context-key="h" href="#args.viewHistoryLink#">
				<i class="fa fa-history"></i>
			</a>
		</cfif>
	</div>
</cfoutput>