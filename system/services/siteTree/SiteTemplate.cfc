component output=false accessors=true {
	property name="id"          type="string";
	property name="title"       type="string";
	property name="description" type="string";

	public struct function getMemento() output=false {
		return {
			  id          = getId()
			, title       = getTitle()
			, description = getDescription()
		};
	}
}