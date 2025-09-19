<cfscript>
	transitionQuery = args.transitionQuery      ?: QueryNew( "" );
	webflowId       = args.record.reference     ?: "";
	instanceRef     = args.record.sub_reference ?: "";
</cfscript>

<cfoutput>
	<cfif transitionQuery.recordcount>
		<table class="table">
			<thead>
				<tr>
					<th>
						#translateResource(
							  uri          = "preside-objects.cfflow_workflow_instance_history:field.step.listing.title"
							, defaultValue = translateResource( uri="preside-objects.cfflow_workflow_instance_history:field.step.title" )
						)#
					</th>
					<th>
						#translateResource(
							  uri          = "preside-objects.cfflow_workflow_instance_history:field.action.listing.title"
							, defaultValue = translateResource( uri="preside-objects.cfflow_workflow_instance_history:field.action.title" )
						)#
					</th>
					<th>
						#translateResource(
							  uri          = "preside-objects.cfflow_workflow_instance_history:field.result.listing.title"
							, defaultValue = translateResource( uri="preside-objects.cfflow_workflow_instance_history:field.result.title" )
						)#
					</th>
				</tr>
			</thead>

			<tbody>
				<cfloop query="#transitionQuery#">
					<tr>
						<td>
							#renderContent(
								  renderer = "webflowInstanceStepTitle"
								, data     = transitionQuery.from
								, args     = { webflowId=webflowId, instanceRef=instanceRef }
							)#
						</td>
						<td>#transitionQuery.action#</td>
						<td>
							#renderContent(
								  renderer = "webflowInstanceStepTitle"
								, data     = transitionQuery.to
								, args     = { webflowId=webflowId, instanceRef=instanceRef }
							)#
						</td>
					</tr>
				</cfloop>
			</tbody>
		</table>
	</cfif>
</cfoutput>