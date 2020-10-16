<cfscript>
	favourites              = args.favourites ?: QueryNew( 'id,condition_name' );
	nonGlobalFilters        = args.nonGlobalFilters?: QueryNew("");
	displayGroupFilter      = false;
	displayIndividualFilter = false;
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

	<cfloop query="nonGlobalFilters">
		<cfif nonGlobalFilters.currentRow eq 1>
			<ul class="nav nav-pills">
				<li class="filter-title">
					<a>
						<i class="fa fa-fw fa-filter"></i>
			<cfif Len( nonGlobalFilters.group_id )>
				<cfset displayGroupFilter = true>
				#translateResource( uri="cms:rulesengine.filters.groupFilters" )#
			<cfelse>
				#translateResource( uri="cms:rulesengine.filters.individualFilters" )#
			</cfif>
					</a>
				</li>
		<cfelseif displayGroupFilter and !Len( nonGlobalFilters.group_id )>
				<cfset displayGroupFilter = false>
			</ul>
			<ul class="nav nav-pills">
				<li class="filter-title">
					<a>
						<i class="fa fa-fw fa-filter"></i>
						#translateResource( uri="cms:rulesengine.filters.individualFilters" )#
					</a>
				</li>
		</cfif>

		<li data-filter-id="#nonGlobalFilters.id#" class="filter">
			<a href="##">
				<i class="fa fa-fw fa-heart"></i>&nbsp;
				#nonGlobalFilters.condition_name#
			</a>
		</li>

		<cfif currentRow eq recordCount>
			</ul>
		</cfif>
	</cfloop>

</cfoutput>