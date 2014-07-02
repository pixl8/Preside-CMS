<cfscript>
	param name="args._version_number" type="numeric";
	param name="args.datemodified"    type="string";

	object   = rc.object ?: "";
	id       = rc.id ?: "";
	property = rc.property ?: "";

	fieldName    = translateResource( uri='preside-objects.#object#:field.#property#.title' );
	dateModified = renderField( object=object, property="datemodified", data=args.datemodified );
	loadLink     = event.buildAdminLink( linkTo="ajaxProxy", queryString="action=frontendediting.getVersionContent&object=#object#&id=#id#&property=#property#&version=#args._version_number#" );
	loadTitle    = translateResource( uri='cms:frontendeditor.loadversion.link.title', data=[ fieldName, datemodified ] );
	previewLink  = event.buildAdminLink( linkTo="ajaxProxy", queryString="action=frontendediting.previewVersionContent&object=#object#&id=#id#&property=#property#&version=#args._version_number#" );
	previewTitle = translateResource( uri='cms:frontendeditor.previewversion.link.title', data=[ fieldName, datemodified ] );
	previewDialogTitle = translateResource( uri='cms:frontendeditor.previewversion.dialog.title', data=[ fieldName, datemodified ] );
</cfscript>

<cfoutput>
	<div class="action-buttons btn-group">
		<a href="#previewLink#" class="preview-version" data-title="#HtmlEditFormat( previewDialogTitle )#" title="#HtmlEditFormat( previewTitle )#" data-buttons="ok" data-modal-class="version-preview">
			<i class="fa fa-eye"></i>
		</a>

		<a href="#loadLink#" class="load-version" title="#HtmlEditFormat( loadTitle )#">
			<i class="fa fa-pencil"></i>
		</a>
	</div>
</cfoutput>