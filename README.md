# TaskMaster

A simple Task Manager application.

Exposes the following JSON endpoints:

* POST http://localhost:4000/api/tasks — Create a task
* GET http://localhost:4000/api/tasks — List tasks. Supports filtering via type, status, and priority
* GET http://localhost:4000/api/tasks/:id — Single task with full details and attempts log.
* GET http://localhost:4000/api/tasks/summary — Aggregate counts by by task status

# Instructions

* Run `mix setup` to install and setup dependencies

* Run tests, credo, sobelow, formating (basically all CI steps) with `mix precommit`

* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

I added my Bruno API tool collection here in the bruno directory. You should be able to slurp that into [Bruno](https://www.usebruno.com/) to use the requests... sorry, not tested. Also, I didn't bother with env vars. Just use the create and then grab ids from the response.

See NOTES.md for my notes!