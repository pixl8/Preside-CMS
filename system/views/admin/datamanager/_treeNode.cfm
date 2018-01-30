<cfscript>
	topLevel           = args.topLevel ?: Querynew('');
	gridFields         = args.gridFields ?: [];
	objectName         = args.objectName;
	record             = args.record ?: {};
	draftsEnabled      = IsTrue( args.draftsEnabled  ?: "" );
	isMultilingual     = IsTrue( args.isMultilingual ?: "" );
	baseViewRecordLink = args.baseViewRecordLink ?: "";
</cfscript>
<cfoutput>
	<tr>
		<cfloop array="#gridFields#" index="i" item="fieldName">
			<cfif i == 1 and ( record._options ?: "" ).len()>
				<td class="page-title-cell">
					<i class="fa fa-lg fa-fw fa-caret-right tree-toggler"></i>

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