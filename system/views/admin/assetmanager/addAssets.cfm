<cfscript>
	prc.pageIcon     = "picture";
	prc.pageTitle    = translateResource( "cms:assetManager" );
	prc.pageSubTitle = translateResource( "cms:assetmanager.edit.uploads.title" );

	event.addAdminBreadCrumb(
		  title = translateResource( "cms:assetmanager.edit.uploads.title" )
		, link  = event.buildAdminLink( linkTo="assetmanager.editUploads" )
	);

	tempFileDetails = prc.tempFileDetails ?: {};

	saveBtnTitle = translateResource( "cms:assetManager.add.asset.form.save.button" );
	cancelBtnTitle = translateResource( "cms:assetManager.add.asset.form.cancel.button" );

	rc.asset_folder = rc.folder ?: "";
</cfscript>

<cfoutput>
	#renderView( view="/admin/assetmanager/_uploadSteps", args={ activeStep=2 } )#

	<form id="add-assets-form" class="form-horizontal batch-add-assets-form" data-auto-focus-form="true" data-dirty-form="protect" action="#event.buildAdminLink( linkto="assetmanager.addAssetsAction" )#" method="post">
		<div class="row">
			<div class="col-md-5">
				<h3 class="upload-options-title">
					#translateResource( "cms:assetmanager.upload.steps.batch.upload.options.title")#
				</h3>
				<p>#translateResource( "cms:assetmanager.upload.steps.batch.upload.options.description")#</p>
				<br>
				#renderForm(
					  formName         = "preside-objects.asset.group.upload"
					, context          = "admin"
					, formId           = "add-assets-form"
					, validationResult = rc.validationResult ?: ''
				)#

				<div class="form-actions row">
					#renderFormControl(
						  type         = "yesNoSwitch"
						, context      = "admin"
						, name         = "_skipEditStep"
						, id           = "_skipEditStep"
						, label        = translateResource( uri="cms:assetmanager.upload.skip.edit.option" )
						, defaultValue = true
					)#
					<div class="col-md-offset-2">
						<a href="#event.buildAdminLink( linkTo='assetmanager', queryString='folder=' & rc.folder )#" class="btn btn-default">
							<i class="fa fa-reply bigger-110"></i>
							#translateResource( "cms:cancel.btn" )#
						</a>

						<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
							<i class="fa fa-check bigger-110"></i>
							#translateResource( "cms:save.btn" )#
						</button>
					</div>
				</div>
			</div>
			<div class="col-md-7">
				<div class="table-responsive">
					<table class="table table-hover">
						<thead>
							<tr>
								<th class="center">
									<label>
										<input type="checkbox" class="ace" checked />
										<span class="lbl"></span>
									</label>
								</th>
								<th style="width:75px;">Preview</th>
								<th>Size</th>
								<th>Filename</th>
								<th>Title (extracted)</th>
							</tr>
						</thead>
						<tbody>
							<cfloop collection="#tempFileDetails#" item="tmpId">
								<tr>
									<td class="center">
										<label>
											<input name="id" type="checkbox" class="ace" name="fileIds" value="#tmpId#" checked>
											<span class="lbl"></span>
										</label>
									</td>
									<td><image src="#event.buildLink( assetId=tmpId, isTemporaryAsset=true )#" width="50" height="50" /></td>
									<td>#fileSizeFormat( tempFileDetails[ tmpId ].size )#</td>
									<td>#tempFileDetails[ tmpId ].name#</td>
									<td>
										<cfif tempFileDetails[ tmpId ].title != tempFileDetails[ tmpId ].name>
											#tempFileDetails[ tmpId ].title#
										<cfelse>
											<em class="grey">None found</em>
										</cfif>
									</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
				</image>
			</div>
		</div>
	</form>


	<!--- <div id="add-asset-forms" class="add-asset-forms">
		<cfloop collection="#tempFileDetails#" item="tmpId">
			<cfif StructCount( tempFileDetails[tmpId] )>
				<form id="add-asset-form-#tmpId#" class="form-horizontal add-asset-form" data-auto-focus-form="true" data-dirty-form="protect" action="#event.buildAdminLink( linkto="assetmanager.addAssetAction" )#" method="post">
					<input type="hidden" name="folder" value="#( rc.folder ?: "" )#" />
					<input type="hidden" name="fileid" value="#tmpId#" />
					<div class="well">
						<div class="row">
							<div class="col-sm-2">
								<image src="#event.buildLink( assetId=tmpId, isTemporaryAsset=true )#" width="100" height="100" />
								<p>#tempFileDetails[ tmpId ].name#, #fileSizeFormat( tempFileDetails[ tmpId ].size )#</p>
							</div>

							<div class="col-sm-10">

								#renderForm(
									  formName  = "preside-objects.asset.admin.add"
									, formId    = "add-asset-form-#tmpId#"
									, context   = "admin"
									, savedData = tempFileDetails[ tmpId ]
								)#

								<div class="col-md-offset-2">
									<button type="reset" class="btn cancel-asset-btn"><i class="fa fa-remove-sign"></i> #cancelBtnTitle#</button>
									<button type="input" class="btn btn-primary"><i class="fa fa-check"></i> #saveBtnTitle#</button>
								</div>
							</div>
						</div>
					</div>
				</form>
			</cfif>
		</cfloop>

		<div class="upload-completed-message">
			<h2 class="green"><i class="fa fa-check"></i>&nbsp;#translateResource( "cms:assetmanager.add.assets.complete.title" )#</h2>


			<p> #translateResource( "cms:assetmanager.add.assets.complete.message" )# </p>

			<a href="#event.buildAdminLink( linkTo="assetmanager", queryString="folder=#( rc.folder ?: '' )#")#" class="btn btn-primary back-btn">
				<i class="fa fa-step-backward"></i>
				#translateResource( "cms:assetmanager.add.assets.complete.button" )#
			</a>
		</div> --->
	</div>


</cfoutput>