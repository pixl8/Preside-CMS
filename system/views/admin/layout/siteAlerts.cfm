<cfparam name="args.inMaintenanceMode" type="boolean" />

<cfoutput>
	<cfif args.inMaintenanceMode>
		<div class="alert alert-danger sitewide-alert">
			<i class="fa fa-fw fa-exclamation-circle"></i>

			#translateResource( 'cms:maintenanceMode.global.site.message' )#
		</div>
	</cfif>
</cfoutput>