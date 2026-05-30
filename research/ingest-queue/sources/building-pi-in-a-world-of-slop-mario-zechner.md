# Transcript: Building pi in a World of Slop — Mario Zechner

- **Channel:** AI Engineer
- **URL:** https://www.youtube.com/watch?v=RjfbvDXpFls
- **Duration:** 18:11
- **Fetched:** 2026-05-30 18:41:59
- **Segments:** 563

---

**[0:00]** [music] >> Hey there. I'm Mario. I built pie in a world of slop and this is a tragedy tragedy in three acts. Just to talk about this real quick. Bunch of people on the internet gave me money for ad space on my torso and all of that goes to a charity. So, yeah, thanks guys.

**[0:26]** So, act one, building pie. In the beginning there was cloud code and it was good, right? We all got basically catnipped by that thing and stopped sleeping.

**[0:38]** Um bunch of stuff before that, but cloud cloud code was the one thing that kind of clicked with me the most. And to preface all of this, I love the cloud cloud team. They're brilliant people, talented, super high velocity. So, uh they also created the entire game.

**[0:52]** Major props to them. So, this is not a roast. This is just me, an old man, telling you why I stopped using cloud code and built my own thing.

**[1:00]** Um in 2025 I started using cloud code in about April, I think, thanks to Peter uh because he told us the agents are working now.

**[1:10]** And back then it was simple and predictable and fit my workflow, but eventually the token madness got hold of them, I think, and the team got bigger and they started uh dog fooding that stuff and built a lot of features. A lot of features I don't need, which is fine. I can just ignore them. But with velocity and more features come more bugs and that's bad because I used to work at construction sites and if my hammer breaks every day, I'm getting really mad. And if my development tools break every day, I'm also getting mad.

**[1:39]** So, there was this. It's just a running gag and here's Tariq telling us that cloud code is now a game engine. And here's Mitchell from Ghosty telling us, "No, it's not." And eventually they fixed the flicker, but then other stuff broke and I think they're now in the third iteration of a tool renderer.

**[1:52]** Yeah, but that's just a symptom. The real problem is that my context wasn't my context. Cloud code is the thing that controls my context and behind my back cloud code does things uh to the context. So, you have the system prompt which changes on every release, including the tool definitions. They would remove tools, modify tools.

**[2:11]** It's not good.

**[2:14]** They would insert system reminders in the most inopportuned place in your context telling the model, "Here's some information. It may or may not be relevant to what you're doing." That actually says it may or may not be relevant what you're doing. And that kind of confused the model and that kind of broke my workflows.

**[2:30]** On top of all that, there's zero observability because that's how the tool is constructed and I like knowing what my agents are doing. There's zero model choice which is obvious. It's the native Anthropic harness, so it makes sense for them to want you to use Claude, right?

**[2:46]** And there's almost zero extensibility and some of you might have written some hooks for Claude code, but I'm telling you the number of hooks and the depth of those hooks is very shallow. Um and every time a hook triggers, what actually happens is a new process gets spawned. Basically, the command you specified for that hook to be executed and I don't find that specifically efficient. So, I uh took a step back and looked around for alternatives and I'd like to especially call out Amp and FactoryDroid, the Porsche and Lamborghini of coding agent harnesses. So, if you can afford them, please use them. They're at the frontier. They're really good and the teams are fantastic. And there's a bunch of other options and I have history in OSS, so naturally I kind of gravitated towards open code. And again, brilliant team, super high execution velocity and they don't sell you hype. They sell you tools that work for the most part.

**[3:33]** I started looking under the hood of open code uh with respect to context handling as well because that's the most important part for me and I found a bunch of things like given some conditions, open code code would just uh prune tool outputs after a specific minimum amount of tokens. And that basically lobotomizes the model.

**[3:54]** Uh there's also LSP server support, which means every time your model is calling the edit tool, open code goes to the LSP server that's connected, asks, [snorts] are there any errors? And if so, injects that as part of the edit tool uh result.

