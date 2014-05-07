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

	if ( not Len( Trim( label ) ) ) {
		label = translateResource( uri="cms:frontendeditor.default.label", data=[ position ] );
	}
</cfscript>

<cfoutput>
	<cfif not event.isAdminUser()>
		#renderedContent#
	<cfelse>
		<div class="content-editor #LCase( control )#<cfif hasDraft> has-draft</cfif>">
			<div class="content-editor-overlay" title="#translateResource( 'cms:frontendeditor.overlay.hint' )#">
				<div class="inner"></div>
			</div>
			<div class="content-editor-label">
				#translateResource( label, property )# <span class="draft-warning">#translateResource( "cms:frontendeditor.draft.warning.label" )#</span>
			</div>
			<div class="content-editor-content">
				#renderedContent#
			</div>
			<div class="content-editor-editor-container">
				<form method="post"
					action                    = "#event.buildAdminLink( linkTo='ajaxProxy.index', querystring='action=frontendEditing.saveAction' )#"
					data-save-draft-action    = "#event.buildAdminLink( linkTo='ajaxProxy.index', querystring='action=frontendEditing.saveDraftAction' )#"
					data-discard-draft-action = "#event.buildAdminLink( linkTo='ajaxProxy.index', querystring='action=frontendEditing.discardDraftAction' )#">

					<input type="hidden" name="pageId"   value="#pageId#"   />
					<input type="hidden" name="object"   value="#object#"   />
					<input type="hidden" name="property" value="#property#" />
					<input type="hidden" name="recordId" value="#recordId#" />
					<input type="hidden" name="renderer" value="#renderer#" />

					<cfif control == "richeditor">
						<textarea name="content">#rawContent#</textarea>
						<textarea name="draftContent" class="hide">#draftContent#</textarea>
					<cfelse>
						#renderFormControl(
							  name         = "content"
							, type         = control
							, context      = "admin"
							, savedValue   = rawContent
							, defaultValue = rawContent
							, layout       = ""
						)#
					</cfif>

					<div class="content-editor-editor-buttons">
						<div class="content-editor-editor-notifications"></div>

						<button class="editor-btn-save" type="submit" disabled="disabled">
							#translateResource( "cms:frontendeditor.editor.save.btn" )#
						</button>
						<cfif control == "richeditor">
							<button class="editor-btn-draft" type="submit" disabled="disabled">
								#translateResource( "cms:frontendeditor.editor.savedraft.btn" )#
							</button>
						</cfif>
						<button class="editor-btn-cancel">
							#translateResource( "cms:frontendeditor.editor.cancel.btn" )#
						</button>
					</div>
				</form>
			</div>
		</div>
	</cfif>
</cfoutput>