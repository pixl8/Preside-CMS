<cfparam name="args.viewRecordLink"    type="string" />
<cfparam name="args.deleteRecordLink"  type="string" />
<cfparam name="args.editRecordLink"    type="string" />
<cfparam name="args.deleteRecordTitle" type="string" />

<cfoutput>
	<div class="action-buttons">
		<a class="green" href="#args.viewRecordLink#" data-context-key="v">
			<i class="fa fa-zoom-in bigger-130"></i>
		</a>

		<a class="blue" href="#args.editRecordLink#" data-context-key="e">
			<i class="fa fa-pencil bigger-130"></i>
		</a>

		<a class="red confirmation-prompt" data-context-key="d" href="#args.deleteRecordLink#" title="#args.deleteRecordTitle#">
			<i class="fa fa-trash-o bigger-130"></i>
		</a>
	</div>
</cfoutput>