<cfscript>
	tempFileDetails = prc.tempFileDetails ?: {};
	formTitle       = translateResource( uri="cms:assetManager.uploader.form.title", data=[ '<span class="asset-number">1</span>', StructCount( tempFileDetails ) ] );
</cfscript>

<cfoutput>
	<div id="add-asset-forms" class="add-asset-forms">
		<h2>#formTitle#</h2>
		<cfloop collection="#tempFileDetails#" item="tmpId">
			<cfif StructCount( tempFileDetails[tmpId] )>
				<form id="add-asset-form-#tmpId#" class="form-horizontal add-asset-form" data-auto-focus-form="true" data-dirty-form="protect" action="#event.buildAdminLink( linkto="assetmanager.addAssetAction" )#" method="post">
					<input type="hidden" name="folder" value="#( rc.folder ?: "" )#" />
					<input type="hidden" name="fileid" value="#tmpId#" />

					<div class="well">
						<div class="row">
							<div class="col-sm-2">
								<image src="#event.buildLink( assetId=tmpId, isTemporaryAsset=true )#" width="100" height="100" />
								<p>#fileSizeFormat( tempFileDetails[ tmpId ].size )#</p>
							</div>

							<div class="col-sm-10">
								#renderForm(
									  formName  = "preside-objects.asset.admin.add"
									, formId    = "add-asset-form-#tmpId#"
									, context   = "admin"
									, savedData = tempFileDetails[ tmpId ]
								)#
							</div>
						</div>
					</div>
				</form>
			</cfif>
		</cfloop>
	</div>
</cfoutput>