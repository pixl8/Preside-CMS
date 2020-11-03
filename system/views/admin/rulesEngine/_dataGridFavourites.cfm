<cfscript>
	favourites              = args.favourites          ?: QueryNew( "" );
	nonFavouriteFilters     = args.nonFavouriteFilters ?: QueryNew( "" );
</cfscript>


<cfif nonFavouriteFilters.recordCount>
	<ul class="data-table-grouped-favourites nav nav-pills">
		<!--- <li class="filter-title">
			<a>
				<i class="fa fa-fw fa-filter"></i>
				<cfoutput>#translateResource( uri="cms:rulesengine.filters.all" )#</cfoutput>
			</a>
		</li> --->
		<cfoutput query="nonFavouriteFilters" group="folder">
			<li class="data-table-favourite-group">
				<a href="##" class="dropdown-toggle" data-toggle="preside-dropdown">
					<i class="fa fa-fw fa-folder"></i>
					<cfif Len( nonFavouriteFilters.folder )>
						#nonFavouriteFilters.folder#
					<cfelse>
						#translateResource( "cms:rulesengine.ungrouped.filter" )#
					</cfif>
					&nbsp;
					<i class="fa fa-caret-down"></i>
				</a>

				<ul class="dropdown-menu">
					<cfoutput>
						<li data-filter-id="#nonFavouriteFilters.id#" class="filter">
							<a href="##">
								<i class="fa fa-fw fa-heart"></i>
								#nonFavouriteFilters.condition_name#
							</a>
						</li>
					</cfoutput>
				</ul>
			</li>
		</cfoutput>
		<cfoutput query="favourites">
			<li data-filter-id="#favourites.id#" class="filter">
				<a href="##">
					<i class="fa fa-fw fa-heart"></i>&nbsp;
					#favourites.condition_name#
				</a>
			</li>
		</cfoutput>
	</ul>
</cfif>
<!--- <cfoutput>
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
</cfoutput> --->