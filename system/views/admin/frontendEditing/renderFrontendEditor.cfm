<cfscript>
	renderedContent = args.renderedContent ?: "";
	rawContent      = args.rawContent      ?: "";
	draftContent    = args.draftContent    ?: "";
	control         = args.control         ?: "";
	label           = args.label           ?: "";
	renderer        = args.renderer        ?: "";
	object          = args.object          ?: "";
	property        = args.property        ?: "";
	recordId        = args.recordId        ?: "";
	pageId          = event.getCurrentPageId();
	hasDraft        = Len( Trim( draftContent ) );
	containerId     = "_" & Left( LCase( Hash( CreateUUId() ) ), 8 );

	if ( not Len( Trim( label ) ) ) {
		label = translateResource( uri="cms:frontendeditor.default.label", data=[ position ] );
	}

	if ( event.isAdminUser() ) {
		prc.hasCmsPageEditPermissions = prc.hasCmsPageEditPermissions ?: hasCmsPermission( permissionKey="sitetree.edit", context="page", contextKeys=event.getPagePermissionContext() );
	}
</cfscript>

<cfoutput>
	<cfif not event.isAdminUser() or not prc.hasCmsPageEditPermissions>
		#renderedContent#
	<cfelse>
		<!-- container: #containerId# -->#Trim( renderedContent )#<!-- !container: #containerId# -->
		<script type="text/template" class="content-editor">
			<div class="presidecms content-editor #LCase( control )#<cfif hasDraft> has-draft</cfif>" id="#containerId#">
				<div class="content-editor-overlay" title="#translateResource( 'cms:frontendeditor.overlay.hint' )#">
					<div class="inner"></div>
				</div>
				<div class="content-editor-label">
					#translateResource( label, property )# <span class="draft-warning">#translateResource( "cms:frontendeditor.draft.warning.label" )#</span>
				</div>
				<div class="presidecms content-editor-editor-container">
					<form method="post"
					    class                     = "content-editor-form"
						action                    = "#event.buildAdminLink( linkTo='ajaxProxy.index', querystring='action=frontendEditing.saveAction' )#"
						data-save-draft-action    = "#event.buildAdminLink( linkTo='ajaxProxy.index', querystring='action=frontendEditing.saveDraftAction' )#"
						data-discard-draft-action = "#event.buildAdminLink( linkTo='ajaxProxy.index', querystring='action=frontendEditing.discardDraftAction' )#">

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
							<textarea name="draftContent" class="hide">#draftContent#</textarea>
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

							<button class="btn btn-primary editor-btn-save" type="submit" disabled="disabled">
								<i class="fa fa-check"></i>
								#translateResource( "cms:frontendeditor.editor.save.btn" )#
							</button>
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