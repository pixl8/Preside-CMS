<cfoutput>
	<tr class="asset-preview">
		<td class="upload-preview"><img class="preview-thumbnail" width="50" height="50" /></td>
		<td class="upload-type">{{{type}}}</td>
		<td class="upload-size">{{{size}}}</td>
		<td class="upload-detail">
			<input type="text" name="asset-title" value="{{name}}" tabindex="{{tabindex}}" class="form-control" placeholder="#translateResource( "preside-objects.asset:field.title.title" )#">
			<input type="text" name="alt_text" value="{{alt_taxt}}" tabindex="{{tabindex}}" class="form-control" placeholder="#translateResource( "preside-objects.asset:field.alt_text.title" )#">
		</td>
		<td class="upload-actions">
			<div class="action-buttons">
				<a class="red cancel-file-trigger" href="##">
					<i class="fa fa-trash-o bigger-130"></i>
				</a>
			</div>
		</td>
	</tr>
</cfoutput>