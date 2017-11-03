<cfscript>
	object              = rc.object ?: "";
	id                  = rc.id ?: "";
	recordLabel         = prc.recordLabel ?: "";
	objectTitleSingular = prc.objectName  ?: "";
	renderedRecord      = prc.renderedRecord ?: "";

	canEdit   = IsTrue( prc.canEdit   ?: "" );
	canDelete = IsTrue( prc.canDelete ?: "" );

	if ( canEdit ) {
		editRecordLink  = event.buildAdminLink( linkTo="datamanager.editRecord", queryString="object=#object#&id=#id#" );
		editRecordTitle = translateResource( uri="cms:datamanager.editRecord.btn" );
	}
	if ( canDelete ) {
		deleteRecordLink   = event.buildAdminLink( linkTo="datamanager.deleteRecordAction", queryString="object=#object#&id=#id#" );
		deleteRecordPrompt = translateResource( uri="cms:datamanager.deleteRecord.prompt", data=[ objectTitleSingular, recordLabel ] );
		deleteRecordTitle  = translateResource( uri="cms:datamanager.deleteRecord.btn" );
	}
</cfscript>


<cfoutput>
	<div class="top-right-button-group">
		<cfif canDelete>
			<a class="pull-right inline confirmation-prompt" href="#deleteRecordLink#" title="#HtmlEditFormat( deleteRecordPrompt )#">
				<button class="btn btn-danger btn-sm">
					<i class="fa fa-trash-o"></i>
					#deleteRecordTitle#
				</button>
			</a>
		</cfif>
		<cfif canDelete>
			<a class="pull-right inline" data-global-key="e" href="#editRecordLink#">
				<button class="btn btn-success btn-sm">
					<i class="fa fa-pencil"></i>
					#editRecordTitle#
				</button>
			</a>
		</cfif>
	</div>

	#renderedRecord#
</cfoutput>