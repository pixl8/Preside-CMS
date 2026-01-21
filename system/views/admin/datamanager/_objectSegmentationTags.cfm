<!---@feature admin--->
<cfscript>
	segmentationTags = args.segmentationTags ?: QueryNew( "" );
</cfscript>

<cfoutput>
	<cfif segmentationTags.recordcount>
		<div class="segmentation-tags">
			<cfloop query="#segmentationTags#">
				<cfif Len( segmentationTags.tag_label ?: "" )>
					<span class="segmentation-tag">
						<cfif Len( segmentationTags.tag_icon ?: "" )>
							<i class="fa fa-fw fa-#segmentationTags.tag_icon#"></i>
						</cfif>
						#segmentationTags.tag_label#
					</span>
				</cfif>
			</cfloop>
		</div>
	</cfif>
</cfoutput>