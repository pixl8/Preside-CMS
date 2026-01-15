<!---@feature admin--->
<cfscript>
	segmentationTags = args.segmentationTags ?: QueryNew( "" );
</cfscript>

<cfoutput>
	<cfif segmentationTags.recordcount>
		<div class="segmentation-tags">
			<cfloop query="#segmentationTags#">
				<cfif Len( segmentationTags.tag_label ?: "" )>
					<span class="segmentation-tag"
						<cfif Len( segmentationTags.tag_colour ?: "" ) AND ( segmentationTags.tag_colour != "##ffffff" )>
							style="background-color: #segmentationTags.tag_colour#; color: white;"
						</cfif>
					>
						#segmentationTags.tag_label#
					</span>
				</cfif>
			</cfloop>
		</div>
	</cfif>
</cfoutput>