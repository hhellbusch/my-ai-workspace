# Transcript: A love letter to Pi | Lucas Meijer

- **Channel:** Build Monumental
- **URL:** https://www.youtube.com/watch?v=fdbXNWkpPMY
- **Duration:** 27:10
- **Fetched:** 2026-05-30 18:43:42
- **Segments:** 688

---

**[0:00]** [clears throat] >> Everyone, my name is Lucas Meyer.

**[0:02]** I spent most of my life, my working life on game engines and games.

**[0:12]** One of them we managed to make quite popular, it's called Unity.

**[0:15]** And um turns out the robots can do programming.

**[0:23]** I I don't know about you, but I did not really have this on my bingo card.

**[0:28]** I'm still I'm still sort of trying to cope with this.

**[0:36]** Um I am playing around with new ideas for what a game engine might look like if you make it for agents or humans and agents instead of only humans.

**[0:46]** Um I host a call it like a coping session bi-monthly for brownfield programmers that decided that they want to be really good at all this AI stuff, but that they realize that um it's actually not so easy. Actually, who here is really good at using the AI agents?

**[1:09]** One?

**[1:11]** Mr. Dunning-Kruger here.

**[1:12]** >> [laughter] >> Um so, for the rest of us >> [laughter] >> My question is are you at stage nine?

**[1:20]** No, I am absolutely not at stage nine and I have a lot of opinions on the stage nine people.

**[1:27]** Um Let me begin by saying like my advice is to not chase every shiny new tool and only solve the problem you actually have, which is probably not at stage nine.

**[1:39]** That said, um here's my shiny tools.

**[1:44]** All right. I like to use Codex. Um I like I like to joke that it's like Claude code, but for programming.

**[1:54]** Maybe Claude is someone you'd invite to your birthday and Codex is this sort of autistic German.

**[2:03]** Um But if you want to write software, I really I'm going for Codex.

**[2:10]** All right.

**[2:14]** >> [laughter] >> Um There This is basically a snapshot of all the things that I learned that works for me, don't work for me. One of the things that work for me is embracing HTML as a output form factor. Um I, you know, the 1980s were cool, but coding agents in these small black and white boxes who like that is crazy.

**[2:34]** Um So, I like to do my prompts kind of like this. I try to find a repo on the monumental GitHub repo. I ask for like do a deep dive analysis and then a lot of the prompts I just end with present your work as a single HTML slide deck.

**[2:50]** And if you do that instead of a coding agent, you get something like this.

**[2:55]** With like this How do you call this?

**[2:58]** Like index on the left and I just find this like such a much more pleasant way to consume large amounts of information.

**[3:08]** It's also a much more pleasant to sort of like skip over stuff than when you read it from a terminal.

**[3:15]** There's no reason we should, you know, go back to that part of the '80s.

**[3:21]** Um Um Making your code base agent friendly.

**[3:26]** This is a game. Who knows this game?

**[3:28]** Uh some old-timers here. It's called Marble Madness. It's from the '90s. Um I like to pretend that the marble is your coding agent and the level is your repo.

**[3:45]** And it's your job for this marble to roll down your repo very conveniently.

**[3:50]** However, there's all sorts of hazards like the marble could fall off the cliff. For instance, if your agent's MD instructions are incomplete or wrong.

**[4:01]** Um if your build system that you use, if it has been spewing out 500 warnings for the last 2 years and you tell everyone, "Yeah, yeah, yeah, you know, ignore that." The agent's going to go off track with that.

**[4:18]** And there's all sorts of like your job is basically to change the repo so that the ball will fall down smoothly.

**[4:28]** I like to ask this question, what would have helped the agent reach its goal faster?

**[4:34]** And I think the only way to really do that is to just read the whole transcript. You read the whole transcript, you see all the tool calls, you see all the things it does and then you're like, "Why like why did it like why did it go there? Why did it go there?" And you just make changes accordingly, right? And if you'd done that actually, let me show you how I like to do that like I'm here. This is my favorite agent. I like to do {slash} share um to create these sort of like easily as you've noticed I like my HTML.

**[5:09]** Um I just go through the whole thing and I read all the tool calls and I figure out sort of like, you know, like how it was performing.

**[5:22]** If you've done that a few times like anything in software development, if you've done it a few times it starts to feel boring. Of course, you can use AI to help you with it.

**[5:31]** Um You can say something like analyze the previous session.

**[5:36]** Find places where the agent went in a wrong direction only to later figure out the right way.

**[5:42]** And of course, in my Um Oh yeah, and make me some recommendations on what I could have added to the repo that would have made it have it not make that mistake.