**[4:08]** Which is bad, because think about how you are editing code. You're not writing a line of code, checking the errors, writing the next line, checking the errors. You don't do that. You finish your work and then you check the errors.

**[4:19]** This confuses the model. There's a bunch of other things like storing individual messages of a session in a JSON file.

**[4:25]** Each message message is a JSON file on disk.

**[4:29]** Uh there was this, and this happens to all of us, no no blame there, but it's not great if by default a server spins up, course headers are set in such a way that any website you open in your browser can now access your open code server. That's yeah.

**[4:43]** And uh entirely unrelated to all of this, I started looking into benchmarks for coding agent harnesses and found uh Terminal Bench, um which is a pretty good benchmark, all things considered.

**[4:51]** And the funny part about it is that it's the most minimal kind of thing you can think of. All it gives the model is a tool to send keystrokes to to a tmux session and read the output of that tmux session.

**[5:05]** There's no file tools, no sub-agents, none of that stuff.

**[5:08]** And it's one of the best performing harnesses in the leaderboard.

**[5:11]** Here's the leaderboard from December 2025.

**[5:15]** Irrespective of model family, Terminus scores higher, mostly high even higher than the native harness of that model.

**[5:21]** So, what does that tell us?

**[5:24]** The form two thesis is we are in the around and find out phase of coding agents, and their current form is not their final form, right?

**[5:32]** So, second thesis is we need better ways to  around. And for me, that means self-modifying malleable agents.

**[5:38]** Things that the agent itself can modify, and I can modify, depending on my workflow.

**[5:45]** So, I stripped away all the things, built a minimal core, but made it super extensible, and made it so that the agent can modify itself.

**[5:53]** With some creature comforts, it's not entirely bare-bones. Uh so, that's Pie.

**[5:56]** It's an agent that adapts to your workflow instead of the other way around.

**[6:01]** It comes with four packages, uh an AI package, which is basically just an abstraction across providers and context handoff between providers, an agent core, uh which is just a while loop and the tool calling, a bespoke tweezer frame work. I come out of game development, so I built a thing that actually doesn't flicker too much, and the coding agent itself. Here's Pie's system prompt.

**[6:21]** >> [laughter] >> That's it.

**[6:23]** Eventually, the industry created a new standard called skills, which is basically just markdown files.

**[6:28]** So, we added that as well, and that needs to go in the system prompt. So, begrudgingly, we had to add a couple more lines.

**[6:34]** And finally, here's the magic that makes Pie able to modify itself.

**[6:37]** We ship the documentation, which was handcrafted by me and an agent, um and code examples of extensions.

**[6:45]** And [clears throat] all we need to do for the agent to modify itself is tell it, "Here's the documentation. Here's some code that shows you how to modify yourself by writing extensions." It comes with four tools. That's all it has, read, write, edit, bash. Here's the tool definitions. Don't read the the text, just look at the size.

**[7:02]** That's it.

**[7:05]** Here's what happens when you start a new session in one of these tools.

**[7:08]** So, the thing is, the models are actually reinforcement trained up to a zoo. So, they didn't know what a coding agent is, because the coding agent harness is basically what they're being trained when they are post-trained.

**[7:19]** You don't need 10,000 tokens to tell them, "You're a coding agent." They know, because they are coding agents now.

**[7:26]** Pie is also yellow by default, because my security needs are different than yours, and I don't think a little dialogue that pops up every now every time you call bash, asking you to approve, is a smart security uh mechanism. So, instead, I give you so much rope that you can build anything that's fit for your specific security needs.

**[7:47]** There's also stuff that's not built in.

**[7:48]** I'm a heathen.

**[7:51]** Because this is how I do it.

**[7:53]** But if you don't like that, then you just ask Pi to build you sub-agent support on plan mode or MCP support, whatever you need.

**[8:00]** Extensibility comes with a bunch of table stakes and then with the extensions itself. And extensions in Pi are just TypeScript modules. In the simplest case, a TypeScript file on disk. You point Pi at that. Here's an extension, load that as part of the harness.

