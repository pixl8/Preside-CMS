<cfscript>
	formId  = ( rc.id ?: "" )
	theForm = prc.form ?: QueryNew('');
	canEdit = IsTrue( prc.canEdit ?: "" );

	showButtonGroup = canEdit;
</cfscript>

<cfoutput>
	<cfif showButtonGroup>
		<div class="row">
			<div class="col-md-4 col-lg-3">
				<div class="tabbable">
					<ul class="nav nav-tabs">
						<li class="active">
							<a data-toggle="tab" href="##tab-fields">
								<i class="fa fa-fw fa-plus green"></i>
								#translateResource( "formbuilder:manage.tab.fields.title" )#
							</a>
						</li>
					</ul>

					<div class="tab-content">
						<div id="tab-fields" class="tab-pane active">
							#renderViewlet( "admin.formbuilder.itemTypePicker" )#
						</div>
					</div>
				</div>


			</div>

			<div class="col-md-8 col-lg-9">
				<div class="formbuilder-workpanel">
					<div class="formbuilder-workpanel-header">
						<cfif canEdit>
							<a class="pull-right inline" href="#event.buildAdminLink( linkTo="formbuilder.editForm", queryString="id=" & formId )#" data-global-key="e">
								#translateResource( "formbuilder:edit.form.btn" )#
								<i class="fa fa-fw fa-lg fa-cog"></i>
							</a>
						</cfif>

						<h2 class="blue">#theForm.name#</h2>
						<p>#theForm.description#</p>
					</div>
					<div class="formbuilder-workpanel-body">
						#renderViewlet( event="admin.formbuilder.itemsManagement", args={ formId=formId } )#
					</div>
				</div>
			</div>
		</div>
	</cfif>
</cfoutput>