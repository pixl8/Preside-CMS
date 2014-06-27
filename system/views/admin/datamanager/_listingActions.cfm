<cfparam name="args.viewRecordLink"    type="string" />
<cfparam name="args.deleteRecordLink"  type="string" />
<cfparam name="args.editRecordLink"    type="string" />
<cfparam name="args.viewHistoryLink"   type="string" />
<cfparam name="args.deleteRecordTitle" type="string" />
<cfparam name="args.objectName"        type="string" />

<cfoutput>
	<div class="action-buttons btn-group">
		<cfif hasPermission( permissionKey="datamanager.edit", context="datamanager", contextKeys=[ args.objectName ] )>
			<a href="#args.editRecordLink#" data-context-key="e">
				<i class="fa fa-pencil"></i>
			</a>
		</cfif>

		<cfif hasPermission( permissionKey="datamanager.delete", context="datamanager", contextKeys=[ args.objectName ] )>
			<a class="confirmation-prompt" data-context-key="d" href="#args.deleteRecordLink#" title="#htmleditformat(args.deleteRecordTitle)#">
				<i class="fa fa-trash-o"></i>
			</a>
		</cfif>

		<cfsavecontent variable="extraMenuItems">
			<cfif hasPermission( permissionKey="datamanager.viewversions", context="datamanager", contextKeys=[ args.objectName ] )>
				<li>
					<a data-context-key="h" href="#args.viewHistoryLink#">
						<i class="fa fa-history"></i>
						#translateResource( uri="cms:datatable.contextmenu.history" )#
					</a>
				</li>
			</cfif>
		</cfsavecontent>

		<cfif Len( Trim( extraMenuItems ) )>
			<a class="dropdown-toggle" data-toggle="dropdown"><i class="fa fa-cog"></i></a>

			<ul class="dropdown-menu pull-right text-left">
				#extraMenuItems#
			</ul>
		</cfif>
	</div>
</cfoutput>