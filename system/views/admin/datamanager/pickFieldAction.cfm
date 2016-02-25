<cfscript>

	param name="args.cancelAction"          type="string"  default=event.buildAdminLink( linkTo="datamanager.object", querystring='id=#rc.object#' );
	
	 renderObject       = rc.renderObject ?: "";
	 renderSwitch       = rc.renderSwitch ?: "";
	
</cfscript>

<cfoutput>
	
	<form class="form-horizontal quick-add-form" method="post" action="#event.buildAdminLink( linkTo='datamanager.updateRecordAction')#">
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

				<button class="btn btn-success" type="submit" tabindex="#getNextTabIndex()#">
					<i class="fa fa-check bigger-110"></i>
					update
				</button>
			</div>
		</div>
	</form>
</cfoutput>
