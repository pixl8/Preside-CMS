<cfscript>
	objectName        = args.objectName           ?: "";
	categoryField     = args.listingCategoryField ?: "";
	listingCategories = args.allListingCategories ?: [];
	listingView       = args.currentListingView   ?: "";
	activeCategoryId  = Trim( rc.activeCategoryId ?: "" );
</cfscript>

<cfoutput>
	<cfif ArrayLen( listingCategories )>
		<div class="tabbable tabs-left">
			<ul class="nav nav-tabs">
				<li<cfif !Len( activeCategoryId )> class="active"</cfif>>
					<a href="#event.buildAdminLink( objectName=objectName )#">
						#translateResource(
							  uri          = "preside-objects.#objectName#:datamanager.records.category.all.label"
							, defaultValue = translateResource( uri="cms:datamanager.records.category.all.label" )
						)#
					</a>
				</li>
				<cfloop array="#listingCategories#" item="listingCategory">
					<li<cfif activeCategoryId eq listingCategory.id> class="active"</cfif>>
						<a href="#event.buildAdminLink( objectName=objectName, queryString="activeCategoryId=#listingCategory.id#" )#">
							#listingCategory.label#
						</a>
					</li>
				</cfloop>
			</ul>

			<div class="tab-content">
				<div id="tab-#activeCategoryId#" class="tab-pane active">
	</cfif>

	#listingView#

	<cfif ArrayLen( listingCategories )>
				</div>
			</div>
		</div>
	</cfif>
</cfoutput>