# Transcript: AgentCraft: Putting the Orc in Orchestration — Ido Salomon

- **Channel:** AI Engineer
- **URL:** https://www.youtube.com/watch?v=kR64LOqBBCU
- **Duration:** 11:10
- **Fetched:** 2026-05-30 18:40:44
- **Segments:** 304

---

**[0:00]** [music] >> So, good morning London.

**[0:15]** My name is Edo Salomon. I'm the creator of Agent Craft. I am also the creator of MC I and creator and co-maintainer of MC apps. So, I'm building some of the stuff that David has been talking about.

**[0:27]** As you've all heard in the past day, agents are amazing.

**[0:32]** But if one agent is so amazing, why don't we scale up to 10 or 20 or 100 different agents and be 100 times more amazing?

**[0:42]** It is pretty simple. We just spin up a bunch of agents. We put them in this like nice screen and it looks really glorious.

**[0:49]** But it won't actually work.

**[0:52]** And the reason is that spinning in them up isn't a problem.

**[0:56]** It's us. We are the bottleneck in orchestrating all of these agents.

**[1:01]** Now, if you think about it, the role of the engineer to actually go and manage dozens of reckless employees is not typically what we do in most companies.

**[1:11]** So, we need to somehow find these new potentially new skills to manage all of these agents.

**[1:20]** Luckily, they're not really brand new. It's not something that we've never done before.

**[1:26]** It's just something that's been hiding in unexpected places.

**[1:30]** I mean, if you're a gamer or used to play games at any point, managing dozens of units probably sounds a little bit familiar.

**[1:39]** Which is why I built Agent Craft, which is an orchestrator that aims to raise the ceiling of human agent collaboration by taking learnings from gaming and transferring them into productivity.

**[1:50]** So, let's see a quick walk through of that and let understand the journey to raise that ceiling.

**[1:59]** So, this is Agent Craft.

**[2:01]** There's a lot to unpack. So, we'll just start with the basics and go from there.

**[2:07]** This is an agent.

**[2:10]** Not a metaphorical one. This is actually a physical manifestation of a coding agent like a live session.

**[2:16]** It can be a you know, cursor. It can be cloud code, code X, open claw, whatever.

**[2:22]** It's something that we can detect on the device and visualize it, but it's also something that we can spawn directly from here.

**[2:32]** So, now we have this agent and we can prompt it. We can use it like just any other agent that we have from our CLI or whatever.

**[2:42]** And what can we tell it to do? It has all of these quirks. You know, we have voice and we have text and we have images and so on.

**[2:49]** We can just tell it to do stuff. So, for example, we can tell it to develop some feature for us.

**[2:54]** And now the agent is working. So, it's doing its work.

**[3:03]** >> [applause] [applause] >> So, it's doing work and as you can see, if you look at the the the UI, there's like a bunch of other stuff. We have these buildings and each building represents some functionality. So, for example, you know, one of these buildings manages the skills and plugins and so on.

**[3:24]** There's also, you know, like integrated terminal and get just to like get that end-to-end workflow.

**[3:32]** The second part of raising the ceiling that we have the basics is visibility.

**[3:36]** We need to be able to quickly understand what each agent is doing. So, we have this nice side panel here that really shows us like high-level mission status summary and so on. What are they actually doing?

**[3:50]** But the cool thing about Agent Craft is that we don't just see a list of what they can do.

**[3:55]** We can actually see them working.

**[3:56]** So, if we look at the map, you would notice that it's actually a projection of my file system.

**[4:03]** Each part of my file system is actually on the map.

**[4:06]** So, I have these directories here.

**[4:07]** And each one of these directories has files. These files are represented as rooms, as you can see here. So, I can actually track and see visually what the agent is working on, which file. I can see the entire change list of what happened there. And because we're orchestrating it, I also know which agents did what and when. So, we can have full lineage of what's going on.

**[4:28]** And we can take this one step further.

**[4:31]** If I know all of these stuff, why not just create a heat map?

**[4:36]** I can actually try and see visualize collisions and I can even prevent them proactively.

**[4:42]** Now, the cool thing here is that once we have this visibility, we're not exactly done yet because we still need to be able to react to the changes that are happening.

