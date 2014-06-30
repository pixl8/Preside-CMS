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
</cfscript>

<cfoutput>
	<cfif not event.isAdminUser()>
		#renderedContent#
	<cfelse>
		<!-- container: #containerId# -->#Trim( renderedContent )#<!-- !container: #containerId# -->

		<div class="content-editor #LCase( control )#<cfif hasDraft> has-draft</cfif>" id="#containerId#">
			<div class="content-editor-overlay" title="#translateResource( 'cms:frontendeditor.overlay.hint' )#">
				<div class="inner"></div>
			</div>
			<div class="content-editor-label">
				#translateResource( label, property )# <span class="draft-warning">#translateResource( "cms:frontendeditor.draft.warning.label" )#</span>
			</div>
			<div class="content-editor-editor-container">
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
						<div class="content-editor-editor-notifications"></div>

						<a data-title="#translateResource( 'cms:frontendeditor.field.history.title' )#"
						   href="#event.buildAdminLink( linkTo='frontendediting.fieldHistory', querystring='object=#object#&property=#property#&recordId=#recordId#' )#" data-toggle="bootbox-modal"><i class="preside-icon fa fa-history"></i></a>

						<button class="editor-btn-save" type="submit" disabled="disabled">
							#translateResource( "cms:frontendeditor.editor.save.btn" )#
						</button>
						<button class="editor-btn-cancel">
							#translateResource( "cms:frontendeditor.editor.cancel.btn" )#
						</button>
					</div>
				</form>
			</div>
		</div>
	</cfif>
</cfoutput>