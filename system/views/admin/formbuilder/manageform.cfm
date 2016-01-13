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
				<a href="##">
					<i class="fa fa-fw fa-reorder"></i>
					Fields &amp; layout
				</a>
			</li>
			<cfif canEdit>
				<li>
					<a href="#event.buildAdminLink( linkTo="formbuilder.editForm", queryString="id=" & formId )#">
						<i class="fa fa-fw fa-cog"></i>
						#translateResource( "formbuilder:edit.form.btn" )#
					</a>
				</li>
			</cfif>
			<li>
				<a href="##">
					<i class="fa fa-fw fa-envelope"></i>
					Responses (10,304)
				</a>
			</li>
		</ul>

		<div class="tab-content">
			<div class="tab-pane active formbuilder-workbench">
				<div class="row">
					<div class="col-md-4 col-lg-3">
						<div id="tab-fields" class="item-type-picker">
							#renderViewlet( "admin.formbuilder.itemTypePicker" )#
						</div>
					</div>
					<div class="col-md-8 col-lg-9">
						<div class="formbuilder-workbench-items">
							#renderViewlet( event="admin.formbuilder.itemsManagement", args={ formId=formId } )#
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</cfoutput>