<cfscript>
	renderedContent = args.renderedContent ?: "";
	rawContent      = args.rawContent      ?: "";
	control         = args.control         ?: "";
	label           = args.label           ?: "";
	renderer        = args.renderer        ?: "";
	object          = args.object          ?: "";
	property        = args.property        ?: "";
	recordId        = args.recordId        ?: "";
	pageId          = event.getCurrentPageId();
	containerId     = "_" & Left( LCase( Hash( CreateUUId() ) ), 8 );

	if ( not Len( Trim( label ) ) ) {
		label = translateResource( uri="cms:frontendeditor.default.label", data=[ position ] );
	}

	if ( event.isAdminUser() ) {
		prc.hasCmsSaveDraftPermissions = prc.hasCmsSaveDraftPermissions ?: hasCmsPermission( permissionKey="sitetree.saveDraft", context="page", contextKeys=event.getPagePermissionContext() );
		prc.hasCmsPublishPermissions   = prc.hasCmsPublishPermissions   ?: hasCmsPermission( permissionKey="sitetree.publish", context="page", contextKeys=event.getPagePermissionContext() );
		prc.hasCmsPageEditPermissions  = prc.hasCmsPageEditPermissions  ?: ( prc.hasCmsSaveDraftPermissions || prc.hasCmsPublishPermissions ) && hasCmsPermission( permissionKey="sitetree.edit", context="page", contextKeys=event.getPagePermissionContext() );

		saveAction            = event.buildAdminLink( linkTo='ajaxProxy.index', querystring='action=frontendEditing.saveAction' );
		publishAction         = event.buildAdminLink( linkTo='ajaxProxy.index', querystring='action=frontendEditing.publishAction' );
		publishPromptEndpoint = event.buildAdminLink( linkTo='ajaxProxy.index', queryString='action=frontendEditing.getPublishPrompt' );
	}
</cfscript>

<cfoutput>
	<cfif not event.isAdminUser() or not prc.hasCmsPageEditPermissions>
		#renderedContent#
	<cfelse>
		<!-- container: #containerId# -->#Trim( renderedContent )#<!-- !container: #containerId# -->
		<script type="text/template" class="content-editor">
			<div class="presidecms content-editor #LCase( control )#" id="#containerId#">
				<div class="content-editor-overlay" title="#translateResource( 'cms:frontendeditor.overlay.hint' )#">
					<div class="inner"></div>
				</div>
				<div class="content-editor-label">
					#translateResource( label, property )# <span class="draft-warning">#translateResource( "cms:frontendeditor.draft.warning.label" )#</span>
				</div>
				<div class="presidecms content-editor-editor-container">
					<form method="post" class="content-editor-form preside-theme" action="#saveAction#" data-publish-prompt-endpoint="#publishPromptEndpoint#" data-publish-action="#publishAction#">
						<input type="hidden" name="pageId"   value="#pageId#"   />
						<input type="hidden" name="object"   value="#object#"   />
						<input type="hidden" name="property" value="#property#" />
						<input type="hidden" name="recordId" value="#recordId#" />
						<input type="hidden" name="renderer" value="#renderer#" />

						<cfif control == "richeditor">
							#renderFormControl(
								  name         = "content"
								, type         = "richeditor"
								, extraClasses = "frontend-container"
								, savedValue   = rawContent
								, defaultValue = rawContent
								, width        = 800
								, height       = 400
								, id           = ""
								, layout       = ""
							)#
						<cfelse>
							#renderFormControl(
								  name         = "content"
								, type         = control
								, context      = "admin"
								, savedValue   = rawContent
								, defaultValue = rawContent
								, id           = ""
								, layout       = ""
							)#
						</cfif>

						<div class="content-editor-editor-buttons">
							<p class="content-editor-editor-notifications"></p>

							<a href="##versiontable#containerId#" class="version-history-link" title="#translateResource( 'cms:frontendeditor.field.history.title' )#"
							   data-title="#translateResource( 'cms:frontendeditor.field.history.title' )#" data-modal-class="version-history" data-buttons="ok"><i class="fa fa-history fa-lg"></i></a>

							<cfif prc.hasCmsSaveDraftPermissions>
								<button type="button" name="_saveAction" value="savedraft" class="btn btn-info editor-btn-save" tabindex="#getNextTabIndex()#">
									<i class="fa fa-save bigger-110"></i> #translateResource( "cms:frontendeditor.editor.save.btn" )#
								</button>
							</cfif>
							<cfif prc.hasCmsPublishPermissions>
								<button type="button" name="_saveAction" value="publish" class="btn btn-warning editor-btn-publish" tabindex="#getNextTabIndex()#">
									<i class="fa fa-globe bigger-110"></i> #translateResource( "cms:frontendeditor.editor.publish.btn" )#
								</button>
							</cfif>

							<button class="btn editor-btn-cancel">
								<i class="fa fa-reply"></i>
								#translateResource( "cms:frontendeditor.editor.cancel.btn" )#
							</button>

							<div class="hide" id="versiontable#containerId#">
								<table class="table table-hover field-version-table" data-remote="#event.buildAdminLink( linkTo="ajaxProxy", queryString="action=frontendediting.getHistoryForAjaxDataTables&id=#recordId#&object=#object#&property=#property#" )#">
									<thead>
										<tr>
											<th>#translateResource( 'cms:frontendeditor.field.history.versiondate.heading' )#</th>
											<th>#translateResource( 'cms:frontendeditor.field.history.versionauthor.heading' )#</th>
											<th>&nbsp;</th>
										</tr>
									</thead>
									<tbody>
									</tbody>
								</table>
								<div class="preview-area">
									<h4>#translateResource( uri='cms:frontendeditor.previewpane.title' )#</h4>
									<div class="preview-pane">
										<em>#translateResource( uri='cms:frontendeditor.previewpane.hint', data=[ '<i class="fa fa-eye"></i>' ])#</em>
									</div>
								</div>
							</div>
						</div>
					</form>
				</div>
			</div>
		</script>
	</cfif>
</cfoutput>