<cfscript>
	groupingConfig = args.refGroupingConfig     ?: {};
	webflowId      = groupingConfig.webflowId   ?: "";
	groupedRefs    = groupingConfig.groupedRefs ?: QueryNew( "" );
	infoCards      = args.infoCards             ?: "";

	groupingLayout        = args.groupingLayout          ?: "cards";
	groupingLayoutViewlet = groupingConfig.layoutViewlet ?: "admin.datamanager.webflow_configuration._instancesGroup#groupingLayout#";
</cfscript>

<cfoutput>
	<cfif Len( infoCards )>
		#infoCards#
	</cfif>

	<cfif Len( webflowId ) && groupedRefs.recordcount && viewletExists( groupingLayoutViewlet )>
		#renderViewlet( event=groupingLayoutViewlet, args=args )#
	</cfif>
</cfoutput>