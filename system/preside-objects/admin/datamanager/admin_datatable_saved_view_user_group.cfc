/**
 * @noLabel          true
 * @noId             true
 * @noDateCreated    true
 * @noDateModified   true
 * @versioned        false
 * @feature          admin
 */
component {
	property name="admin_datatable_saved_view" relationship="many-to-one" relatedto="admin_datatable_saved_view" required=true ondelete="cascade" uniqueindexes="viewgroup|1" adminRenderer="none";
	property name="security_group"             relationship="many-to-one" relatedto="security_group"             required=true ondelete="cascade" uniqueindexes="viewgroup|2";
}
