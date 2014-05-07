<cfscript>
	prc.pageIcon     = "picture";
	prc.pageTitle    = translateResource( "cms:assetManager" );
	prc.pageSubTitle = translateResource( "cms:assetmanager.add.folder.title" );

	event.addAdminBreadCrumb(
		  title = prc.pageSubTitle
		, link  = event.buildAdminLink( linkTo="assetmanager.addFolder", queryString="folder=#( rc.folder ?: '' )#" )
	);
</cfscript>


<cfoutput>
	<form class="form-horizontal add-folder-form" data-auto-focus-form="true" id="add-folder-form" method="post" action="#event.buildAdminLink( linkTo='assetmanager.addFolderAction' )#">
		<input type="hidden" name="folder" value="#( rc.folder ?: '' )#" />

		#renderForm(
			  formName         = "preside-objects.asset_folder.admin.add"
			, context          = "admin"
			, formId           = "add-folder-form"
			, validationResult = rc.validationResult ?: ""
		)#

		<div class="form-actions row">
			#renderFormControl(
				  type    = "yesNoSwitch"
				, context = "admin"
				, name    = "_addAnother"
				, id      = "_addAnother"
				, label   = translateResource( uri="cms:assetmanager.add.another.folder" )
			)#

			<div class="col-md-offset-2">
				<button class="btn btn-info" type="submit">
					<i class="fa fa-ok bigger-110"></i>
					#translateResource( "cms:assetmanager.add.folder.button" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>