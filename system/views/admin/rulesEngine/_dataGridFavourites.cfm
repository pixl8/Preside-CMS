<cfscript>
	favourites          = args.favourites          ?: QueryNew( "" );
	nonFavouriteFilters = args.nonFavouriteFilters ?: QueryNew( "" );
	noFilters           = ( favourites.recordCount + nonFavouriteFilters.recordCount ) == 0;
	noSavedFilters      = args.noSavedFilters ?: ( favourites.recordCount + nonFavouriteFilters.recordCount ) == 0;
	canManageFilters    = IsTrue( args.canManageFilters ?: "" );
</cfscript>

<cfif noFilters>
	<ul class="nav nav-pills">
		<li class="filter-title">
			<a>
				<i class="fa fa-fw fa-filter"></i>
				<cfif canManageFilters>
					<cfoutput>#translateResource( "cms:rulesengine.filters.favourites.none.saved.message" )#</cfoutput>
				<cfelse>
					<cfoutput>#translateResource( "cms:rulesengine.filters.favourites.none.saved.no.rights.message" )#</cfoutput>
				</cfif>

			</a>
		</li>
	</ul>
<cfelse>
	<ul class="data-table-grouped-favourites nav nav-pills">
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
					<span class="badge">0</span>
					<i class="fa fa-caret-down"></i>
				</a>

				<ul class="dropdown-menu">
					<cfoutput>
						<li data-filter-id="#nonFavouriteFilters.id#" class="filter">
							<a href="##">
								<i class="fa fa-fw fa-filter"></i>
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