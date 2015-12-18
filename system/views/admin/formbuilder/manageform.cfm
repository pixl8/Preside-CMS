<cfscript>
	formId  = ( rc.id ?: "" )
	theForm = prc.form ?: QueryNew('');
	canEdit = IsTrue( prc.canEdit ?: "" );

	showButtonGroup = canEdit;
</cfscript>

<cfoutput>
	<cfif showButtonGroup>
		<div class="top-right-button-group">
			<cfif canEdit>
				<a class="pull-right inline" href="#event.buildAdminLink( linkTo="formbuilder.editForm", queryString="id=" & formId )#" data-global-key="e">
					<button class="btn btn-success btn-sm">
						<i class="fa fa-pencil"></i>
						#translateResource( "formbuilder:edit.form.btn" )#
					</button>
				</a>
			</cfif>
		</div>
	</cfif>
</cfoutput>