/**
 * @noLabel          true
 * @noId             true
 * @noDateCreated    true
 * @noDateModified   true
 * @versioned        false
 */
component {
	property name="rules_engine_condition" relationship="many-to-one" relatedto="rules_engine_condition" required=true ondelete="cascade" uniqueindexes="rulesgroup|1" adminRenderer="none";
	property name="security_group"         relationship="many-to-one" relatedto="security_group"         required=true ondelete="cascade" uniqueindexes="rulesgroup|2";
}