**[8:15]** And with that, you get a basically an extension API that lets you hook into everything and define stuff for the harness to expose to the to the model. And that includes tools, slash command shortcuts. You can listen in on any kind of event and react and then save state in the session that's optionally provided to the agent as well or stored there for tools that analyze sessions as part of your organizational workflows. You can do custom compaction, custom providers, and you have full control over the tools. So, you can modify everything in Pi.

**[8:47]** And you can then bundle all of that up and put it on NPM or on GitHub because I think we don't need to reinvent another bunch of silos called marketplaces. We already have package managers managers.

**[8:59]** And all of that hot reloads. So, if you develop an extension for Pi, you do so in the session and you hot reloads changes and see the the the effects of that immediately, which is very great and that's also game development thing is in game development, you want high very low iteration uh speeds and that's great.

**[9:19]** So, a couple of examples. Cloud or Anthropic ships the slash, by the way, which lets you talk to the agent while goes on its main quest. I posted this little prompt on Twitter jokingly and somebody built it in 5 minutes with more features. And they didn't have to fork or clone it just let the agent write the extension based on the prompt.

**[9:38]** Here's Nico as one of the most prolific uh extension writers. I don't know what the is going on here. It's a chat room for all of his Pi agents and they talk with each other. I would never use this, but all of this is custom including the UI.

**[9:52]** Or you can play NES games.

**[9:53]** Or you can play Doom.

**[9:55]** And there's a bunch of other examples I'm not going to talk about. So, how do you build a Pi extension? You don't. You tell Pi to build it for you based on your specifications and then you just iterate with it on that and hot reload during the session.

**[10:08]** Going to skip that example as well. And if you don't like building things yourself and I hope you do like building things yourself, but if you don't you can look on NPM or our little search uh interface on top of NPM to find packages for sub agents, MCP, and so on.

**[10:22]** So, does it actually work? Well, here's the terminal bench leaderboard from October before Pi had compaction. I added that for Peter's claw thingy.

**[10:30]** It scored sixth place.

**[10:32]** Uh but none of this is actually about Pi. If you want to read I basically want you to retake control of your tools and workflows. So, build your own.

**[10:41]** Um and if you want to know more about Pi and Open Claw, go to this talk, please.

**[10:44]** Yeah, and then eventually Peter happened. He put Pi inside of Open Claw as it's a gent core, which meant my open source project became the target of a lot of Open Claw instances unbeknownst to their users.

**[10:56]** So, this is act two, OSS in the age of clankers. Clankers are destroying OSS.

**[10:59]** Here's Till Draw. They closed down the issue and pull request tracker. Here's Open Claw's uh trackers. Here's mine. Half of that is Open Claw instances who post garbage.

**[11:08]** So, I started to rage against the clankers.

**[11:13]** Um if you send a pull request, it gets auto closed with a comment that asks you to please write a nice issue in your human voice no longer than a screen worth of text. And if I see that, I write looks good to me and your account name gets put in a file in the repository and the next time you send a pull request, it's let through.

**[11:29]** Clankers don't read that comment. They don't go back once they posted a pull request. So, that's a perfect filter. Uh Mitchell eventually turned that into vouch. Here's a clanker. Uh I also labeled them. If you had interactions with open claw, your issues get deprioritized. I also built tools where I embed uh issues and pull request texts into 3D space, so I see clusters of issues. Uh I also invented OS certification. I just close the tracker whenever I want, so I have my life back.

**[11:55]** So, does this work? Yes, sort of.

**[11:58]** >> [laughter] >> Which leads me to act three, slow the  down.

**[12:04]** Everything's broken.

**[12:05]** And then there's people that say, "Our product's been 100% built by agents." Yes, we know it sucks now.

**[12:12]** Congratulations.

**[12:14]** >> [cheering] [applause] [applause] >> And I'm hearing this from my peers, and this is entirely unhealthy.

