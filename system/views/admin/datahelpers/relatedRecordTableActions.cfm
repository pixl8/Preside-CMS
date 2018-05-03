<cfparam name="args.viewRecordLink" type="string" />

<cfoutput>
	<div class="action-buttons btn-group">
		<a href="#args.viewRecordLink#" data-context-key="v">
			<i class="fa fa-eye blue"></i>
		</a>
	</div>
</cfoutput>