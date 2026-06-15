# TaskMaster Notes

## Intro

Okay, first off, I want to say that this is a great code challenge! It is actually the sort of work that most of us do all day every day. 

That said I'm amazed that anyone does all this in 3-5 hours! Maybe if you're prompting an agent for everything. I opted not to take that route as I figured I should actually use my skills for a coding challenge... plus, the time was theorectically open-ended. 

I do have Copilot enabled in my editor, but it sometimes screws me up more than helps. Also, I don't pay for it so I ran out of free inline suggestions early today. I did ask a few questions in its chat and there (still got plenty of credits for that).

So yeah, I devoted my weekend to this. I spent some time Friday night looking over the instructions and starting my notes as to what I wanted to do. Then I worked most of Saturday afternoon setting up the initial app and and building out the model and controller. Then I spent pretty much all day today, non-stop, building out the rest. Maybe I'm not as senior as I thought I was? Heh.

I will say that, even though I love the guts of this challenge, most devs work on existing apps in a well-trodden niche, adding features and fixing bugs. Cramming and jamming on a new app doesn't seem that typical. Though I guess if your company is cranking out microservices.... Still, a typical work stream would be working from well-defined tickets. Hopefully slow and steady (which always wins the race).

Also, I have wicked test anxiety. Thank you for not making this have a hard stop! As it is, I still spent way too much time thinking that it was taking longer than it should and maybe I'm dumber than I thought... classic imposter syndrome. Oh, and my current job has been not keeping me busy at all so I'm rusty.

But whatever. I hope that doesn't sound like a bunch of excuses. I'm happy to spend a weekend banging on this. It took me what it took me. I hope my attention to detail comes through and the fact that I always strive to do the best job possible.

## Implementation Notes

As mentioned above, I did not just have an LLM spit out every lick of code. I accepted some Copilot suggestions and wrote lots of stuff freehand. I used the `phx.gen.json` scaffold as starting point but diverged plenty.

Maybe it was a waste of time to add Credo, Sobelow, Mix Audit and wired up CI but it seemed best to work my usual workflow. I also made branches and pull requests, as I would at work. And I probably paid more attention to tidiness and nits than I should have. But I like to make a repo as I would always do it. No reason to make anyone look at a mess!

I didn't bother creating any seeds. There is only one model and it is the entity that the API creates and reports. What would I seed? I did add a couple homespun factory/fixture functions though.

## Attempt Modeling

I initially thought I would do a regular `has_many` assoc for the Task's `Attempt` but then I decided they are basically just internal progress indicators so an `embeds_many` seemed fine. 

I considered the idea of just querying Oban but decided that that could depend on Oban's schema and that could change. On the other hand, this app is not going to live long so that's kind of silly. But again, I tried to do everything as I would on a real project.

## Failure Chance

For testing with the failure chance, I considered an App env flag but that would affect the ability to keep tests async.
At my current job, however, I did some serious digging on our large test suite to try to get more sync tests (due to app env use) to be async. 

I ultimately discovered that there wasn't much benefit because the Github runners were quad-core. So we could only have 4 tests running in parallel. The number of async tests vastly outnumbered the sync tests. I did make sure, however, that tests using app env were in modules that did `async: false`. 

Also interesting: we wound up with so many migrations that those took about as much time in CI as the tests did. I campaigned for rolling those up but could never get buy-in.

Anyway, I initially used dependency injection for the Task failure/success (and skipping the sleep) logic but when I got to the Oban job testing I realized I had to use Mox because `Oban.Worker.perform` and `Oban.Testing.perform_job` are single-arity.

## State Machine/Oban

I don't really have a real state machine here but this took me way me longer than I expected. The task status change is all handled by internal logic so it doesn't seem like enforcing state transitions is that necesary. I'd probably introduce that on a big team with varied levels of ability though, just to call out incorrect logic before it is even in a pull request. It would be more robust and correct.

I considered doing separate queues per priority but just went with the default queue to avoid making four workers (though I think I can probably pick queue at enqueue time). In a real app I would probably do that... although I probably wouldn't replicate so much of what Oban does in a real app... I think. :-p

Also did not bother with Oban uniqueness constraints since the jobs are enqued by internal logic and only one will be in flight at a time. That's the hope anyway.

I didn't set up the Oban pruning but I would think we could prune pretty savagely since the Task is keeping track of the state and other details. Our Oban shadow. I thought about adding Oban Web just to see jobs run but I've had an insane weekend as it is.

And sorry, I didn't really have time to think much about Oban sharding. We have a ton of Oban workers at my current job and didn't bother with sharding. On the other hand, the system invovles a lot of microservices (handling all external comms outside of the main app) so each of those have its own Oban server. That is kind of sharding by default. 