**[5:52]** Um Obviously, I ask it to report that stuff in HTML for me. This is one that I was working on the other day. It gives some, you know, info on how the session was going and then here it had some frictions and this one was funny to me because it turns out um this was on the game engine that I'm doing some work on.

**[6:15]** Um The documentation said that you have to call the the build command, you have to do {at} Mac if you want to do a Mac build.

**[6:24]** And then turns out the agent tried that and it was wrong.

**[6:27]** And then it had to read the whole source code of the build system to figure out like, "No, it's colon Mac." And I did change that like a few weeks ago. I just missed a spot in the docs. All right, so by fixing that I may, you know, like you can actually make a continuous process to to making your code base like the most beautiful Marble Madness level because this repeated process is actually what you need, right? Like it's super easy to have clunkers write MD files and you just get more and more and more and more and it's like, you know, this Google Drive from how many how many docs in the monumental drive?

**[7:09]** Notion. In the Notion like Like I'm I'm assuming it's hard to find things just by previous experience.

**[7:16]** Um Um Let me Am I join Yeah, let me I'm going to show this. Um I like to use this program. It's called Super code. Um it's like conductor, but I like it much better.

**[7:34]** Um Maybe we can go into why later.

**[7:36]** Um And I showed the share.

**[7:40]** Let me go back to this topic actually.

**[7:46]** Evaluating agent work. I think this is the biggest mental shift that made the biggest difference for me is thinking about how you're going to actually evaluate the agent's work, right? Like you give it a task and it goes off for half an hour and then at some point it's done, right?

**[8:03]** Now what?

**[8:06]** Like what you're going to do? Like you're going to read the whole transcript? Are you going to read the summary? Are you going to read the source code? Are you going to play the game? Open the website? Like what is it that you're going to do?

**[8:16]** And my advice is to ask yourself this question before you send the agent on its task.

**[8:25]** Because when you ask yourself the question before, you can actually put it in the prompt.

**[8:32]** And it turns out that agents really like to know ahead of time how you're going to evaluate the results because it also gives them a lot of clarity on when they are done and when they're not done.

**[8:43]** This is actually also a great tip for humans.

**[8:47]** >> [laughter] >> They also like to know how you're going to evaluate them and when they are done and when they're not done.

**[8:53]** >> [laughter] >> Actually, almost [clears throat] everything that you turns out with these agents like it's almost all true for humans, too.

**[9:00]** Okay, so you put it in the beginning.

**[9:03]** You tell it how you will evaluate.

**[9:07]** And one of the things that I like Actually, let me show you back to Super code. Yeah.

**[9:15]** So, on the Steve Yegge stage nine, there's like agent swarms and agents starting agents and all these things. I don't know what those guys are smoking.

**[9:24]** I'm not like I'm not having any of that, but you might see on the left side here.

**[9:29]** I do have like 10 or 12 of these things open. Right? But there's no spinners there because all of these agents work streams that I have, they're all waiting for me.

**[9:41]** Right? So, in this new world, I am absolutely the bottleneck. And it's act like if a agent does like an hour of work, it's actually a ton of work to evaluate it. Like it could take like 15 minutes depending on, you know, like the quality and how happy you with it.

**[9:57]** So, if I'm the bottleneck of my whole little software factory here, and I'm like the evaluation of the work is the bottleneck, let's try to have the agent do more of it. And let's like I like to call these evaluation packs. Like let's really as if it were sort of like you know, let let's make them a lot of work to present a beautiful package for you that makes it really efficient to evaluate.

**[10:28]** For instance, I one-shotted as a to prepare for this talk, I one-shotted a website to where you can have photos and you can drag them on a timeline for an animation and then set up transitions between them.

**[10:45]** The way I would ask to evaluate that is to say, well, why don't you record a video where you open the websites that you just made where you demonstrate to me all the different features by moving the mouse and doing all these things and make a recording of that and then obviously show it to me in a single page slide deck together with a bunch of other stuff. And if you ask that, it turns out you can just ask that.

**[11:17]** And I get back from my one-shot this evaluation pack which makes my life easier to evaluate what it's done and also to quickly evaluate if I kind of like it. Like it makes this video and I can hit play.

**[11:34]** Not sure how well the video works on this screen sharing thing, but here it is going through the different photos.

**[11:41]** It's renaming them. It's adding them to the timeline.

**[11:45]** It's changing transitions and by making it do the work to make my evaluation life easy, I get to spend less time on the evaluation and I can get more of these individual work streams done.

