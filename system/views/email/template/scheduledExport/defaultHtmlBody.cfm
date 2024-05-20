<!---@feature emailCenter and dataExport--->
<cfoutput>
<p>Hi ${known_as},</p>
<p>Please find the following link for the saved export: ${saved_export_name}.</p>

<p><a href="${export_download_link}">${export_filename}</a></p>
<p>The report contains ${number_of_records} records.</p>
</cfoutput>