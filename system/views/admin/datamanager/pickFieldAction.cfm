<cfscript>

	param name="args.cancelAction"          type="string"  default=event.buildAdminLink( linkTo="datamanager.object", querystring='id=#rc.object#' );
		object          = rc.object       ?: "";
	 renderObject       = rc.renderObject ?: "";
	 renderSwitch       = rc.renderSwitch ?: "";
		recordLabel     = rc.pickField    ?: "";
	objectTitleSingular = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object ?: "" );
	editRecordTitle     = translateResource( uri="cms:datamanager.bulkEdit.title", data=[ LCase( objectTitleSingular ), recordLabel,ListLen(rc.id) ] );
	saveButton          = translateResource( uri="cms:datamanager.savechanges.btn", data=[ LCase( objectTitleSingular ) ] );
	prc.pageIcon  = "pencil";
	prc.pageTitle = editRecordTitle;
	
</cfscript>

<cfoutput>
	<form class="form-horizontal quick-add-form" method="post" data-dirty-form="protect" action="#event.buildAdminLink( linkTo='datamanager.updateRecordAction')#">
			<input type="hidden" name="sourceIds" value="#rc.id#">
			<input type="hidden" name="updateField" value="#rc.pickField#">
			<input type="hidden" name="objectName" value="#rc.object#">
			#renderObject#
			#renderSwitch#
		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#args.cancelAction#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:datamanager.cancel.btn" )#
				</a>

				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
					<i class="fa fa-check bigger-110"></i>
					#saveButton#
				</button>
			</div>
		</div>
	</form>
</cfoutput>
