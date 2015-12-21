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
						<li>
							<a data-toggle="tab" href="##tab-settings">
								<i class="fa fa-fw fa-cog blue"></i>
								#translateResource( "formbuilder:manage.tab.field.settings.title" )#
							</a>
						</li>
					</ul>

					<div class="tab-content">
						<div id="tab-fields" class="tab-pane active">
							#renderViewlet( "admin.formbuilder.itemTypePicker" )#
						</div>
						<div id="tab-settings" class="tab-pane">
						</div>
					</div>
				</div>


			</div>

			<div class="col-md-8 col-lg-9">
			</div>
		</div>
	</cfif>
</cfoutput>