**[12:24]** Um so, here's how we should not work with agents and why, at least in my opinion. I wrote this on my blog a while ago, but the basic gist is we're having army of agents in your using beats on and you don't know that it's basically uninstallable malware, and Entropic built a C compiler. It kind of works, but actually doesn't, and we're hoping the next generation of molds will fix it. And here is Kerbal building a browser, and that's also super broken. Uh but the next generation will fix it. And SaaS is dead software is often 6 months, and my grandma just built herself a Spotify with her open claw.

**[12:55]** Come on, people.

**[12:56]** So, agents are actually compounding booboos, which is my word for errors, with zero learning and no bottlenecks and uh delayed pain. The delayed pain is for you.

**[13:06]** Here's your code base on a human, on one agent, and 10 agents. How much of the agent code can you review?

**[13:12]** Here's the same code base, but expressed in number of booboos per day.

**[13:16]** How much of those booboos do you think you'll find? Then you say, "Oh, I have a review agent." Let me introduce you to the wonderful world of the ouroboros.

**[13:26]** Doesn't work. It catches some issues.

**[13:28]** Um the problem is that agents and merchants have learned complexity. Where did they learn that complexity from?

**[13:33]** From the internet. What's on the internet? All our old garbage code.

**[13:36]** There are some pearls on the internet, really well-designed systems, but 90% of code on the internet is our old garbage.

**[13:43]** And that's what the models learn from.

**[13:45]** And every decision of an agent is local, especially if the code base is so big that it doesn't fit into its context.

**[13:51]** And if you let it go wild and add abstractions everywhere that are and intertwined.

**[13:57]** Um so that leads to a lot of abstractions and duplication and backwards compatibility. Who has seen that in the output of their agents? It's  annoying. Or defense in depth.

**[14:06]** So yeah, you get enterprise-grade complexity within 2 weeks with just two humans and 10 agents.

**[14:13]** Congratulations.

**[14:14]** And then you say, "But my detailed spec." Yes, sure. You know what we call a sufficiently detailed spec?

**[14:20]** It's a program.

**[14:23]** So if you leave blanks in your spec, what do you think happens? How does the model fill in the blanks? And with what does it fill that in? It fills it in with the garbage that it learned on the internet from our old code, which is garbage from mediocre.

**[14:37]** And then you say, "But humans also." Yes, humans are horrible, failed fallible beings, but they can learn.

**[14:42]** And they are bottlenecks. There's only so many booboos they can add to your code base on a daily basis.

**[14:48]** And humans feel pain.

**[14:51]** Which is a very interesting property because humans hate pain. And once there's too much pain, the human has a bunch of options. It can quit their job.

**[14:58]** It can uh blame somebody else and make them fix it. Or everybody bands together and starts refactoring the out out of the garbage code base, right?

**[15:08]** Agents will happily keep into your code base.

**[15:13]** And now your agents and their super complex memory systems will not save you. Agents don't learn the way we learn.

**[15:21]** Those are my most most beloved people. I don't even read the code anymore.

**[15:26]** Congratulations. Something is broken and your users are screaming. So, who you going to call? Not yourself, because you haven't read the code.

**[15:34]** So, you're relying on your agents, but they are now also overwhelmed because the code base is so humongous that there's absolutely zero chance they can get all the context they need to fix the issues. And long context windows are a hack, as most of you will find those this year as everybody's switching to 1 million tokens context windows.

**[15:51]** And agentic search is also failing.

**[15:53]** So, the agent patches locally and  up globally. If you see this in your code base, you're So, you cannot trust your code base anymore and also not your tests because your agent wrote your tests. So, good game.

**[16:10]** So, here's how I think we should work.

**[16:11]** Um there's a bunch of properties for good agent tasks. That means scope. If you can scope it in such a way that the agent is guaranteed to find all the things it needs to find to do a good job, you're done. That means modularize your code base. If you can give it a function to evaluate how well it did the job, even better. Hill climbing, auto research.

**[16:32]** Uh anything non-mission critical, let it wipe. Boring stuff, let it wipe.

