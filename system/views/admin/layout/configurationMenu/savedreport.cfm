<cfif isFeatureEnabled( "savereport" )>
	<cfoutput>
		<li>
			<a href="#event.buildAdminLink( objectName="saved_report" )#">
				<i class="fa fa-fw fa-download"></i>
				#translateResource( 'cms:savedreport' )#
			</a>
		</li>
	</cfoutput>
</cfif>