**[12:03]** Additionally, it also helps the agent to not cheat. Right? It's super easy for the agent to say like, yeah, wrote some code and I think we're good.

**[12:13]** Um if you force it to make a video, it has to open it in Chrome or whatever and it will run all the JavaScript and if there's an error there, it will find it and if it fails to actually do these commands, it will notice it and it will kick itself in a loop to try to fix that.

**[12:32]** Um all right, so that is Oh, yeah, and then I all like because the video is actually hard for the agent to read itself, I also always ask it for a bunch of screenshots because you can force it to actually read the image files and use the models in How do you call that, Rick? The image >> Multi-model capabilities. Yeah, multi-model capabilities to actually look at the picture to see what is wrong.

**[12:59]** All right. Um let me speed through this.

**[13:03]** Um here we are.

**[13:07]** All right, so then finally, um I am in this rabbit hole of Pi. Pi is a coding agent. The rest of this talk is my love letter to Pi.

**[13:18]** Uh Pi is not Cloud Code. It is not Codex. You can use whatever model you want.

**[13:25]** Um and I love it because it's hackable.

**[13:28]** Um we just uh you know, we just did a poll and it turns out none of you know what we're doing with coding agents. I also have no idea what we're doing with coding agents. The Cloud Code guys have no idea. The Codex guys have no idea.

**[13:45]** We're so early. We have no idea what an ergonomic AI assistant actually looks like and that's why in this phase it's so important to just try endless and throw it against the wall and see what sticks. Right? And um oh, yeah, that is this.

**[14:06]** So, uh being able to experiment with what works for you as a person, what works for your project is super important.

**[14:13]** What is not amazing is waiting for some Cloud Code guys in San Francisco to come up with the workflow that is sort of like middle of the road for everyone that might or might not work for you.

**[14:25]** And that is why I love Pi because it allows you to do these things.

**[14:31]** It also has precise context management and I hope to show some of these things.

**[14:35]** Let me start off with the context management. So, I was rehearsing this thing in the back and I have all this stuff in my session here. I'm going to do {slash} tree. Let me actually Can you guys read that? It's I'm going to do {slash} tree, my Pi feature.

**[14:56]** And you get an overview of your entire context over here.

**[14:59]** And you'll notice that it's not linear, but that I've actually gone into different branches.

**[15:05]** Um since the bottom here was all a bit nonsense, I'm going to go back to this one.

**[15:13]** I'm going to hit enter.

**[15:14]** And then for now, I'm going to say no summary.

**[15:18]** And what this does is it brings me back to the beginning of the context. I get all that context back.

**[15:24]** Um let me ask for this is the repo of this sort of game engine experiment.

**[15:31]** Like run the fighter game for me.

**[15:33]** Let's hope Codex is not down.

**[15:38]** Ooh.

**[15:49]** Uh-oh.

**[15:50]** >> [laughter] >> Let's try that again.

**[15:54]** That looks better.

**[16:05]** Um all right, so fighter game.

**[16:10]** Nothing in particularly exciting about it.

**[16:16]** Um all right.

**[16:18]** Um I'm sorry, I lost my train of thought.

**[16:21]** Where was I?

**[16:22]** So, yeah, I so I went back with the So, I went back with {slash} tree to the beginning of the context and the {slash} tree I actually use it all the time because very often you will go into a side quest that turns out to be a dead end.

**[16:36]** Right? Let me actually you know, let's go into the side quest with the dead end. Like ask me five questions about my beef chili.

**[16:48]** All right. Slight detour. Bear with me.

**[16:52]** Um I'm going to do {slash} answer here.

**[16:55]** {slash} answer. {slash} answer is an extension that some random dude on the internet made. This is not part of Pi.

**[17:05]** It is someone that thought, you know what really sucks about coding agents?

**[17:11]** That when you ask them to interview about your plan and you get 20 questions that you have to sort of like type them back one by one. Like yeah, oh yeah, the answer to 16 is yes and then the answer to the other one Oh, yeah, scroll back.

**[17:24]** Oh, yeah, 17. Yeah, 17 is no. So, he figured like what if we just had like a special UI for that?

**[17:29]** And he wrote an extension for it called answer and what it does it takes the previous message, sends it to some to some cheap LLM to extract all the questions and then preserve like present it to you in this nice UI.

**[17:41]** Uh what kind of beef?

**[17:43]** Um losses token.

**[17:46]** Very and never beans, you animal.

**[17:51]** Um and then when you are done with it, it just turns it into a user message like that.

