<cfscript>
	formId  = ( rc.id ?: "" )
	theForm = prc.form ?: QueryNew('');
	canEdit = IsTrue( prc.canEdit ?: "" );

	showButtonGroup = canEdit;
</cfscript>

<cfoutput>
	<div class="tabbable">
		<ul class="nav nav-tabs">
			<li class="active">
				<a href="##">Fields &amp; layout</a>
			</li>
			<li>
				<a href="##">Submission actions</a>
			</li>
			<li>
				<a href="##">Responses (10,304)</a>
			</li>
		</ul>

		<div class="tab-content">
			<div class="tab-pane active">
				<div class="row">
					<div class="col-md-4 col-lg-3">
						<div id="tab-fields" class="item-type-picker">
							#renderViewlet( "admin.formbuilder.itemTypePicker" )#
						</div>
					</div>
					<div class="col-md-8 col-lg-9">
						<div class="formbuilder-workpanel">
							<!--- <div class="formbuilder-workpanel-header">
								<cfif canEdit>
									<a class="pull-right inline" href="#event.buildAdminLink( linkTo="formbuilder.editForm", queryString="id=" & formId )#" data-global-key="e">
										#translateResource( "formbuilder:edit.form.btn" )#
										<i class="fa fa-fw fa-lg fa-cog"></i>
									</a>
								</cfif>
							</div> --->
							<div class="formbuilder-workpanel-body">
								#renderViewlet( event="admin.formbuilder.itemsManagement", args={ formId=formId } )#
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</cfoutput>