**[4:51]** So, we can lean into another cool mechanism from RTS games. We can simply use muscle memory to quickly cycle between the agents that need our help.

**[5:00]** They need us to approve the plan. They need us to answer some questions and so on.

**[5:06]** So, now we have visibility and we can react quickly. So, we're done. We solved orchestration.

**[5:13]** But not quite because that's really only the first step. I was able to use more agents in parallel, but only for a short amount of time.

**[5:22]** There are a few reasons for that. The first one is that there's only a limit to how many ideas I can have in my head at any given time without being tired. So, what I did is basically tell the agent to do it. I told them, "Okay, find missions for me to do." So, I have quests now and I can click a button and they just do whatever. They can refactor test all the stuff that I don't want to do.

**[5:44]** And the second one is that all of this babysitting takes a lot of time. Like I need I see what's going on. I can react to it very quickly, but I still need to cycle through it.

**[5:55]** So, what I did there is kind of say, "How do I take myself out of the equation as much as possible?" So, if agents are so amazing, why not just let them do it? I can just like give them some idea. I have this campaign feature.

**[6:12]** Broadly say what I want to happen and I would just spin up a container. I would let the agents run there. They can decompose the task. They can plan it.

**[6:20]** They can present the plan to me. I don't care what they're doing because it's container, so do whatever.

**[6:25]** And the main thing here is that once it's decomposed, I'm not the one doing the babysitting. Now, I have the campaign orchestrator and that's his problem.

**[6:35]** So, we're actually moving more of the effort only to the planning phase or the review phase.

**[6:40]** And once we have that, we reach a point where we can just say, "Why is it my ideas? Why can't I tell it to have like run in a cron job, go to Twitter every day, scan cool ideas and just implement them?" I just decide what I want. Which is actually how I implemented channels pretty quickly.

**[6:58]** So, we have that and now I just have a lot of different PRs to review. So, there's this nice capability of just review bundles.

**[7:06]** And now I can see exactly what changes happened in each one. Like why did they do stuff? What are the tasks? And I also have visual evidence.

**[7:16]** So, now I am able to just look at screenshots. I can look at videos and really see what's going on without investing too much time in doing it.

**[7:25]** And once we have that, we can actually shift more of the work from the planning to the review.

**[7:33]** How much time do I need to spend on the plan if I can just do it 10 times and I'll just pick the one that is most fitting for me.

**[7:40]** And the next part is we're still not done. I mean, if you think about it, this is only the first step because agents aren't that smart yet. So, we need to offload it to someone else. Humans.

**[7:53]** Now, what I can do, and this is my favorite feature, is that we can actually create these workspaces. So, I can collaborate with the product designer from my team and they can do whatever they want and we can I can just continue from where they left off.

**[8:07]** So, for example, let's say this is an agent actually from the product designer on their computer. So, they can see my agents. I can see their agents. I can understand what they're doing and we can just collaborate.

**[8:21]** Um Yeah, they just started working again.

**[8:25]** So, I can see that they want to design this new page, which is pretty cool.

**[8:28]** So, I can wait for them to finish or I can just go ahead now and just hand off from them to my agents.

**[8:37]** Well, our agents.

**[8:39]** Insert communist, whatever.

**[8:42]** So, we have our agents now and I can just keep going from there. And the cool thing is that it's not just human-to-human collaboration.

**[8:49]** We are also collaborating with the agents. So, there's more direct stuff like this. I can just type stuff and prompt my agents or even their agents.

**[8:56]** But there's also a softer mechanism.

**[8:59]** There's actually a chat that is between humans and humans, but also between the humans and the agents. You can see here that the agent said, "I'm starting to work on something." And then I can say, "I'm also working on it." So, the next time the agent does something, it knows someone else is working. They can also have soft collaboration, so they would know what files each one is changing.

**[9:22]** So, we've actually taken a bunch of stuff that were limiting us from really reaching our full potential with agents and kind of solve them one by one. There are a bunch of other features that I just didn't have time to go over, but you can try them out and see for yourself if you can really work better that way.

**[9:44]** So, to sum up, uh these are not exactly new skills. I mean, you're probably worried perhaps that you won't be able to get adapted to this future where we're not actually coding, we're just telling other people to code for us or other agents.

