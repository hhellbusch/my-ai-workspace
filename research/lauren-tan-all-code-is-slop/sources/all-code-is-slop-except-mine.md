# Transcript: All Code Is Slop (Except Mine) — Lauren Tan, SpaceXSI

- **Channel:** AI Engineer
- **URL:** https://www.youtube.com/watch?v=O_zcc6Xl12g
- **Duration:** 17:16
- **Fetched:** 2026-11-16 21:47:05
- **Segments:** 470

---

**[0:00]** [music] >> All right. Um so again I'm my name is Potato. Uh I work on Grokbot at SpaceX SI.

**[0:20]** And can I just get a quick show of hands? How many of you have ever looked at code that somebody else wrote and you thought that's all slop.

**[0:27]** Well, I have too.

**[0:32]** But today I'm going to convince you that you can turn that slop into gold.

**[0:36]** Uh and so I did something crazy last month and I shipped 3,000 pull requests to production.

**[0:47]** Now before agents we never really cared about volume uh except for the outliers.

**[0:50]** And at my previous company we called these people coding machines. People like Brett Taylor who famously rewrote all of Google Maps uh in a weekend.

**[1:00]** Just an insanely productive engineer.

**[1:03]** Uh and well with agents anyone can now be a coding machine. And my thesis is that the job of the software engineer, the meta of being a software engineer is figuring out how to maintain or even improve the quality of your code while massively increasing your productivity.

**[1:20]** To get there some people like to call this a software factory. Uh but I like to keep it simple and I think of it as all about trust.

**[1:30]** Not blind trust but investing in your agents environment so you can trust that your agents are going to do the right thing.

**[1:39]** Now it takes quite a lot of effort to get there um and it took me six months to get to a point where I could ship thousands of pull requests, a lot of them in my sleep.

**[1:49]** But it's certainly possible and it will take you much less time than I did.

**[1:53]** So let's start by talking about how we move from a low trust to a high-trust one.

**[1:59]** So, this inverse pyramid is how I think about where to spend time on your agent's environment.

**[2:07]** The first two layers are deterministic, so using your code itself. So, things like good API design, architecture, refactoring, or using lint rules, type systems, compilers, or you know, different kinds of testing.

**[2:22]** And you can use both of these layers together to constrain what agents can do and force them to do the right thing by default.

**[2:30]** Verification, both runtime and formal, are great tools to layer on to find bugs and check properties and the invariance in your system that you want to hold true and also help you check whether or not the agent understood your goals and your intent.

**[2:46]** And then finally, you want to layer with a little bit of prose. So, things like rules, skills, agents.md, things that require judgment.

**[2:56]** But let's start with your codebase.

**[2:59]** Agents generate their outputs based on their inputs. And so the the quality of the input really matters, and it just so happens that your codebase is one of the largest inputs.

**[3:10]** So, whenever you're correcting your agent, think about how you can make that a deterministic check instead of adding another line to your rules or your agents.md because it's far more reproducible when it's in code and it lets you trust it more.

**[3:24]** And the analogy that I like to use is that your codebase is kind of like a garden.

**[3:31]** You know, code used to arrive a few pull requests at a time.

**[3:34]** And uh I remember going into work in 2024 and reviewing the three pull requests that my colleagues wrote colleagues wrote.

**[3:42]** And today, that number is more like 300.

**[3:44]** So, you know, every engineer is now a team of hundreds or even thousands of agents, and code is arriving so rapidly that it almost feels like a continuous stream, and it almost feels organic, like a living thing.

**[4:01]** And in this analogy, your codebase, the constraints that you impose, the guardrails that you put up are the concrete foundations that the new code that your agents write grow around, just like uh the building in this picture.

**[4:15]** And so in many ways, the job of being a software engineer is kind of becoming like gardening.

**[4:21]** Because code is the biggest input for agents, it means that any workarounds, um anti-patterns, deprecated code, tech debt, it's now likely to be just copied by the next agent since it looks like the established pattern in your codebase.

**[4:38]** And uh it's like you have some weeds or pests growing in your garden, and then they spread everywhere before you know it.

**[4:47]** So you want to make your codebase as pristine as possible so that agents are always copying the good stuff.

**[4:55]** All right, let's look at some real examples.

**[4:59]** Uh so Dune is a client framework that we created for Graph Bot to implement this idea for organic architecture.

