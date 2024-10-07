<!---@feature admin and customEmailTemplates--->
<cfparam name="args.deleteRecordLink"  type="string" />
<cfparam name="args.previewRecordLink" type="string" />
<cfparam name="args.editRecordLink"    type="string" />
<cfparam name="args.cloneLink"         type="string" />
<cfparam name="args.viewHistoryLink"   type="string" />
<cfparam name="args.deleteRecordTitle" type="string" />
<cfparam name="args.objectName"        type="string" />
<cfparam name="args.canEdit"           type="boolean" />
<cfparam name="args.canClone"          type="boolean" />
<cfparam name="args.canDelete"         type="boolean" />
<cfparam name="args.canViewHistory"    type="boolean" />

<cfoutput>
	<div class="action-buttons btn-group">
		<a href="#args.previewRecordLink#" data-context-key="p">
			<i class="fa fa-eye"></i>
		</a>

		<cfif args.canEdit>
			<a href="#args.editRecordLink#" data-context-key="e">
				<i class="fa fa-pencil"></i>
			</a>
		</cfif>

		<cfif args.canClone>
			<a href="#args.cloneLink#" data-context-key="c">
				<i class="fa fa-clone"></i>
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