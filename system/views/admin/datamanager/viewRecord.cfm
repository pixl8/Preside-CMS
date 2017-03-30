<cfscript>
	objectName          = event.getValue( name="object", defaultValue="" );
	id                     = event.getValue( name="id", defaultValue="" );
	record                 = event.getValue( name="record", defaultValue=QueryNew(''), private=true );
	objectTitleSingular = translateResource( uri="preside-objects.#objectName#:title.singular", defaultValue=objectName );
	viewRecordPrompt       = translateResource( uri="preside-objects.#objectName#:viewRecord.prompt", defaultValue="", data=[ record.label ] );
	viewRecordTitle        = translateResource( uri="cms:datamanager.viewRecord.title", data=[  objectTitleSingular , record.label ] );
	deleteRecordPrompt     = translateResource( uri="cms:datamanager.deleteRecord.prompt", data=[  objectTitleSingular , record.label ] );

	prc.pageIcon  = "zoom-in";
	prc.pageTitle = viewRecordTitle;
</cfscript>

<cfoutput>
	<div class="top-right-button-group">
		<a class="pull-right inline confirmation-prompt" href="#event.buildAdminLink( linkTo="datamanager.deleteRecordAction", queryString="object=#objectName#&id=#id#" )#" data-global-key="d" title="#deleteRecordPrompt#">
			<button class="btn btn-danger btn-sm">
				<i class="fa fa-trash-o"></i>
				#translateResource( "cms:datamanager.deleterecord.btn" )#
			</button>
		</a>

		<a class="pull-right inline" href="#event.buildAdminLink( linkTo="datamanager.editRecord", queryString="object=#objectName#&id=#id#" )#" data-global-key="e">
			<button class="btn btn-primary btn-sm">
				<i class="fa fa-pencil"></i>
				#translateResource( "cms:datamanager.editrecord.btn" )#
			</button>
		</a>
	</div>
</cfoutput>