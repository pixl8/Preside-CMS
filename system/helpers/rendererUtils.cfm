<cffunction name="renderEmailTrackingLink" access="public" returntype="string" output="false">
	<cfargument name="link"       type="string" required="true" />
	<cfargument name="link_title" type="string" required="true" />
	<cfargument name="link_body"  type="string" required="true" /><cfsilent>

	<cfscript>
		var linkTitle = Len( Trim( arguments.link_title ) ) ? "#arguments.link_title# (#arguments.link#)" : "";
		var linkBody  = Len( Trim( arguments.link_body ) ) ? arguments.link_body : ( Len( Trim( arguments.link_title ) ) ? arguments.link_title : arguments.link );

		return '<a href="#arguments.link#" title="#linkTitle#">#Abbreviate( linkBody, 70 )#</a>';
	</cfscript>
</cfsilent></cffunction>

<cffunction name="autoLoadMore" access="public" returntype="string" output="false">
	<cfargument name="content"       type="string"  required="true" />
	<cfargument name="maxRows"       type="numeric" required="false" default="3" />
	<cfargument name="showMoreLabel" type="string"  required="false" default="" />
	<cfargument name="showLessLabel" type="string"  required="false" default="" />
	<cfargument name="showMoreClass" type="string"  required="false" default="" />
	<cfargument name="showLessClass" type="string"  required="false" default="" />

	<cfscript>
		var attrs = [ 'data-read-all="true"', 'data-read-all-rows="#arguments.maxRows#"' ];

		if ( Len( arguments.showMoreLabel ) ) {
			ArrayAppend( attrs, 'data-show-more-text="#HtmlEditFormat( arguments.showMoreLabel )#"' );
		}
		if ( Len( arguments.showLessLabel ) ) {
			ArrayAppend( attrs, 'data-show-less-text="#HtmlEditFormat( arguments.showLessLabel )#"' );
		}
		if ( Len( arguments.showMoreClass ) ) {
			ArrayAppend( attrs, 'data-show-more-class="#HtmlEditFormat( arguments.showMoreClass )#"' );
		}
		if ( Len( arguments.showLessClass ) ) {
			ArrayAppend( attrs, 'data-show-less-class="#HtmlEditFormat( arguments.showLessClass )#"' );
		}

		return '<div #ArrayToList( attrs, ' ' )#>' & arguments.content & '</div>'

	</cfscript>
</cffunction>