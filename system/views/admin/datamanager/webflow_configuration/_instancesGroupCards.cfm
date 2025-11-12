<cfscript>
	recordId       = args.recordId              ?: "";
	activeTab      = rc.tab                     ?: "activeInstances"
	instObjName    = args.instanceObjectName    ?: "";
	groupingConfig = args.refGroupingConfig     ?: {};
	webflowId      = groupingConfig.webflowId   ?: "";
	groupedRefs    = groupingConfig.groupedRefs ?: QueryNew( "" );

	event.include( "/css/admin/specific/datamanager/dataCardGrid/" );
</cfscript>

<cfoutput>
	<cfif Len( webflowId ) && groupedRefs.recordcount>
		<div id="cards" class="card-listing">
			<cfloop query="#groupedRefs#">
				<cfset refId    = groupedRefs.reference_id  ?: "" />
				<cfset refLabel = renderContent( renderer="webflowInstanceReference", data=refId, args={ webflowId=webflowId } ) />
				<cfset totalNo  = Val( groupedRefs.total_no ?: "" ) />

				<cfif isEmptyString( refLabel )>
					<cfcontinue />
				</cfif>

				<div class="card-listing-item">
					<div class="card">
						<div class="card-header">
							<h6 class="card-header-label">
								#renderContent( renderer="webflowInstanceReference", data=refId, args={ webflowId=webflowId } )#
							</h6>
						</div>

						<div class="card-body card-body-with-link">
							<a href="#event.buildAdminLink( objectName="webflow_configuration", recordId=recordId, querystring="tab=#activeTab#&reference=#refId#" )#" class="card-body-link">
								#translateResource( uri="preside-objects.webflow_configuration:instance.group.count.#( totalNo == 1 ) ? "singular." : ""#label", data=[ totalNo ] )#
							</a>
						</div>
					</div>
				</div>
			</cfloop>
		</div>
	</cfif>
</cfoutput>