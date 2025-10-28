/**
 * @nowirebox true
 */
component accessors=true {
	property name="id"    type="string"  default="";
	property name="steps" type="array";

	public array function getSteps() {
		return variables.steps ?: [];
	}
}