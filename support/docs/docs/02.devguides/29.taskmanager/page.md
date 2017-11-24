---
id: taskmanager
title: Task manager
---

As of v10.7.0, PresideCMS comes with an built-in task management system designed for running and monitoring scheduled and ad-hoc tasks in the system. For example, you might have a nightly data import task, or an ad-hoc task for optimizing images.

Tasks are defined using convention and run in your full application context so have access to all your data and service layers. Each task is run as a background thread and can be monitored using the real time log view.

![Screenshot of taskmanager live log](images/screenshots/taskmanagerlogs.png)

The documentation is split into two sections:

* [[taskmanager-predefinedtasks]]
* [[taskmanager-adhoctasks]]