**[18:00]** Just I I really like that as an example of how you can just notice a problem that you actually have, like answering these plan questions, instead of a problem that you don't have, which is, you know, like how do I keep 20 agent swarms busy?

**[18:15]** All right, now that we went into a useless side quest, I can finally so show what I like {slash} tree for.

**[18:24]** Because you pay for all these side quests in your context, right? It's very normal for people to what's it called? Anthropomorphize their coding agent like it's some human you're supposed to talk to. No. No, it's not a human and you're also not really supposed to talk to it like that. It is a token producing machine that can help you get to good code, but you shouldn't pretend it's like a conversation. Like very often the right thing to do is like you should never tell it like, no, I didn't want it like that. I wanted it like that. Like when I have when I when it made something I didn't like, I'd use {slash} tree and I go back and then I ask it in a different way. I never, you know, like like don't argue with these things.

**[19:10]** Um if you do argue with them or if you if you say like, okay, forget about it.

**[19:17]** Let's just continue with this other feature. You continuously pay for this side quest to be in your context. You pay for it in tokens and you pay for it in intelligence because once your once your context gets longer, like once you get into the 50, 60% range, you enter like this dumb zone and it gets more stupid. So, it's really important.

**[19:40]** I'm not sure if you can see it down here, but most coding agents these days show you how far you are in the context window.

**[19:50]** If like if I see that go above 50, I get very nervous. I try to always make sure I am below 50.

**[19:57]** Um so when I go into this side quest like this, uh and then later it turns out that the discussion about beef is maybe not uh beneficial to the rest of my demo, I'm going to go back here. And here I can choose. I can say no summary, it will just throw it away.

**[20:18]** I'm probably going to do that because for the rest of the demo, the agent won't get better performance if it knows my beef preferences.

**[20:26]** If it was a side quest where you do something on your project that is actually useful to know that you tried it and that it failed because blah, then you would do summary and it would put a summary in there.

**[20:38]** So it's like you have much more intention and control over your context than most other coding agents provide. I think they're also catching up. I'm not I'm not quite sure, but having this control is super important.

**[20:53]** Um All right. I think I have one or two more things.

**[21:01]** Um notice um so one of the cool things about this game engine project I have Do I have um is that I have like full local CIs. I'm going to make a change to arena, which is like my main memory allocator that gets used everywhere.

**[21:20]** And now I'm going to ask like, hey, do a full CI run using uh S A all with a colon, not with a at symbol.

**[21:34]** And one of the things that was annoying me about these coding agents is that when you have these long-running tool calls, you have so poor visibility in what's going on.

**[21:45]** Right? Like when it does like rep grip, it's not a problem because it just finishes immediately. But the but I have Oh, this is not going well.

**[21:52]** What did did did it ever show the thing?

**[21:56]** Yes. Yeah.

**[21:57]** Was it just very quickly run?

**[21:59]** >> [clears throat] >> Oh, here we go.

**[22:01]** Oh, that's not good. Oh, you think I think my build system is so good that I already that it has this one cached. I'm going to do it like this.

**[22:12]** Here, try again.

**[22:14]** Um But it like I really disliked that you had such poor visibility. So I figured, oh, it would be cool if we can actually run these uh commands as a virtual terminal and that my coding agent actually shows it to me when it's working so that when it's sitting there for 10 minutes, which is like that is sometimes fine and that is sometimes uh it's stuck on something and it would be very nice if I could see it.

**[22:44]** So I made this this morning and um I thought it was a cool example of my new sort of like mental model, like how am I going to write a feature like this?

**[22:54]** How am I going to like it's cool that pilot should do it the first place. Yay pi.

**[23:02]** Uh but how like when when you write a feature like that, how are you going to close the loop? How are you going to make the agent know if the thing it wrote worked? And how am I going to check?

**[23:14]** And for this one, I asked it to write a single page HTML file.

**[23:19]** Here, this one. I asked it to like, hey, write me a bunch of different test programs that do different things with the terminal, you know, like alt screen, all these spinners, different colors, different repainting, like sending a hundred screens, all these test cases.

**[23:35]** And then I asked it to like, okay, well, run it through the code, make screenshots every few seconds, turn them into an animated GIF, put the animated GIF in my HTML file so that my job of reviewing it is easy.

**[23:54]** Right? And then run both my my virtual terminal code path against pi's own code path over there so that I can quickly see that it that that matches.

**[24:05]** It has some alt screen code, some synchronization code. I'm like it tries curl, it tries FFmpeg.

**[24:13]** So that's sort of it's another example of putting the onus on the agent to do the work for both the agent's benefit, making sure that it actually works, and my benefit of making it easy to get confidence that this thing actually works.