**[5:05]** It's not really that interesting technically. Uh you can kind of think of Dune as um kind of like Next.js for Electron apps.

**[5:14]** But the interesting part of Dune is that it has a lot of constraints and lint rules that we've encoded uh a lot of the lessons that we've learned building desktop applications.

**[5:23]** And one such lesson is that anything that requires nuance to use well often leads to slop.

**[5:31]** Uh you know your classic example is uh you know use effect in React, right? It has its use cases, uh but it's often misused. You know some people joke that you need a PhD to use use effect.

**[5:42]** Um and in in other words, it really requires a lot of nuance to use well.

**[5:46]** And agents are not good at using it.

**[5:50]** Um so our solution has been to just ban it in product code, and it's really only allowed in some places inside of Dune APIs.

**[6:00]** And effectively, this problem has now been categorically eliminated, and we never need to catch that during code review again.

**[6:08]** Another interesting pattern that we use is context through directory structure.

**[6:12]** Uh so one anti-pattern that we saw with Cursor, which is an Electron app, is that agents would often import main thread code into the renderer thread, which would cause long tasks and jank.

**[6:25]** So in uh Gulp bot and in Dunanaps, we've made this very very conventional.

**[6:30]** Uh we have these two top-level directories literally called Electron renderer and Electron main, and imports between them are forbidden or banned by our dependency graph analyzer and some lint rules.

**[6:43]** And again, you know, these are simple lint rules to set up, but it means one less thing that we need to review and think about uh you know, during code review.

**[6:53]** And then one more surprising thing that I've seen is agents using Markdown. So things like documentation, uh code comments, rules or skills, and they use this as a place to write down their justifications for not doing the right thing. Or I don't know if you've ever seen this, but they'll over rotate on some small correction that you made, and they treat it like a hard rule that can never be broken ever again.

**[7:19]** And here's another example from Cursor.

**[7:22]** So agents really loved using imperative timers, so things like set timeout, request animation frame, request idle callback. And they were using these as quick fixes because they were really patching over an architecture clash between uh VS Code's imperative style and React's declarative style.

**[7:41]** So our choice of architecture actually made both the client and the agent performance much worse.

**[7:49]** And if you've ever done any performance work in JavaScript, you'll know that when you have tons of timers being rapidly created and destroyed, causes a lot of uh major garbage collection, which causes a lot of lag and jank.

**[8:00]** Uh but the worst part is that agents wrote a a of code comments, like you can see in red here, explaining why this quick fix was justified.

**[8:09]** And before you know it, we had timers spreading everywhere and the you know the performance of the app really suffered.

**[8:17]** Now in Grabot, uh we learned our lesson there and we decided to just ban 99% of comments uh because they go stale easily. Uh you know humans just really don't bother reading the comment slot anyway.

**[8:31]** And again it gives an agent the an escape hatch to justify not doing the right thing because it's hard.

**[8:38]** Um and the worst part about comments though is that they're not enforceable.

**[8:42]** So what seems well intentioned, you know like I'm going to tell the the next agent not to do something, never ends up actually being anything that you can trust.

**[8:52]** So in Grabot and Dune and in Dune uh we now have lint rules that give uh good and very helpful error messages telling the agent to fix the root cause, the real problem uh rather than just patch around it.

**[9:07]** And so our general principle is that every time we correct our agents, it turns into one of these deterministic checks or we think about how to categorically eliminate that problem in the code through better API design, through better architecture.

**[9:21]** And if you do this enough times, you'll find that you have just less things to look out for in code review.

**[9:28]** And at some point you'll realize there's there's nothing left to review.

**[9:32]** And you can just let agents merge their most of their own pull requests.

**[9:36]** All right. Uh moving on, verification is also a really big part of how we make our agent more autonomous and also increase our confidence and trust in their work.

**[9:49]** And our code review process has now really shrunk into looking at verification artifacts instead. So things like videos, screenshots, diagrams, formal verification.

**[9:58]** Um and the most basic example of this is runtime verification uh which is just a fancy way of saying giving your agent a way to run the code for itself and use debugging tools that, you know, human developers use as well, like the Chrome DevTools protocol.

**[10:13]** Um, in our runtime verification skills, we have this thing that we call a feature map.

