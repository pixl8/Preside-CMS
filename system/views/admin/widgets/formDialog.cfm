<cfscript>
	widget = prc.widget ?: {};

	prc.pageTitle    = translateResource( widget.title       ?: "cms:widget.not.found" );
	prc.pageSubTitle = translateResource( widget.description ?: "cms:widget.not.found" );
	prc.pageIcon     = translateResource( widget.icon        ?: "fa-magic", "fa-magic" );
	prc.pageIcon     = ReReplace( prc.pageIcon, "^fa\-", "" );

	formAction = event.buildAdminLink( linkTo="widgets.saveConfigFormAction" );
</cfscript>

<cfoutput>
	<cfsavecontent variable="body">
		<form class="form-horizontal widget-config-form" data-auto-focus-form="true" data-widget-config-form="true" id="widget-#( rc.widget ?: '' )#" action="#formAction#" method="post">
			<input name="widget" type="hidden" value="#( rc.widget ?: "" )#" />

			#renderWidgetConfigForm(
				  widgetId         = ( rc.widget               ?: "" )
				, configJson       = ( rc.configJson       ?: "" )
				, validationResult = ( rc.validationResult ?: "" )
				, context          = "widgetdialog"
			)#
		</form>
	</cfsavecontent>

	#renderView( view="/admin/widgets/_dialogLayout", args={ body=body } )#
</cfoutput>