**[24:32]** Oh. Ah. All right, that is a bummer. I am going like let me do one final demo.

**[24:38]** It's probably too late.

**[24:41]** Uh I wanted to do this at the beginning to show you that the thing that's probably coolest is that I can write extensions for itself because it's a coding agent that has access to its own docs. So let's try make a quick extension that when the agent starts, I can play Doom in an overlay.

**[25:01]** And we'll see if we like if it is quick enough for this thing to work.

**[25:10]** Um This particular form of software where software finishes [snorts] and extends and configures itself while it is running on the user machine, I find mind-blowing and is amazing for an agent. It's also I think amazing for a potential game engine.

**[25:34]** And I actually like to call this um Barbapapa software.

**[25:39]** Uh Barbapapa is this cartoon from the '70s where you have all these characters and they go on adventures.

**[25:49]** And when they go on an adventure, they are able to shape-shift in whatever form is required for the adventure at hand.

**[25:56]** Like these.

**[26:00]** And software could be like this.

**[26:04]** You could have software that instead of that one programmer writes it once and thousands of people use it, that a programmer writes sort of like a base for the software and then when you use it, it sort of like morphs in morphs itself into whatever shape is good for you and is good for the problem you have right now.

**[26:29]** So pi can do that.

**[26:31]** Um can it also Oh. Ooh.

**[26:33]** Ooh, it's ready. Let's try.

**[26:36]** Um so another cool thing with pi, you can do slash reload.

**[26:40]** So it has hot reload for its own code changes that it do. I have no idea if this is going to actually Oh. Oh.

**[26:48]** Oh.

**[26:52]** Oh.

**[26:54]** Yeah.

**[26:55]** Here we go.

**[26:56]** Here we go. Here we go.

**[26:58]** All right, I'm going to end on that.

**[27:00]** Thanks, everyone.

**[27:01]** >> [applause] [applause]

---

## Plain Text