**[10:20]** And that's basically kind of like a site map of all of the features that are available in your application from the user's point of view.

**[10:27]** And so with this, agents don't need to guess when you say, you know, the thingy in the left sidebar, it gives you some shared vocabulary.

**[10:34]** And we also make use of custom CLIs inside these skills so that agents can reuse the the CLI and the driver every time, which cuts down on token usage and is also testable.

**[10:47]** Um, and then recently we've also started looking at formal verification.

**[10:52]** Uh, so we now use TLA Plus to do some model checking of major user flows such as notifications across multiple devices and platforms.

**[11:01]** Uh, we use a lean as well for proving certain algorithms.

**[11:04]** Uh, for example, we have our own we wrote our own custom virtualization library and we use lean there to check that we don't have, you know, flickering or jittering problems.

**[11:13]** Um, and we're still experimenting with this approach overall. It seems very promising. Uh, we've already found quite a few bugs with formal verification.

**[11:21]** Uh, but it's certainly not a silver bullet and we're treating it as another tool, another layer in our agents' environment.

**[11:33]** Uh, and then this is a very fast video, but another thing that we just started looking at is property-based testing as well for UIs.

**[11:41]** Uh, so we use this library called Bombadil.

**[11:44]** Um, and this has also caught a few UI bugs for us already.

**[11:47]** Okay, so zooming out, I saw this tweet from Cindy and 6 months ago she she said that she was oh, she was talking about not being able to trust her agents because of subtle bugs that were getting merged.

**[12:01]** And really what was missing for her in being able to trust her agents was the verification process. And now, 6 months later, she says that 70% of her daily tokens go into verification. And I'd say that that tracks with what I see as well, that most of my token usage goes to verification.

**[12:20]** And if you really look closely at her process, none of these things here are new or novel techniques that we've never had before.

**[12:28]** These are just good software engineering tools, but ones that might have been prohibitively expensive to use before as they were hard to understand or write or maintain.

**[12:39]** But agents drastically cut this cost down.

**[12:41]** And really, we are entering a golden age of software testing and verification because agents let us test everything to a much greater degree than used to be economical.

**[12:52]** And then formal verification can also help you better reason about how your product should work and whether your agents really understand your intent and goals.

**[13:01]** Uh I made this new skill called state chart uh in my plugin P stack, potato stack, uh which helps you visualize state machines from uh from the user's point of view.

**[13:11]** Uh and it's I find this much easier to review alongside the videos and screenshots that we provide.

**[13:16]** Um and so that's been great.

**[13:18]** Sorry for the flashback.

**[13:21]** Uh okay, now let's look at what the promised land looks like. What do you get in return for all of this uh you know investment?

**[13:29]** So on the Growth Bot team, our velocity is uh taking off and rapidly increasing.

**[13:34]** And last month, our team shipped a ridiculous 11,000 pull requests to production, which is a wild number.

**[13:44]** And our pace of releasing the client has also increased. And we cut a new stable version about once a day.

**[13:50]** And then the core team is also shipping much more. And we also have uh a lot more casual or drive-by contributors who don't always have a lot of context, uh but they're also contributing. Um and in October, we had about 227 people who contributed at least one pull request.

**[14:10]** So So this velocity accelerating, you might be thinking to yourself like isn't this going to be chaos? You know, isn't this going to be a bunch of slop?

**[14:19]** But actually, the number of PRs that get reverted has actually gotten lower on a relative basis and is steady at about half a percent.

**[14:27]** But I think the really interesting thing about this shipping pace and this volume of pull requests is that the performance of Graph Bot has stayed not just stable, but has improved on multiple dimensions compared to when we launched. So startup, typing, opening new chats, switching chats, all of this has gotten faster.

**[14:49]** And keep in mind, Graph Bot is still an Electron app for now.

**[14:55]** So there is a ceiling, right? But it's already much faster than many other agent UIs out there.

**[15:00]** And for an Electron app with this high velocity and this many people contributing, I'd say that's pretty good.

**[15:08]** So before you jump into building out a software factory and you know, automating everything that you can, whenever you correct your agent, try and do it by improving your codebase first.

**[15:18]** You know, start with a lint rule to prevent new occurrences of anti-patterns and then clean up those old patterns as well.

**[15:27]** And then make sure that your verification story is really strong.

