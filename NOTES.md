 NOTES.md — This carries heavy weight. Cover:
  Architecture decisions and why
  OTP patterns used (and patterns considered but not implemented, with reasoning)
  Trade-offs and shortcuts you made
  Scaling analysis (bottlenecks, what breaks first at load)
  Testing strategy and what you'd test with more time
  What you'd build in a week vs. what you built in a few hours


flesh this stuff out!

check indexes again; gonna need the composite index to support the filtering on the list endpoint

Did not use LLM with wild abandon but I do have Copilot enabled in my editor (though it sometimes screws me up more than helps)

Used scaffold as starting point but diverged plenty

Maybe it was a waste of time to add Credo, Sobelow, Mix Audit and wired up CI but it seemed best to work my usual workflow. I also made branches and pull requests, as I would at work.

I initially thought I would do a regular has_many assoc for the Task's Attempt but then I decided they are basically just internal progress indicators so an embeds_many seemed fine. I considered the idea of just querying Oban but decided that that could depend on Oban's schema and that could change. On the other hand, this app is not going to live long so that's kind of silly. But again, I tried to do everything as I would on a real project.

I couldn't help but think, however, that I'm basically recreating Oban's lifecycle logic. But jobs can be pruned, Tasks stay forever

For testing with the failure chance, I considered an App env flag but that would affect the ability to keep tests async.
At my current job, however, I did some serious digging on our large test suite to try to get more sync tests (due to app env use) to be async. I ultimately discovered that there wasn't much benefit because the Github runners were quad-core. So we could only have 4 tests running in parallel. The number of async tests vastly outnumbered the sync tests. I did make sure, however, that tests using app env were in modules that did async: false. Also interesting: we wound up with so many migrations that those took about as much time as the tests did. I campaigned for rolling those up but could never get buy-in.

I initially used dependency injection for the Task failure/success (and skipping the sleep) logic but when I got to the Oban job testing I realized I had to use Mox because Oban.Worker.perform and Oban.Testing.perform_job are single-arity.

I don't really have a real state machine but this is all taking me longer than expected. The task status change is all handled by internal logic so it doesn't seem like enforcing state transitions is that required. I'd probably introduce that on a big team with varied levels though, just to call out incorrect logic before it is even in a pull request.

I considered doing separate queues per priority but just went with the default queue to avoid making 4 workers (though I think I can pick queue at enqueue time). In a real app I would probably do that... although I probably wouldn't replicate so much of what Oban does in a real app... I think.

Also did not bother with Oban uniqueness constraints since the jobs are enqued by internal logic and only one will be in flight at a time. That's the hope anyway.

The default ordering (priority then inserted_at) is in place but I'm skipping the inserted_at test to save time (heh, almost a double entendre there)

I started a branch where I pulled in the [Flop](https://hex.pm/packages/flop) library  since it would give me cursor-based pagination and filtering (and also sorting if we wanted to give that option to users). That also would have given me parameter validation. Not that I've really seen a lot of places guard against script-kiddies playing with query params. It's just another Sentry error that we can ignore, right? Heh.

I really wanted to get to at least one extra credit piece so I pulled in the [Nebulex](https://nebulex.hexdocs.pm/Nebulex.html) caching library which I used on a previous project at my current job (though with the Redis adapter). I just added the Cache module ("using" Nebulex) and wired it up in the controller. I would probably prefer to keep that in the context but it was easier to just add it in the controller with a TTL for now. Invalidation for this could be tricky because if there is a lot of task creation going on and tasks running all the time then invalidating the cache for every action would probably mean we get mostly, if not all, cache misses. I would probably keep it as a TTL until we verify the load we're going to have.

Almost forgot about the composite indexing question. I've been debating over a composite on the three filterable columns vs indexes on each column. Searching seems to suggest that Postgres is smart enough to combine the individual indexs.

Here's the explain analyze output:

```
"Seq Scan on tasks t0  (cost=0.00..2.44 rows=1 width=273) (actual time=0.030..0.030 rows=0 loops=1)\n  Filter: ((status = 'queued'::task_status_type) AND (type = 'import'::task_title_type) AND (priority = 'critical'::task_priority_type))\n  Rows Removed by Filter: 25\nPlanning Time: 2.109 ms\nExecution Time: 0.059 ms"
```
for a query with all three filters:

```
query = from(t in Task, where: t.status == ^:queued and t.type == ^:import and t.priority == ^:critical)
```

and without any index. And here's the explain analyze after:

```
"Seq Scan on tasks t0  (cost=0.00..2.44 rows=1 width=273) (actual time=0.020..0.021 rows=0 loops=1)\n  Filter: ((status = 'queued'::task_status_type) AND (type = 'import'::task_title_type) AND (priority = 'critical'::task_priority_type))\n  Rows Removed by Filter: 25\nPlanning Time: 1.862 ms\nExecution Time: 0.045 ms"
```

It did shave some time off but I'm still getting a seq scan... though I think that's because I don't have very many rows.

Well, it's something. Better wrap this up and send it in.



- Pagination?! - or just put a limit on the list action for now; last 100? Actually Flop would give me filtering and sorting too
- Metric GenServer
- caching?
- Supervisor?
- PubSub?
- Sharding Oban?
- Oban pruning: can prune pretty aggressively, I would think