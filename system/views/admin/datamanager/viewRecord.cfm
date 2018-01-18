<cfscript>
	object        = rc.object ?: "";
	id            = rc.id     ?: "";
	version       = Val( rc.version ?: "" );
	useVersioning = IsTrue( prc.useVersioning ?: "" );

	topRightButtons = prc.topRightButtons ?: "";
	renderedRecord  = prc.renderedRecord  ?: "";
</cfscript>


<cfoutput>
	<cfif topRightButtons.len()>
		<div class="top-right-button-group">#topRightButtons#</div>
	</cfif>

	<cfif useVersioning>
		#renderViewlet( event='admin.datamanager.versionNavigator', args={
			  object  = object
			, id      = id
			, version = version
			, isDraft = IsTrue( prc.record._version_is_draft ?: "" )
			, baseUrl = event.buildAdminLink( objectName=object, recordId=id, operation='viewRecord', args={ version="{version}" } )
		} )#
	</cfif>

	#renderedRecord#
</cfoutput>