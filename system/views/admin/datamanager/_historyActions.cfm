<cfparam name="args.objectName"     type="string" />
<cfparam name="args.recordId"       type="string" />
<cfparam name="args.editRecordLink" type="string" />

<cfoutput>
	<div class="action-buttons btn-group">
		<i class="fa fa-cog dropdown-toggle" data-toggle="dropdown"></i>

		<ul class="dropdown-menu pull-right text-left">
			<cfif hasPermission( permissionKey="datamanager.edit", context="datamanager", contextKeys=[ args.objectName ] )>
				<li>
					<a href="#args.editRecordLink#" data-context-key="e">
						<i class="fa fa-pencil"></i>
						#translateResource( uri="cms:datatable.contextmenu.edit" )#
					</a>
				</li>
			</cfif>
		</ul>
	</div>
</cfoutput>