**[10:03]** Uh but these skills are there. They're just not something we used for work until now. Uh so with games as one example, we can take these skills to the next level.

**[10:15]** We need to somehow raise that ceiling.

**[10:18]** We need to somehow improve our collaboration with agents. Uh and with Agent Craft, the goal is to take the learnings from games and really raise that to the next level with better visibility, uh more autonomy to the agents, and human-to-agent collaboration.

**[10:37]** So, I invite you to go to uh the website. Uh this is the QR code. You can It's free. You can just download it and play with it. Uh it's still experimental. It's still new. There's a bunch of stuff that need to change, uh but it will only happen with great feedback. There's also Discord.

**[10:53]** Uh so, please join. Give us uh your feedback, and let's raise the ceiling together.

**[10:59]** Thank you.

**[11:01]** >> [applause] [music]

---

## Plain Text

[music] >> So, good morning London. My name is Edo Salomon. I'm the creator of Agent Craft. I am also the creator of MC I and creator and co-maintainer of MC apps. So, I'm building some of the stuff that David has been talking about. As you've all heard in the past day, agents are amazing. But if one agent is so amazing, why don't we scale up to 10 or 20 or 100 different agents and be 100 times more amazing? It is pretty simple. We just spin up a bunch of agents. We put them in this like nice screen and it looks really glorious. But it won't actually work. And the reason is that spinning in them up isn't a problem. It's us. We are the bottleneck in orchestrating all of these agents. Now, if you think about it, the role of the engineer to actually go and manage dozens of reckless employees is not typically what we do in most companies. So, we need to somehow find these new potentially new skills to manage all of these agents. Luckily, they're not really brand new. It's not something that we've never done before. It's just something that's been hiding in unexpected places. I mean, if you're a gamer or used to play games at any point, managing dozens of units probably sounds a little bit familiar. Which is why I built Agent Craft, which is an orchestrator that aims to raise the ceiling of human agent collaboration by taking learnings from gaming and transferring them into productivity. So, let's see a quick walk through of that and let understand the journey to raise that ceiling. So, this is Agent Craft. There's a lot to unpack. So, we'll just start with the basics and go from there. This is an agent. Not a metaphorical one. This is actually a physical manifestation of a coding agent like a live session. It can be a you know, cursor. It can be cloud code, code X, open claw, whatever. It's something that we can detect on the device and visualize it, but it's also something that we can spawn directly from here. So, now we have this agent and we can prompt it. We can use it like just any other agent that we have from our CLI or whatever. And what can we tell it to do? It has all of these quirks. You know, we have voice and we have text and we have images and so on. We can just tell it to do stuff. So, for example, we can tell it to develop some feature for us. And now the agent is working. So, it's doing its work. >> [applause] [applause] >> So, it's doing work and as you can see, if you look at the the the UI, there's like a bunch of other stuff. We have these buildings and each building represents some functionality. So, for example, you know, one of these buildings manages the skills and plugins and so on. There's also, you know, like integrated terminal and get just to like get that end-to-end workflow. The second part of raising the ceiling that we have the basics is visibility. We need to be able to quickly understand what each agent is doing. So, we have this nice side panel here that really shows us like high-level mission status summary and so on. What are they actually doing? But the cool thing about Agent Craft is that we don't just see a list of what they can do. We can actually see them working. So, if we look at the map, you would notice that it's actually a projection of my file system. Each part of my file system is actually on the map. So, I have these directories here. And each one of these directories has files. These files are represented as rooms, as you can see here. So, I can actually track and see visually what the agent is working on, which file. I can see the entire change list of what happened there. And because we're orchestrating it, I also know which agents did what and when. So, we can have full lineage of what's going on. And we can take this one step further. If I know all of these stuff, why not just create a heat map? I can actually try and see visualize collisions and I can even prevent them proactively. Now, the cool thing here is that once we have this visibility, we're not exactly done yet because we still need to be able to react to the changes that are happening. So, we can lean into another cool mechanism from RTS games. We can simply use muscle memory to quickly cycle between the agents that need our help. They need us to approve the plan. They need us to answer some questions and so on. So, now we have visibility and we can react quickly. So, we're done. We solved orchestration. But not quite because that's really only the first step. I was able to use more agents in parallel, but only for a short amount of time. There are a few reasons for that. The first one is that there's only a limit to how many ideas I can have in my head at any given time without being tired. So, what I did is basically tell the agent to do it. I told them, "Okay, find missions for me to do." So, I have quests now and I can click a button and they just do whatever. They can refactor test all the stuff that I don't want to do. And the second one is that all of this babysitting takes a lot of time. Like I need I see what's going on. I can react to it very quickly, but I still need to cycle through it. So, what I did there is kind of say, "How do I take myself out of the equation as much as possible?" So, if agents are so amazing, why not just let them do it? I can just like give them some idea. I have this campaign feature. Broadly say what I want to happen and I would just spin up a container. I would let the agents run there. They can decompose the task. They can plan it. They can present the plan to me. I don't care what they're doing because it's container, so do whatever. And the main thing here is that once it's decomposed, I'm not the one doing the babysitting. Now, I have the campaign orchestrator and that's his problem. So, we're actually moving more of the effort only to the planning phase or the review phase. And once we have that, we reach a point where we can just say, "Why is it my ideas? Why can't I tell it to have like run in a cron job, go to Twitter every day, scan cool ideas and just implement them?" I just decide what I want. Which is actually how I implemented channels pretty quickly. So, we have that and now I just have a lot of different PRs to review. So, there's this nice capability of just review bundles. And now I can see exactly what changes happened in each one. Like why did they do stuff? What are the tasks? And I also have visual evidence. So, now I am able to just look at screenshots. I can look at videos and really see what's going on without investing too much time in doing it. And once we have that, we can actually shift more of the work from the planning to the review. How much time do I need to spend on the plan if I can just do it 10 times and I'll just pick the one that is most fitting for me. And the next part is we're still not done. I mean, if you think about it, this is only the first step because agents aren't that smart yet. So, we need to offload it to someone else. Humans. Now, what I can do, and this is my favorite feature, is that we can actually create these workspaces. So, I can collaborate with the product designer from my team and they can do whatever they want and we can I can just continue from where they left off. So, for example, let's say this is an agent actually from the product designer on their computer. So, they can see my agents. I can see their agents. I can understand what they're doing and we can just collaborate. Um Yeah, they just started working again. So, I can see that they want to design this new page, which is pretty cool. So, I can wait for them to finish or I can just go ahead now and just hand off from them to my agents. Well, our agents. Insert communist, whatever. So, we have our agents now and I can just keep going from there. And the cool thing is that it's not just human-to-human collaboration. We are also collaborating with the agents. So, there's more direct stuff like this. I can just type stuff and prompt my agents or even their agents. But there's also a softer mechanism. There's actually a chat that is between humans and humans, but also between the humans and the agents. You can see here that the agent said, "I'm starting to work on something." And then I can say, "I'm also working on it." So, the next time the agent does something, it knows someone else is working. They can also have soft collaboration, so they would know what files each one is changing. So, we've actually taken a bunch of stuff that were limiting us from really reaching our full potential with agents and kind of solve them one by one. There are a bunch of other features that I just didn't have time to go over, but you can try them out and see for yourself if you can really work better that way. So, to sum up, uh these are not exactly new skills. I mean, you're probably worried perhaps that you won't be able to get adapted to this future where we're not actually coding, we're just telling other people to code for us or other agents. Uh but these skills are there. They're just not something we used for work until now. Uh so with games as one example, we can take these skills to the next level. We need to somehow raise that ceiling. We need to somehow improve our collaboration with agents. Uh and with Agent Craft, the goal is to take the learnings from games and really raise that to the next level with better visibility, uh more autonomy to the agents, and human-to-agent collaboration. So, I invite you to go to uh the website. Uh this is the QR code. You can It's free. You can just download it and play with it. Uh it's still experimental. It's still new. There's a bunch of stuff that need to change, uh but it will only happen with great feedback. There's also Discord. Uh so, please join. Give us uh your feedback, and let's raise the ceiling together. Thank you. >> [applause] [music]