<cfscript>
	tempFileDetails = prc.tempFileDetails ?: {};
	formTitle       = translateResource( uri="cms:assetManager.uploader.form.title", data=[ '<span class="asset-number">1</span>', StructCount( tempFileDetails ) ] );
</cfscript>

<cfoutput>
	<div id="add-asset-forms" class="add-asset-forms">
		<div class="upload-steps">
			<div class="alert alert-info">
				<p><i class="fa fa-lg fa-edit"></i> #formTitle#</p>
			</div>
			<cfloop collection="#tempFileDetails#" item="tmpId">
				<cfif StructCount( tempFileDetails[tmpId] )>
					<form id="add-asset-form-#tmpId#" class="form-horizontal add-asset-form" data-auto-focus-form="true" data-dirty-form="protect" action="#event.buildAdminLink( linkto="assetmanager.addAssetAction" )#" method="post">
						<input type="hidden" name="fileid" value="#tmpId#" />

						<div class="row">
							<div class="col-sm-2">
								<image src="#event.buildLink( assetId=tmpId, isTemporaryAsset=true )#" width="100" height="100" />
								<p>#fileSizeFormat( tempFileDetails[ tmpId ].size )#</p>
							</div>

							<div class="col-sm-10">
								#renderForm(
									  formName  = "preside-objects.asset.picker.add"
									, formId    = "add-asset-form-#tmpId#"
									, context   = "admin"
									, savedData = tempFileDetails[ tmpId ]
								)#
							</div>
						</div>
					</form>
				</cfif>
			</cfloop>
		</div>
		<div class="completed-steps">
			<div class="alert alert-success">
				<p><i class="fa fa-lg fa-check"></i> #translateResource( uri="cms:assetmanager.uploader.form.completed.title" )#</p>
			</div>
		</div>
	</div>
</cfoutput>