<cfparam name="args._version_number" type="string" />

<cfset language = rc.language ?: "" />
<cfset id       = rc.id       ?: "" />

<cfoutput>
	<div class="action-buttons btn-group">
		<a href="#event.buildAdminLink( linkTo='sitetree.translatePage', queryString='id=#id#&language=#language#&version=#args._version_number#' )#" data-context-key="e" title="#HtmlEditFormat( translateResource( uri="cms:datatable.contextmenu.edit" ) )#">
			<i class="fa fa-pencil"></i>
		</a>
	</div>
</cfoutput>