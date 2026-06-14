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

- Pagination?! - or just put a limit on the list action for now; last 100? Actually Flop would give me filtering and sorting too
- Metric GenServer
- caching?
- Supervisor?
- PubSub?
- Sharding Oban?
- Oban pruning: can prune pretty aggressively, I would think