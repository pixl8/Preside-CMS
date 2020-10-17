<cfscript>
	favourites              = args.favourites          ?: QueryNew( "" );
	nonFavouriteFilters     = args.nonFavouriteFilters ?: QueryNew( "" );
</cfscript>

<cfoutput>
	<ul class="nav nav-pills">
		<li class="filter-title">
			<a>
				<i class="fa fa-fw fa-filter"></i>
				#translateResource( uri="cms:rulesengine.filters.favourites" )#
				<cfif !favourites.recordCount>
					<em>#translateResource( uri="cms:rulesengine.filters.favourites.none.saved.message" )#</em>
				</cfif>
			</a>
		</li>
		<cfloop query="favourites">
			<li data-filter-id="#favourites.id#" class="filter">
				<a href="##">
					<i class="fa fa-fw fa-heart"></i>&nbsp;
					#favourites.condition_name#
				</a>
			</li>
		</cfloop>
	</ul>
</cfoutput>
<cfif nonFavouriteFilters.recordCount>
	<ul>
		<cfoutput query="nonFavouriteFilters" group="folder">
			<li>
				<cfif Len( nonFavouriteFilters.folder )>
					#nonFavouriteFilters.folder#
				<cfelse>
					#translateResource( "cms:rulesengine.ungrouped.filter" )#
				</cfif>

				<ul class="nav nav-pills">
					<cfoutput>
						<li data-filter-id="#nonFavouriteFilters.id#" class="filter">
							<a href="##">
								<i class="fa fa-fw fa-heart"></i>&nbsp;
								#nonFavouriteFilters.condition_name#
							</a>
						</li>
					</cfoutput>
				</ul>
			</li>
		</cfoutput>
	</ul>
</cfif>