**[16:35]** Reproduction cases for user issues, which are usually only partial in information, perfect. I don't spend any mornings anymore doing that. Or if you don't have a human near you, rubber duck. So, lots of tasks you can use them for and save time.

**[16:48]** At the you evaluate. You take what's reasonable, most of it isn't, and then finalize.

**[16:55]** My final slide, more or less. Slow the  down.

**[16:58]** >> [gasps] >> Think about what you're building and why, and don't just build because your agent can do it now. That's stupid.

**[17:04]** Uh learn to say no. This is your most valuable capability at the moment. Fewer features, but the ones that matter, and then use your agents to polish the out of that. Enlighten your users, not your uh token maxing desires.

**[17:19]** Cap the amount of generated code uh that you need to review.

**[17:23]** And non-critical code, sure, five slope ahead. Critical code, read every line.

**[17:30]** See the keynote after me for more info on that. So, how do you know what's critical? Any guesses?

**[17:35]** Well, you read the code.

**[17:39]** >> [laughter] >> Uh if you do anything important, write it by hand. You can use a clanker to help you with that, but don't make let it make the decisions for you because we've learned all the decisions it makes are learned from the internet.

**[17:51]** And that friction is the thing that builds the understanding of the system in your head, which is important.

**[17:56]** And it's also where you learn new things.

**[18:01]** And all of this requires discipline and agency.

**[18:04]** And all of this still requires humans.

**[18:05]** Thank you.

**[18:07]** Woo!

---

## Plain Text

