<cfscript>
	topLevel           = args.topLevel ?: Querynew('');
	gridFields         = args.gridFields ?: [];
	objectName         = args.objectName;
	record             = args.record ?: {};
	parent             = args.parent ?: "";
	draftsEnabled      = IsTrue( args.draftsEnabled  ?: "" );
	isMultilingual     = IsTrue( args.isMultilingual ?: "" );
	baseViewRecordLink = args.baseViewRecordLink ?: "";
	currentLevel       = Val( args.currentLevel ?: 0 );
</cfscript>
<cfoutput>
	<tr class="depth-#currentLevel#" data-depth="#currentLevel#" data-id="#record.id#" data-parent="#parent#" data-context-container="#record.id#">
		<cfloop array="#gridFields#" index="i" item="fieldName">
			<cfif i == 1 and ( record._options ?: "" ).len()>
				<td class="page-title-cell">
					<cfif IsTrue( record.child_count ?: "" )>
						<i class="fa fa-lg fa-fw fa-caret-right tree-toggler"></i>
					</cfif>

					<a class="page-title" href="#baseViewRecordLink.replace( '{recordId}', record.id ?: '' )#">#( record[ fieldName ] ?: "" )#</a>

					<div class="actions pull-right btn-group">
						#record._options#
					</div>
				</td>
			<cfelse>
				<td>
					#( record[ fieldName ] ?: "" )#
				</td>
			</cfif>
		</cfloop>
		<cfif draftsEnabled>
			<td>#record._status#</td>
		</cfif>
		<cfif isMultilingual>
			<td>#record._translateStatus#</td>
		</cfif>
	</tr>
</cfoutput>