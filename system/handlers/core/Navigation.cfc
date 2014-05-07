<cfcomponent output="false">
	<cfproperty name="siteTreeSvc" inject="siteTreeService" />

<!--- VIEWLETS --->
	<cffunction name="singleLevelMainNav" access="private" returntype="string" output="false">
		<cfargument name="event"        type="any"    required="true" />
		<cfargument name="rc"           type="struct" required="true" />
		<cfargument name="prc"          type="struct" required="true" />
		<cfargument name="viewletArgs"  type="struct" required="false" default="#StructNew()#" />

		<cfscript>
			viewletArgs.homePage  = siteTreeSvc.getSiteHomepage();
			viewletArgs.menuItems = siteTreeSvc.getDescendants(
				  id       = viewletArgs.homepage.id
				, depth        = 1
				, selectFields = [ "id", "label as title" ]
			);

			return renderView( view="core/navigation/singleLevelMainNav", args=viewletArgs );
		</cfscript>
	</cffunction>

</cfcomponent>