[music] >> Hey there. I'm Mario. I built pie in a world of slop and this is a tragedy tragedy in three acts. Just to talk about this real quick. Bunch of people on the internet gave me money for ad space on my torso and all of that goes to a charity. So, yeah, thanks guys. So, act one, building pie. In the beginning there was cloud code and it was good, right? We all got basically catnipped by that thing and stopped sleeping. Um bunch of stuff before that, but cloud cloud code was the one thing that kind of clicked with me the most. And to preface all of this, I love the cloud cloud team. They're brilliant people, talented, super high velocity. So, uh they also created the entire game. Major props to them. So, this is not a roast. This is just me, an old man, telling you why I stopped using cloud code and built my own thing. Um in 2025 I started using cloud code in about April, I think, thanks to Peter uh because he told us the agents are working now. And back then it was simple and predictable and fit my workflow, but eventually the token madness got hold of them, I think, and the team got bigger and they started uh dog fooding that stuff and built a lot of features. A lot of features I don't need, which is fine. I can just ignore them. But with velocity and more features come more bugs and that's bad because I used to work at construction sites and if my hammer breaks every day, I'm getting really mad. And if my development tools break every day, I'm also getting mad. So, there was this. It's just a running gag and here's Tariq telling us that cloud code is now a game engine. And here's Mitchell from Ghosty telling us, "No, it's not." And eventually they fixed the flicker, but then other stuff broke and I think they're now in the third iteration of a tool renderer. Yeah, but that's just a symptom. The real problem is that my context wasn't my context. Cloud code is the thing that controls my context and behind my back cloud code does things uh to the context. So, you have the system prompt which changes on every release, including the tool definitions. They would remove tools, modify tools. It's not good. They would insert system reminders in the most inopportuned place in your context telling the model, "Here's some information. It may or may not be relevant to what you're doing." That actually says it may or may not be relevant what you're doing. And that kind of confused the model and that kind of broke my workflows. On top of all that, there's zero observability because that's how the tool is constructed and I like knowing what my agents are doing. There's zero model choice which is obvious. It's the native Anthropic harness, so it makes sense for them to want you to use Claude, right? And there's almost zero extensibility and some of you might have written some hooks for Claude code, but I'm telling you the number of hooks and the depth of those hooks is very shallow. Um and every time a hook triggers, what actually happens is a new process gets spawned. Basically, the command you specified for that hook to be executed and I don't find that specifically efficient. So, I uh took a step back and looked around for alternatives and I'd like to especially call out Amp and FactoryDroid, the Porsche and Lamborghini of coding agent harnesses. So, if you can afford them, please use them. They're at the frontier. They're really good and the teams are fantastic. And there's a bunch of other options and I have history in OSS, so naturally I kind of gravitated towards open code. And again, brilliant team, super high execution velocity and they don't sell you hype. They sell you tools that work for the most part. I started looking under the hood of open code uh with respect to context handling as well because that's the most important part for me and I found a bunch of things like given some conditions, open code code would just uh prune tool outputs after a specific minimum amount of tokens. And that basically lobotomizes the model. Uh there's also LSP server support, which means every time your model is calling the edit tool, open code goes to the LSP server that's connected, asks, [snorts] are there any errors? And if so, injects that as part of the edit tool uh result. Which is bad, because think about how you are editing code. You're not writing a line of code, checking the errors, writing the next line, checking the errors. You don't do that. You finish your work and then you check the errors. This confuses the model. There's a bunch of other things like storing individual messages of a session in a JSON file. Each message message is a JSON file on disk. Uh there was this, and this happens to all of us, no no blame there, but it's not great if by default a server spins up, course headers are set in such a way that any website you open in your browser can now access your open code server. That's yeah. And uh entirely unrelated to all of this, I started looking into benchmarks for coding agent harnesses and found uh Terminal Bench, um which is a pretty good benchmark, all things considered. And the funny part about it is that it's the most minimal kind of thing you can think of. All it gives the model is a tool to send keystrokes to to a tmux session and read the output of that tmux session. There's no file tools, no sub-agents, none of that stuff. And it's one of the best performing harnesses in the leaderboard. Here's the leaderboard from December 2025. Irrespective of model family, Terminus scores higher, mostly high even higher than the native harness of that model. So, what does that tell us? The form two thesis is we are in the around and find out phase of coding agents, and their current form is not their final form, right? So, second thesis is we need better ways to  around. And for me, that means self-modifying malleable agents. Things that the agent itself can modify, and I can modify, depending on my workflow. So, I stripped away all the things, built a minimal core, but made it super extensible, and made it so that the agent can modify itself. With some creature comforts, it's not entirely bare-bones. Uh so, that's Pie. It's an agent that adapts to your workflow instead of the other way around. It comes with four packages, uh an AI package, which is basically just an abstraction across providers and context handoff between providers, an agent core, uh which is just a while loop and the tool calling, a bespoke tweezer frame work. I come out of game development, so I built a thing that actually doesn't flicker too much, and the coding agent itself. Here's Pie's system prompt. >> [laughter] >> That's it. Eventually, the industry created a new standard called skills, which is basically just markdown files. So, we added that as well, and that needs to go in the system prompt. So, begrudgingly, we had to add a couple more lines. And finally, here's the magic that makes Pie able to modify itself. We ship the documentation, which was handcrafted by me and an agent, um and code examples of extensions. And [clears throat] all we need to do for the agent to modify itself is tell it, "Here's the documentation. Here's some code that shows you how to modify yourself by writing extensions." It comes with four tools. That's all it has, read, write, edit, bash. Here's the tool definitions. Don't read the the text, just look at the size. That's it. Here's what happens when you start a new session in one of these tools. So, the thing is, the models are actually reinforcement trained up to a zoo. So, they didn't know what a coding agent is, because the coding agent harness is basically what they're being trained when they are post-trained. You don't need 10,000 tokens to tell them, "You're a coding agent." They know, because they are coding agents now. Pie is also yellow by default, because my security needs are different than yours, and I don't think a little dialogue that pops up every now every time you call bash, asking you to approve, is a smart security uh mechanism. So, instead, I give you so much rope that you can build anything that's fit for your specific security needs. There's also stuff that's not built in. I'm a heathen. Because this is how I do it. But if you don't like that, then you just ask Pi to build you sub-agent support on plan mode or MCP support, whatever you need. Extensibility comes with a bunch of table stakes and then with the extensions itself. And extensions in Pi are just TypeScript modules. In the simplest case, a TypeScript file on disk. You point Pi at that. Here's an extension, load that as part of the harness. And with that, you get a basically an extension API that lets you hook into everything and define stuff for the harness to expose to the to the model. And that includes tools, slash command shortcuts. You can listen in on any kind of event and react and then save state in the session that's optionally provided to the agent as well or stored there for tools that analyze sessions as part of your organizational workflows. You can do custom compaction, custom providers, and you have full control over the tools. So, you can modify everything in Pi. And you can then bundle all of that up and put it on NPM or on GitHub because I think we don't need to reinvent another bunch of silos called marketplaces. We already have package managers managers. And all of that hot reloads. So, if you develop an extension for Pi, you do so in the session and you hot reloads changes and see the the the effects of that immediately, which is very great and that's also game development thing is in game development, you want high very low iteration uh speeds and that's great. So, a couple of examples. Cloud or Anthropic ships the slash, by the way, which lets you talk to the agent while goes on its main quest. I posted this little prompt on Twitter jokingly and somebody built it in 5 minutes with more features. And they didn't have to fork or clone it just let the agent write the extension based on the prompt. Here's Nico as one of the most prolific uh extension writers. I don't know what the is going on here. It's a chat room for all of his Pi agents and they talk with each other. I would never use this, but all of this is custom including the UI. Or you can play NES games. Or you can play Doom. And there's a bunch of other examples I'm not going to talk about. So, how do you build a Pi extension? You don't. You tell Pi to build it for you based on your specifications and then you just iterate with it on that and hot reload during the session. Going to skip that example as well. And if you don't like building things yourself and I hope you do like building things yourself, but if you don't you can look on NPM or our little search uh interface on top of NPM to find packages for sub agents, MCP, and so on. So, does it actually work? Well, here's the terminal bench leaderboard from October before Pi had compaction. I added that for Peter's claw thingy. It scored sixth place. Uh but none of this is actually about Pi. If you want to read I basically want you to retake control of your tools and workflows. So, build your own. Um and if you want to know more about Pi and Open Claw, go to this talk, please. Yeah, and then eventually Peter happened. He put Pi inside of Open Claw as it's a gent core, which meant my open source project became the target of a lot of Open Claw instances unbeknownst to their users. So, this is act two, OSS in the age of clankers. Clankers are destroying OSS. Here's Till Draw. They closed down the issue and pull request tracker. Here's Open Claw's uh trackers. Here's mine. Half of that is Open Claw instances who post garbage. So, I started to rage against the clankers. Um if you send a pull request, it gets auto closed with a comment that asks you to please write a nice issue in your human voice no longer than a screen worth of text. And if I see that, I write looks good to me and your account name gets put in a file in the repository and the next time you send a pull request, it's let through. Clankers don't read that comment. They don't go back once they posted a pull request. So, that's a perfect filter. Uh Mitchell eventually turned that into vouch. Here's a clanker. Uh I also labeled them. If you had interactions with open claw, your issues get deprioritized. I also built tools where I embed uh issues and pull request texts into 3D space, so I see clusters of issues. Uh I also invented OS certification. I just close the tracker whenever I want, so I have my life back. So, does this work? Yes, sort of. >> [laughter] >> Which leads me to act three, slow the  down. Everything's broken. And then there's people that say, "Our product's been 100% built by agents." Yes, we know it sucks now. Congratulations. >> [cheering] [applause] [applause] >> And I'm hearing this from my peers, and this is entirely unhealthy. Um so, here's how we should not work with agents and why, at least in my opinion. I wrote this on my blog a while ago, but the basic gist is we're having army of agents in your using beats on and you don't know that it's basically uninstallable malware, and Entropic built a C compiler. It kind of works, but actually doesn't, and we're hoping the next generation of molds will fix it. And here is Kerbal building a browser, and that's also super broken. Uh but the next generation will fix it. And SaaS is dead software is often 6 months, and my grandma just built herself a Spotify with her open claw. Come on, people. So, agents are actually compounding booboos, which is my word for errors, with zero learning and no bottlenecks and uh delayed pain. The delayed pain is for you. Here's your code base on a human, on one agent, and 10 agents. How much of the agent code can you review? Here's the same code base, but expressed in number of booboos per day. How much of those booboos do you think you'll find? Then you say, "Oh, I have a review agent." Let me introduce you to the wonderful world of the ouroboros. Doesn't work. It catches some issues. Um the problem is that agents and merchants have learned complexity. Where did they learn that complexity from? From the internet. What's on the internet? All our old garbage code. There are some pearls on the internet, really well-designed systems, but 90% of code on the internet is our old garbage. And that's what the models learn from. And every decision of an agent is local, especially if the code base is so big that it doesn't fit into its context. And if you let it go wild and add abstractions everywhere that are and intertwined. Um so that leads to a lot of abstractions and duplication and backwards compatibility. Who has seen that in the output of their agents? It's  annoying. Or defense in depth. So yeah, you get enterprise-grade complexity within 2 weeks with just two humans and 10 agents. Congratulations. And then you say, "But my detailed spec." Yes, sure. You know what we call a sufficiently detailed spec? It's a program. So if you leave blanks in your spec, what do you think happens? How does the model fill in the blanks? And with what does it fill that in? It fills it in with the garbage that it learned on the internet from our old code, which is garbage from mediocre. And then you say, "But humans also." Yes, humans are horrible, failed fallible beings, but they can learn. And they are bottlenecks. There's only so many booboos they can add to your code base on a daily basis. And humans feel pain. Which is a very interesting property because humans hate pain. And once there's too much pain, the human has a bunch of options. It can quit their job. It can uh blame somebody else and make them fix it. Or everybody bands together and starts refactoring the out out of the garbage code base, right? Agents will happily keep into your code base. And now your agents and their super complex memory systems will not save you. Agents don't learn the way we learn. Those are my most most beloved people. I don't even read the code anymore. Congratulations. Something is broken and your users are screaming. So, who you going to call? Not yourself, because you haven't read the code. So, you're relying on your agents, but they are now also overwhelmed because the code base is so humongous that there's absolutely zero chance they can get all the context they need to fix the issues. And long context windows are a hack, as most of you will find those this year as everybody's switching to 1 million tokens context windows. And agentic search is also failing. So, the agent patches locally and  up globally. If you see this in your code base, you're So, you cannot trust your code base anymore and also not your tests because your agent wrote your tests. So, good game. So, here's how I think we should work. Um there's a bunch of properties for good agent tasks. That means scope. If you can scope it in such a way that the agent is guaranteed to find all the things it needs to find to do a good job, you're done. That means modularize your code base. If you can give it a function to evaluate how well it did the job, even better. Hill climbing, auto research. Uh anything non-mission critical, let it wipe. Boring stuff, let it wipe. Reproduction cases for user issues, which are usually only partial in information, perfect. I don't spend any mornings anymore doing that. Or if you don't have a human near you, rubber duck. So, lots of tasks you can use them for and save time. At the you evaluate. You take what's reasonable, most of it isn't, and then finalize. My final slide, more or less. Slow the  down. >> [gasps] >> Think about what you're building and why, and don't just build because your agent can do it now. That's stupid. Uh learn to say no. This is your most valuable capability at the moment. Fewer features, but the ones that matter, and then use your agents to polish the out of that. Enlighten your users, not your uh token maxing desires. Cap the amount of generated code uh that you need to review. And non-critical code, sure, five slope ahead. Critical code, read every line. See the keynote after me for more info on that. So, how do you know what's critical? Any guesses? Well, you read the code. >> [laughter] >> Uh if you do anything important, write it by hand. You can use a clanker to help you with that, but don't make let it make the decisions for you because we've learned all the decisions it makes are learned from the internet. And that friction is the thing that builds the understanding of the system in your head, which is important. And it's also where you learn new things. And all of this requires discipline and agency. And all of this still requires humans. Thank you. Woo!