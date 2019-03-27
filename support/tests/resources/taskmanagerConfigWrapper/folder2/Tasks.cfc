component output=false {

	private boolean function task_3( event, rc, prc ) output=false schedule="* 5 * * * *" displayname="Task 3" hint="This is scheduled task 3" {
		return true;
	}

	private boolean function task_4( event, rc, prc ) output=false schedule="* 14 3 * * *" displayname="Task 4" hint="This is scheduled task 4" {
		return true;
	}

}