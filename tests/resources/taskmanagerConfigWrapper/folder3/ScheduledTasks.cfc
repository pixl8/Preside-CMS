component output=false {

	private boolean function task_4( event, rc, prc ) output=false schedule="* 5 * * * *" displayname="Task 4" hint="This is scheduled task 4" displayGroup="Group x" {
		return true;
	}

	private boolean function task_5( event, rc, prc ) output=false schedule="* 14 3 * * *" displayname="Task 5" hint="This is scheduled task 5" {
		return true;
	}

}