[clears throat] >> Everyone, my name is Lucas Meyer. I spent most of my life, my working life on game engines and games. One of them we managed to make quite popular, it's called Unity. And um turns out the robots can do programming. I I don't know about you, but I did not really have this on my bingo card. I'm still I'm still sort of trying to cope with this. Um I am playing around with new ideas for what a game engine might look like if you make it for agents or humans and agents instead of only humans. Um I host a call it like a coping session bi-monthly for brownfield programmers that decided that they want to be really good at all this AI stuff, but that they realize that um it's actually not so easy. Actually, who here is really good at using the AI agents? One? Mr. Dunning-Kruger here. >> [laughter] >> Um so, for the rest of us >> [laughter] >> My question is are you at stage nine? No, I am absolutely not at stage nine and I have a lot of opinions on the stage nine people. Um Let me begin by saying like my advice is to not chase every shiny new tool and only solve the problem you actually have, which is probably not at stage nine. That said, um here's my shiny tools. All right. I like to use Codex. Um I like I like to joke that it's like Claude code, but for programming. Maybe Claude is someone you'd invite to your birthday and Codex is this sort of autistic German. Um But if you want to write software, I really I'm going for Codex. All right. >> [laughter] >> Um There This is basically a snapshot of all the things that I learned that works for me, don't work for me. One of the things that work for me is embracing HTML as a output form factor. Um I, you know, the 1980s were cool, but coding agents in these small black and white boxes who like that is crazy. Um So, I like to do my prompts kind of like this. I try to find a repo on the monumental GitHub repo. I ask for like do a deep dive analysis and then a lot of the prompts I just end with present your work as a single HTML slide deck. And if you do that instead of a coding agent, you get something like this. With like this How do you call this? Like index on the left and I just find this like such a much more pleasant way to consume large amounts of information. It's also a much more pleasant to sort of like skip over stuff than when you read it from a terminal. There's no reason we should, you know, go back to that part of the '80s. Um Um Making your code base agent friendly. This is a game. Who knows this game? Uh some old-timers here. It's called Marble Madness. It's from the '90s. Um I like to pretend that the marble is your coding agent and the level is your repo. And it's your job for this marble to roll down your repo very conveniently. However, there's all sorts of hazards like the marble could fall off the cliff. For instance, if your agent's MD instructions are incomplete or wrong. Um if your build system that you use, if it has been spewing out 500 warnings for the last 2 years and you tell everyone, "Yeah, yeah, yeah, you know, ignore that." The agent's going to go off track with that. And there's all sorts of like your job is basically to change the repo so that the ball will fall down smoothly. I like to ask this question, what would have helped the agent reach its goal faster? And I think the only way to really do that is to just read the whole transcript. You read the whole transcript, you see all the tool calls, you see all the things it does and then you're like, "Why like why did it like why did it go there? Why did it go there?" And you just make changes accordingly, right? And if you'd done that actually, let me show you how I like to do that like I'm here. This is my favorite agent. I like to do {slash} share um to create these sort of like easily as you've noticed I like my HTML. Um I just go through the whole thing and I read all the tool calls and I figure out sort of like, you know, like how it was performing. If you've done that a few times like anything in software development, if you've done it a few times it starts to feel boring. Of course, you can use AI to help you with it. Um You can say something like analyze the previous session. Find places where the agent went in a wrong direction only to later figure out the right way. And of course, in my Um Oh yeah, and make me some recommendations on what I could have added to the repo that would have made it have it not make that mistake. Um Obviously, I ask it to report that stuff in HTML for me. This is one that I was working on the other day. It gives some, you know, info on how the session was going and then here it had some frictions and this one was funny to me because it turns out um this was on the game engine that I'm doing some work on. Um The documentation said that you have to call the the build command, you have to do {at} Mac if you want to do a Mac build. And then turns out the agent tried that and it was wrong. And then it had to read the whole source code of the build system to figure out like, "No, it's colon Mac." And I did change that like a few weeks ago. I just missed a spot in the docs. All right, so by fixing that I may, you know, like you can actually make a continuous process to to making your code base like the most beautiful Marble Madness level because this repeated process is actually what you need, right? Like it's super easy to have clunkers write MD files and you just get more and more and more and more and it's like, you know, this Google Drive from how many how many docs in the monumental drive? Notion. In the Notion like Like I'm I'm assuming it's hard to find things just by previous experience. Um Um Let me Am I join Yeah, let me I'm going to show this. Um I like to use this program. It's called Super code. Um it's like conductor, but I like it much better. Um Maybe we can go into why later. Um And I showed the share. Let me go back to this topic actually. Evaluating agent work. I think this is the biggest mental shift that made the biggest difference for me is thinking about how you're going to actually evaluate the agent's work, right? Like you give it a task and it goes off for half an hour and then at some point it's done, right? Now what? Like what you're going to do? Like you're going to read the whole transcript? Are you going to read the summary? Are you going to read the source code? Are you going to play the game? Open the website? Like what is it that you're going to do? And my advice is to ask yourself this question before you send the agent on its task. Because when you ask yourself the question before, you can actually put it in the prompt. And it turns out that agents really like to know ahead of time how you're going to evaluate the results because it also gives them a lot of clarity on when they are done and when they're not done. This is actually also a great tip for humans. >> [laughter] >> They also like to know how you're going to evaluate them and when they are done and when they're not done. >> [laughter] >> Actually, almost [clears throat] everything that you turns out with these agents like it's almost all true for humans, too. Okay, so you put it in the beginning. You tell it how you will evaluate. And one of the things that I like Actually, let me show you back to Super code. Yeah. So, on the Steve Yegge stage nine, there's like agent swarms and agents starting agents and all these things. I don't know what those guys are smoking. I'm not like I'm not having any of that, but you might see on the left side here. I do have like 10 or 12 of these things open. Right? But there's no spinners there because all of these agents work streams that I have, they're all waiting for me. Right? So, in this new world, I am absolutely the bottleneck. And it's act like if a agent does like an hour of work, it's actually a ton of work to evaluate it. Like it could take like 15 minutes depending on, you know, like the quality and how happy you with it. So, if I'm the bottleneck of my whole little software factory here, and I'm like the evaluation of the work is the bottleneck, let's try to have the agent do more of it. And let's like I like to call these evaluation packs. Like let's really as if it were sort of like you know, let let's make them a lot of work to present a beautiful package for you that makes it really efficient to evaluate. For instance, I one-shotted as a to prepare for this talk, I one-shotted a website to where you can have photos and you can drag them on a timeline for an animation and then set up transitions between them. The way I would ask to evaluate that is to say, well, why don't you record a video where you open the websites that you just made where you demonstrate to me all the different features by moving the mouse and doing all these things and make a recording of that and then obviously show it to me in a single page slide deck together with a bunch of other stuff. And if you ask that, it turns out you can just ask that. And I get back from my one-shot this evaluation pack which makes my life easier to evaluate what it's done and also to quickly evaluate if I kind of like it. Like it makes this video and I can hit play. Not sure how well the video works on this screen sharing thing, but here it is going through the different photos. It's renaming them. It's adding them to the timeline. It's changing transitions and by making it do the work to make my evaluation life easy, I get to spend less time on the evaluation and I can get more of these individual work streams done. Additionally, it also helps the agent to not cheat. Right? It's super easy for the agent to say like, yeah, wrote some code and I think we're good. Um if you force it to make a video, it has to open it in Chrome or whatever and it will run all the JavaScript and if there's an error there, it will find it and if it fails to actually do these commands, it will notice it and it will kick itself in a loop to try to fix that. Um all right, so that is Oh, yeah, and then I all like because the video is actually hard for the agent to read itself, I also always ask it for a bunch of screenshots because you can force it to actually read the image files and use the models in How do you call that, Rick? The image >> Multi-model capabilities. Yeah, multi-model capabilities to actually look at the picture to see what is wrong. All right. Um let me speed through this. Um here we are. All right, so then finally, um I am in this rabbit hole of Pi. Pi is a coding agent. The rest of this talk is my love letter to Pi. Uh Pi is not Cloud Code. It is not Codex. You can use whatever model you want. Um and I love it because it's hackable. Um we just uh you know, we just did a poll and it turns out none of you know what we're doing with coding agents. I also have no idea what we're doing with coding agents. The Cloud Code guys have no idea. The Codex guys have no idea. We're so early. We have no idea what an ergonomic AI assistant actually looks like and that's why in this phase it's so important to just try endless and throw it against the wall and see what sticks. Right? And um oh, yeah, that is this. So, uh being able to experiment with what works for you as a person, what works for your project is super important. What is not amazing is waiting for some Cloud Code guys in San Francisco to come up with the workflow that is sort of like middle of the road for everyone that might or might not work for you. And that is why I love Pi because it allows you to do these things. It also has precise context management and I hope to show some of these things. Let me start off with the context management. So, I was rehearsing this thing in the back and I have all this stuff in my session here. I'm going to do {slash} tree. Let me actually Can you guys read that? It's I'm going to do {slash} tree, my Pi feature. And you get an overview of your entire context over here. And you'll notice that it's not linear, but that I've actually gone into different branches. Um since the bottom here was all a bit nonsense, I'm going to go back to this one. I'm going to hit enter. And then for now, I'm going to say no summary. And what this does is it brings me back to the beginning of the context. I get all that context back. Um let me ask for this is the repo of this sort of game engine experiment. Like run the fighter game for me. Let's hope Codex is not down. Ooh. Uh-oh. >> [laughter] >> Let's try that again. That looks better. Um all right, so fighter game. Nothing in particularly exciting about it. Um all right. Um I'm sorry, I lost my train of thought. Where was I? So, yeah, I so I went back with the So, I went back with {slash} tree to the beginning of the context and the {slash} tree I actually use it all the time because very often you will go into a side quest that turns out to be a dead end. Right? Let me actually you know, let's go into the side quest with the dead end. Like ask me five questions about my beef chili. All right. Slight detour. Bear with me. Um I'm going to do {slash} answer here. {slash} answer. {slash} answer is an extension that some random dude on the internet made. This is not part of Pi. It is someone that thought, you know what really sucks about coding agents? That when you ask them to interview about your plan and you get 20 questions that you have to sort of like type them back one by one. Like yeah, oh yeah, the answer to 16 is yes and then the answer to the other one Oh, yeah, scroll back. Oh, yeah, 17. Yeah, 17 is no. So, he figured like what if we just had like a special UI for that? And he wrote an extension for it called answer and what it does it takes the previous message, sends it to some to some cheap LLM to extract all the questions and then preserve like present it to you in this nice UI. Uh what kind of beef? Um losses token. Very and never beans, you animal. Um and then when you are done with it, it just turns it into a user message like that. Just I I really like that as an example of how you can just notice a problem that you actually have, like answering these plan questions, instead of a problem that you don't have, which is, you know, like how do I keep 20 agent swarms busy? All right, now that we went into a useless side quest, I can finally so show what I like {slash} tree for. Because you pay for all these side quests in your context, right? It's very normal for people to what's it called? Anthropomorphize their coding agent like it's some human you're supposed to talk to. No. No, it's not a human and you're also not really supposed to talk to it like that. It is a token producing machine that can help you get to good code, but you shouldn't pretend it's like a conversation. Like very often the right thing to do is like you should never tell it like, no, I didn't want it like that. I wanted it like that. Like when I have when I when it made something I didn't like, I'd use {slash} tree and I go back and then I ask it in a different way. I never, you know, like like don't argue with these things. Um if you do argue with them or if you if you say like, okay, forget about it. Let's just continue with this other feature. You continuously pay for this side quest to be in your context. You pay for it in tokens and you pay for it in intelligence because once your once your context gets longer, like once you get into the 50, 60% range, you enter like this dumb zone and it gets more stupid. So, it's really important. I'm not sure if you can see it down here, but most coding agents these days show you how far you are in the context window. If like if I see that go above 50, I get very nervous. I try to always make sure I am below 50. Um so when I go into this side quest like this, uh and then later it turns out that the discussion about beef is maybe not uh beneficial to the rest of my demo, I'm going to go back here. And here I can choose. I can say no summary, it will just throw it away. I'm probably going to do that because for the rest of the demo, the agent won't get better performance if it knows my beef preferences. If it was a side quest where you do something on your project that is actually useful to know that you tried it and that it failed because blah, then you would do summary and it would put a summary in there. So it's like you have much more intention and control over your context than most other coding agents provide. I think they're also catching up. I'm not I'm not quite sure, but having this control is super important. Um All right. I think I have one or two more things. Um notice um so one of the cool things about this game engine project I have Do I have um is that I have like full local CIs. I'm going to make a change to arena, which is like my main memory allocator that gets used everywhere. And now I'm going to ask like, hey, do a full CI run using uh S A all with a colon, not with a at symbol. And one of the things that was annoying me about these coding agents is that when you have these long-running tool calls, you have so poor visibility in what's going on. Right? Like when it does like rep grip, it's not a problem because it just finishes immediately. But the but I have Oh, this is not going well. What did did did it ever show the thing? Yes. Yeah. Was it just very quickly run? >> [clears throat] >> Oh, here we go. Oh, that's not good. Oh, you think I think my build system is so good that I already that it has this one cached. I'm going to do it like this. Here, try again. Um But it like I really disliked that you had such poor visibility. So I figured, oh, it would be cool if we can actually run these uh commands as a virtual terminal and that my coding agent actually shows it to me when it's working so that when it's sitting there for 10 minutes, which is like that is sometimes fine and that is sometimes uh it's stuck on something and it would be very nice if I could see it. So I made this this morning and um I thought it was a cool example of my new sort of like mental model, like how am I going to write a feature like this? How am I going to like it's cool that pilot should do it the first place. Yay pi. Uh but how like when when you write a feature like that, how are you going to close the loop? How are you going to make the agent know if the thing it wrote worked? And how am I going to check? And for this one, I asked it to write a single page HTML file. Here, this one. I asked it to like, hey, write me a bunch of different test programs that do different things with the terminal, you know, like alt screen, all these spinners, different colors, different repainting, like sending a hundred screens, all these test cases. And then I asked it to like, okay, well, run it through the code, make screenshots every few seconds, turn them into an animated GIF, put the animated GIF in my HTML file so that my job of reviewing it is easy. Right? And then run both my my virtual terminal code path against pi's own code path over there so that I can quickly see that it that that matches. It has some alt screen code, some synchronization code. I'm like it tries curl, it tries FFmpeg. So that's sort of it's another example of putting the onus on the agent to do the work for both the agent's benefit, making sure that it actually works, and my benefit of making it easy to get confidence that this thing actually works. Oh. Ah. All right, that is a bummer. I am going like let me do one final demo. It's probably too late. Uh I wanted to do this at the beginning to show you that the thing that's probably coolest is that I can write extensions for itself because it's a coding agent that has access to its own docs. So let's try make a quick extension that when the agent starts, I can play Doom in an overlay. And we'll see if we like if it is quick enough for this thing to work. Um This particular form of software where software finishes [snorts] and extends and configures itself while it is running on the user machine, I find mind-blowing and is amazing for an agent. It's also I think amazing for a potential game engine. And I actually like to call this um Barbapapa software. Uh Barbapapa is this cartoon from the '70s where you have all these characters and they go on adventures. And when they go on an adventure, they are able to shape-shift in whatever form is required for the adventure at hand. Like these. And software could be like this. You could have software that instead of that one programmer writes it once and thousands of people use it, that a programmer writes sort of like a base for the software and then when you use it, it sort of like morphs in morphs itself into whatever shape is good for you and is good for the problem you have right now. So pi can do that. Um can it also Oh. Ooh. Ooh, it's ready. Let's try. Um so another cool thing with pi, you can do slash reload. So it has hot reload for its own code changes that it do. I have no idea if this is going to actually Oh. Oh. Oh. Oh. Yeah. Here we go. Here we go. Here we go. All right, I'm going to end on that. Thanks, everyone. >> [applause] [applause]