Also, though the entire system was built to eventually handle all orders and procesing for dozens of brands across hundreds of sites, we actually only rolled it out for one brand in three regions before the project was cancelled. If we had brought on a lot more brands I'm sure we would have had to look into splitting up Oban more.

## Ordering/Filtering/Pagination

The default ordering (priority then `inserted_at`) is in place but I'm skipping the `inserted_at` test to save time (heh, almost a double entendre there).

I started a branch where I pulled in the [Flop](https://hex.pm/packages/flop) library since it would give me cursor-based pagination *and* filtering (and also sorting if we wanted to give that option to users). That also would have given me parameter validation. Not that I've really seen a lot of places guard against script-kiddies playing with query params. It's just another Sentry error that we can ignore, right? Heh.

## Caching For Credit

I really wanted to get to at least one extra credit piece so I pulled in the [Nebulex](https://nebulex.hexdocs.pm/Nebulex.html) caching library which I used on a previous project at my current job (though with the Redis adapter). I just added the Cache module ("using" Nebulex) and wired it up in the controller. I just used a TTL of 2 minutes as a start.

Invalidation for this could be tricky because if there is a lot of task creation going on and tasks running all the time then invalidating the cache for every action would probably mean we get mostly, if not all, cache misses. I would probably keep it as a TTL until we verify the load we're going to have.

## PubSub

Heh, PubSub is being started in Application. It comes out of the generator that way. I should have added a quick broadcast call and maybe just read it and log it somewhere else. Oh yeah, the MetricServer (see below) could have listened for events and updated its tallies fromt that. This is making me sad that I didn't try this.

## Additional Supervision

I did not get around to adding another Supervisor or even setting restart policies on what I do have. I will say that at my current job we have tons of Oban jobs/workflows and lots of Broadway pipelines, plus two Repos, Telemetry, two Redis caches, etc and we only have child Supervisors for the Broaday Pipelines and the GRPC servers. Everything just uses the default restart logic.

## MetricServer

I thought about it! Seems like a neat idea and the GenServer itself wouldn't be too much work. Deriving the metrics would be more work, I think. I actually made the `TaskMaster.Tasks.Task.Attempt` record `started_at` and `ended_at` to be able to get durations. Oh well.

I guess it is worth pointing out that I haven't written a single GenServer at my current job. We went all in on Oban Pro. Everything not in the main request process is in Oban Jobs or Broadway Pipelines. A need for a bespoke GenServer never came up.

At my job before that, I wrote some GenServers on my first team. I can't remember the exact use case but I remember some pain trying to get some timing issue right. This is why I generally prefer a solid, well-maintained library with lots of eyes on it. The second team I was on there had no custom GenServers because it was all DynamicSupervisors spun up to process the order translation work to send it to an external point-of-sale system.

## Composite Indexing?

Almost forgot about the composite indexing question. I've been debating over a composite on the three filterable columns vs indexes on each column. Searching seems to suggest that Postgres is smart enough to combine the individual indexs.

Here's the explain analyze output without any index:

```
"Seq Scan on tasks t0  (cost=0.00..2.44 rows=1 width=273) (actual time=0.030..0.030 rows=0 loops=1)\n  Filter: ((status = 'queued'::task_status_type) AND (type = 'import'::task_title_type) AND (priority = 'critical'::task_priority_type))\n  Rows Removed by Filter: 25\nPlanning Time: 2.109 ms\nExecution Time: 0.059 ms"
```
for a query with all three filters:

```
query = from(t in Task, where: t.status == ^:queued and t.type == ^:import and t.priority == ^:critical)
```

And here's the explain analyze after adding the individual indexes:

```
"Seq Scan on tasks t0  (cost=0.00..2.44 rows=1 width=273) (actual time=0.020..0.021 rows=0 loops=1)\n  Filter: ((status = 'queued'::task_status_type) AND (type = 'import'::task_title_type) AND (priority = 'critical'::task_priority_type))\n  Rows Removed by Filter: 25\nPlanning Time: 1.862 ms\nExecution Time: 0.045 ms"
```

It did shave some time off but I'm still getting a seq scan... though I think that's because I don't have very many rows.

# Conclusion

I better wrap this up and send it in. If I had more time, I would probably comb through this to look for untested edge-cases. I would also love to whip up that MetricServer and have it subscribe to PubSub updates. 

I think the Supervisor setup is fine for an initial launch but we would definitely want to look at load and carefully consider throughput. Oh and I didn't touch the Telemetry at all... it's just what came for free. Observability is important! (As long as someone actually reads it.)

Also obviousliy did not even consider production stuff; deploys and whatnot. That's work too.

Really there are so many ideas and options to look at. And this is only a single-model system! It's amazing how much work it is just to spin up something like this

Thank you for this opportunity!

Ben Munat
