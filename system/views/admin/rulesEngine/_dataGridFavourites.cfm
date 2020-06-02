<cfscript>
	favourites = args.favourites ?: QueryNew( 'id,condition_name' );
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