**[15:29]** A lot of this work is a prerequisite to automation anyway. And if your inner coding loop produces slop, then automating that loop just produces more slop and you need to throw more and more and more tokens at the problem, which we all know is very expensive.

**[15:46]** And once you meet these investments into, you know, code into your codebase, static analysis, runtime informal verification, you'll start to find that many things become possible with these foundations and that you can really easily build your own factory on top of these foundations.

**[16:04]** And when you're ready, Graph Bot is a great way to build that outer loop. We have tons of connectors, routines that can kick off cursor, cloud agents, and projects uh which let you orchestrate thousands of uh hundreds or even thousands of agents.

**[16:19]** And as a quick example, you know, whenever we cut a new release now, Grokbot will automatically spin up a new cursor project for us that will fuzz the entire application, the entire build, and it will find bugs uh by running the app and using it like a real user.

**[16:33]** And then it's going to open fixed PRs for each of those bugs that it finds and it's going to auto merge it as uh crazy as that sounds. And that's because our codebase is good enough that pull requests tend to just be good by default and most product code that we land no longer really requires deep human review.

**[16:53]** So when you have solid foundations and good organic architecture, you can turn slop into gold and you can ship with high quality uh high velocity without compromising on quality.

**[17:08]** My name is Potato, also known as Lauren.

**[17:09]** Thanks to you again for listening to my talk.

**[17:13]** >> [applause]

---

## Plain Text

