<cfscript>
	objectName    = args.objectName         ?: "";
	groupField    = args.listingGroupField  ?: "";
	listingGroups = args.allListingGroups   ?: [];
	listingView   = args.currentListingView ?: "";
	activeGroupId = Trim( rc.activeGroupId ?: "" );
</cfscript>

<cfoutput>
	<cfif ArrayLen( listingGroups )>
		<div class="tabbable tabs-left">
			<ul class="nav nav-tabs">
				<li<cfif !Len( activeGroupId )> class="active"</cfif>>
					<a href="#event.buildAdminLink( objectName=objectName )#">
						#translateResource(
							  uri          = "preside-objects.#objectName#:datamanager.records.group.all.label"
							, defaultValue = translateResource( uri="cms:datamanager.records.group.all.label" )
						)#
					</a>
				</li>
				<cfloop array="#listingGroups#" item="listingGroup">
					<li<cfif activeGroupId eq listingGroup.id> class="active"</cfif>>
						<a href="#event.buildAdminLink( objectName=objectName, queryString="activeGroupId=#listingGroup.id#" )#">
							#listingGroup.label#
						</a>
					</li>
				</cfloop>
			</ul>

			<div class="tab-content">
				<div id="tab-#activeGroupId#" class="tab-pane active">
	</cfif>

	#listingView#

	<cfif ArrayLen( listingGroups )>
				</div>
			</div>
		</div>
	</cfif>
</cfoutput>