[music] >> All right. Um so again I'm my name is Potato. Uh I work on Grokbot at SpaceX SI. And can I just get a quick show of hands? How many of you have ever looked at code that somebody else wrote and you thought that's all slop. Well, I have too. But today I'm going to convince you that you can turn that slop into gold. Uh and so I did something crazy last month and I shipped 3,000 pull requests to production. Now before agents we never really cared about volume uh except for the outliers. And at my previous company we called these people coding machines. People like Brett Taylor who famously rewrote all of Google Maps uh in a weekend. Just an insanely productive engineer. Uh and well with agents anyone can now be a coding machine. And my thesis is that the job of the software engineer, the meta of being a software engineer is figuring out how to maintain or even improve the quality of your code while massively increasing your productivity. To get there some people like to call this a software factory. Uh but I like to keep it simple and I think of it as all about trust. Not blind trust but investing in your agents environment so you can trust that your agents are going to do the right thing. Now it takes quite a lot of effort to get there um and it took me six months to get to a point where I could ship thousands of pull requests, a lot of them in my sleep. But it's certainly possible and it will take you much less time than I did. So let's start by talking about how we move from a low trust to a high-trust one. So, this inverse pyramid is how I think about where to spend time on your agent's environment. The first two layers are deterministic, so using your code itself. So, things like good API design, architecture, refactoring, or using lint rules, type systems, compilers, or you know, different kinds of testing. And you can use both of these layers together to constrain what agents can do and force them to do the right thing by default. Verification, both runtime and formal, are great tools to layer on to find bugs and check properties and the invariance in your system that you want to hold true and also help you check whether or not the agent understood your goals and your intent. And then finally, you want to layer with a little bit of prose. So, things like rules, skills, agents.md, things that require judgment. But let's start with your codebase. Agents generate their outputs based on their inputs. And so the the quality of the input really matters, and it just so happens that your codebase is one of the largest inputs. So, whenever you're correcting your agent, think about how you can make that a deterministic check instead of adding another line to your rules or your agents.md because it's far more reproducible when it's in code and it lets you trust it more. And the analogy that I like to use is that your codebase is kind of like a garden. You know, code used to arrive a few pull requests at a time. And uh I remember going into work in 2024 and reviewing the three pull requests that my colleagues wrote colleagues wrote. And today, that number is more like 300. So, you know, every engineer is now a team of hundreds or even thousands of agents, and code is arriving so rapidly that it almost feels like a continuous stream, and it almost feels organic, like a living thing. And in this analogy, your codebase, the constraints that you impose, the guardrails that you put up are the concrete foundations that the new code that your agents write grow around, just like uh the building in this picture. And so in many ways, the job of being a software engineer is kind of becoming like gardening. Because code is the biggest input for agents, it means that any workarounds, um anti-patterns, deprecated code, tech debt, it's now likely to be just copied by the next agent since it looks like the established pattern in your codebase. And uh it's like you have some weeds or pests growing in your garden, and then they spread everywhere before you know it. So you want to make your codebase as pristine as possible so that agents are always copying the good stuff. All right, let's look at some real examples. Uh so Dune is a client framework that we created for Graph Bot to implement this idea for organic architecture. It's not really that interesting technically. Uh you can kind of think of Dune as um kind of like Next.js for Electron apps. But the interesting part of Dune is that it has a lot of constraints and lint rules that we've encoded uh a lot of the lessons that we've learned building desktop applications. And one such lesson is that anything that requires nuance to use well often leads to slop. Uh you know your classic example is uh you know use effect in React, right? It has its use cases, uh but it's often misused. You know some people joke that you need a PhD to use use effect. Um and in in other words, it really requires a lot of nuance to use well. And agents are not good at using it. Um so our solution has been to just ban it in product code, and it's really only allowed in some places inside of Dune APIs. And effectively, this problem has now been categorically eliminated, and we never need to catch that during code review again. Another interesting pattern that we use is context through directory structure. Uh so one anti-pattern that we saw with Cursor, which is an Electron app, is that agents would often import main thread code into the renderer thread, which would cause long tasks and jank. So in uh Gulp bot and in Dunanaps, we've made this very very conventional. Uh we have these two top-level directories literally called Electron renderer and Electron main, and imports between them are forbidden or banned by our dependency graph analyzer and some lint rules. And again, you know, these are simple lint rules to set up, but it means one less thing that we need to review and think about uh you know, during code review. And then one more surprising thing that I've seen is agents using Markdown. So things like documentation, uh code comments, rules or skills, and they use this as a place to write down their justifications for not doing the right thing. Or I don't know if you've ever seen this, but they'll over rotate on some small correction that you made, and they treat it like a hard rule that can never be broken ever again. And here's another example from Cursor. So agents really loved using imperative timers, so things like set timeout, request animation frame, request idle callback. And they were using these as quick fixes because they were really patching over an architecture clash between uh VS Code's imperative style and React's declarative style. So our choice of architecture actually made both the client and the agent performance much worse. And if you've ever done any performance work in JavaScript, you'll know that when you have tons of timers being rapidly created and destroyed, causes a lot of uh major garbage collection, which causes a lot of lag and jank. Uh but the worst part is that agents wrote a a of code comments, like you can see in red here, explaining why this quick fix was justified. And before you know it, we had timers spreading everywhere and the you know the performance of the app really suffered. Now in Grabot, uh we learned our lesson there and we decided to just ban 99% of comments uh because they go stale easily. Uh you know humans just really don't bother reading the comment slot anyway. And again it gives an agent the an escape hatch to justify not doing the right thing because it's hard. Um and the worst part about comments though is that they're not enforceable. So what seems well intentioned, you know like I'm going to tell the the next agent not to do something, never ends up actually being anything that you can trust. So in Grabot and Dune and in Dune uh we now have lint rules that give uh good and very helpful error messages telling the agent to fix the root cause, the real problem uh rather than just patch around it. And so our general principle is that every time we correct our agents, it turns into one of these deterministic checks or we think about how to categorically eliminate that problem in the code through better API design, through better architecture. And if you do this enough times, you'll find that you have just less things to look out for in code review. And at some point you'll realize there's there's nothing left to review. And you can just let agents merge their most of their own pull requests. All right. Uh moving on, verification is also a really big part of how we make our agent more autonomous and also increase our confidence and trust in their work. And our code review process has now really shrunk into looking at verification artifacts instead. So things like videos, screenshots, diagrams, formal verification. Um and the most basic example of this is runtime verification uh which is just a fancy way of saying giving your agent a way to run the code for itself and use debugging tools that, you know, human developers use as well, like the Chrome DevTools protocol. Um, in our runtime verification skills, we have this thing that we call a feature map. And that's basically kind of like a site map of all of the features that are available in your application from the user's point of view. And so with this, agents don't need to guess when you say, you know, the thingy in the left sidebar, it gives you some shared vocabulary. And we also make use of custom CLIs inside these skills so that agents can reuse the the CLI and the driver every time, which cuts down on token usage and is also testable. Um, and then recently we've also started looking at formal verification. Uh, so we now use TLA Plus to do some model checking of major user flows such as notifications across multiple devices and platforms. Uh, we use a lean as well for proving certain algorithms. Uh, for example, we have our own we wrote our own custom virtualization library and we use lean there to check that we don't have, you know, flickering or jittering problems. Um, and we're still experimenting with this approach overall. It seems very promising. Uh, we've already found quite a few bugs with formal verification. Uh, but it's certainly not a silver bullet and we're treating it as another tool, another layer in our agents' environment. Uh, and then this is a very fast video, but another thing that we just started looking at is property-based testing as well for UIs. Uh, so we use this library called Bombadil. Um, and this has also caught a few UI bugs for us already. Okay, so zooming out, I saw this tweet from Cindy and 6 months ago she she said that she was oh, she was talking about not being able to trust her agents because of subtle bugs that were getting merged. And really what was missing for her in being able to trust her agents was the verification process. And now, 6 months later, she says that 70% of her daily tokens go into verification. And I'd say that that tracks with what I see as well, that most of my token usage goes to verification. And if you really look closely at her process, none of these things here are new or novel techniques that we've never had before. These are just good software engineering tools, but ones that might have been prohibitively expensive to use before as they were hard to understand or write or maintain. But agents drastically cut this cost down. And really, we are entering a golden age of software testing and verification because agents let us test everything to a much greater degree than used to be economical. And then formal verification can also help you better reason about how your product should work and whether your agents really understand your intent and goals. Uh I made this new skill called state chart uh in my plugin P stack, potato stack, uh which helps you visualize state machines from uh from the user's point of view. Uh and it's I find this much easier to review alongside the videos and screenshots that we provide. Um and so that's been great. Sorry for the flashback. Uh okay, now let's look at what the promised land looks like. What do you get in return for all of this uh you know investment? So on the Growth Bot team, our velocity is uh taking off and rapidly increasing. And last month, our team shipped a ridiculous 11,000 pull requests to production, which is a wild number. And our pace of releasing the client has also increased. And we cut a new stable version about once a day. And then the core team is also shipping much more. And we also have uh a lot more casual or drive-by contributors who don't always have a lot of context, uh but they're also contributing. Um and in October, we had about 227 people who contributed at least one pull request. So So this velocity accelerating, you might be thinking to yourself like isn't this going to be chaos? You know, isn't this going to be a bunch of slop? But actually, the number of PRs that get reverted has actually gotten lower on a relative basis and is steady at about half a percent. But I think the really interesting thing about this shipping pace and this volume of pull requests is that the performance of Graph Bot has stayed not just stable, but has improved on multiple dimensions compared to when we launched. So startup, typing, opening new chats, switching chats, all of this has gotten faster. And keep in mind, Graph Bot is still an Electron app for now. So there is a ceiling, right? But it's already much faster than many other agent UIs out there. And for an Electron app with this high velocity and this many people contributing, I'd say that's pretty good. So before you jump into building out a software factory and you know, automating everything that you can, whenever you correct your agent, try and do it by improving your codebase first. You know, start with a lint rule to prevent new occurrences of anti-patterns and then clean up those old patterns as well. And then make sure that your verification story is really strong. A lot of this work is a prerequisite to automation anyway. And if your inner coding loop produces slop, then automating that loop just produces more slop and you need to throw more and more and more tokens at the problem, which we all know is very expensive. And once you meet these investments into, you know, code into your codebase, static analysis, runtime informal verification, you'll start to find that many things become possible with these foundations and that you can really easily build your own factory on top of these foundations. And when you're ready, Graph Bot is a great way to build that outer loop. We have tons of connectors, routines that can kick off cursor, cloud agents, and projects uh which let you orchestrate thousands of uh hundreds or even thousands of agents. And as a quick example, you know, whenever we cut a new release now, Grokbot will automatically spin up a new cursor project for us that will fuzz the entire application, the entire build, and it will find bugs uh by running the app and using it like a real user. And then it's going to open fixed PRs for each of those bugs that it finds and it's going to auto merge it as uh crazy as that sounds. And that's because our codebase is good enough that pull requests tend to just be good by default and most product code that we land no longer really requires deep human review. So when you have solid foundations and good organic architecture, you can turn slop into gold and you can ship with high quality uh high velocity without compromising on quality. My name is Potato, also known as Lauren. Thanks to you again for listening to my talk. >> [applause]