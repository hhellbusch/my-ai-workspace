# Transcript: Why AI Agents Break Zero Trust at the Last Mile

- **Channel:** IBM Technology
- **URL:** https://www.youtube.com/watch?v=SbrEk_tXZaE
- **Duration:** 13:02
- **Fetched:** 2026-05-30 19:02:49
- **Segments:** 162

---

**[0:00]** Howdy everyone.

**[0:00]** In this video we're going to investigate the agentic last mile identity problem.

**[0:01]** This is the critical gap between an AI agent's high level reasoning and its ability to reliably integrate and execute in real world fragmented systems, which open security risks.

**[0:11]** We'll look at the last mile challenge.

**[0:19]** And discuss how to address it.

**[0:21]** Before we dive into this, let's start with what is a last mile problem?

**[0:24]** One of the most traditional ones that we've have come across was actually around internet providers trying to get high speed access to people's homes.

**[0:35]** Now, they were able to build very big and fast trunk lines, which were super fast, but the challenge they had was, how do I connect this to homes that have been built years ago, if not hundreds of years ago that have existing infrastructure.

**[0:49]** They have high speed trunks.

**[0:53]** But how do I get it to an old existing infrastructure and get those high speeds in?

**[0:54]** That was the problem that internet providers were faced with.

**[1:00]** How do we get that last mile to the house to get them the high speed access that was available?

**[1:04]** And these are the kinds of things that we're looking at in the agentic world.

**[1:10]** When we think about agentic and the last mile challenge, let's start with by reviewing an AI and agentic system.

**[1:14]** Let's start with, we have a user, they're happy AI user, and they're going to connect with a chat or some application that's AI enabled, and they are going to ask questions.

**[1:30]** That's going to go off to an agent, we'll call this A1.

**[1:35]** There's likely an LLM in here that's interacting and providing reasoning and intelligence.

**[1:39]** That's getting to in turn talk to possibly an MCP server, and behind this, we're going to have either some processes that we want to run, or we're gonna have possibly data that we wanna connect to.

**[1:58]** So we're to have these connections.

**[2:02]** Now, when we think about this system, this part is where we're really emerging today.

**[2:10]** We're building these agentic systems that know how to talk, know how to reason, know how to execute, know-how to communicate, whether it's 808 or some way.

**[2:14]** This is all pretty new and we're building this out and we know how to do this.

**[2:19]** This piece that we're connecting back here, this is actually our last mile.

**[2:23]** These are systems a lot of times in companies that have been around for a long time.

**[2:29]** They're, at least in the agentic sense, legacy systems.

**[2:35]** They were not built with agentic in mind.

**[2:39]** They were built with applications trying to talk to them.

**[2:41]** So this is how do we connect this world, this emerging world of agentic to the last mile, to our systems that have been around for a long time within an enterprise.

**[2:50]** All right.

**[2:54]** So when we're thinking about this, the first thing we want to talk to, okay, so we have our last mile.

**[2:55]** Why?

**[3:01]** Is this a challenge?

**[3:04]** Alright.

**[3:08]** The first thing when we look at this whole system is that the end of this is not verifying the user.

**[3:09]** In other words, we have a person here.

**[3:24]** They come in.

**[3:27]** They log in.

**[3:28]** We know who they are.

**[3:29]** We know in the chat.

**[3:30]** We know when the agent.

**[3:32]** We know all through this flow.

**[3:33]** We know exactly who that person is.

**[3:34]** When we get to here, a lot of times these systems may be running and connecting with like an API key or they have some sort of shared credentials.

**[3:43]** In other words, you've got, traditionally, we've got two applications that are trying to talk to each other and they have their own credentials between the application and data or processes that they're trying to connect to.

**[3:55]** None of that really contains any information about who that user is.

**[4:02]** So we lose verifying at the very end who it is that's initiating the prompt into this agentic system.

**[4:07]** So that's the first thing that that we need to think about or why we have a challenge with the last mile.

**[4:18]** The next thing is that the end is not checking a certain set of things that we think about in an agentic world.

**[4:22]** So the first thing that it's not checking is the specific intent.

**[4:34]** And that really gets to, all right, we have a user and they intend to change a password or change some data at the very end.

**[4:42]** That's their intent.

**[4:50]** When we're dealing with an API key or just credentials between applications, that intent gets completely lost.

**[4:51]** The same thing is true for context.

**[4:57]** We lose the context.

**[5:00]** What is the environment that we're working in?

**[5:02]** What are the systems in this agentic system that we are talking about?

**[5:04]** That gets lost when we get down to this point.

**[5:07]** The other thing that we lose or is not available is delegation.

**[5:10]** Again, if we're dealing with our backend legacy applications and they're dealing with certain ways to connect, when we're looking at agent one has been working on behalf of the user, we've delegated our work to this agent and that's coming and doing something, we lose that.

**[5:29]** We don't know that an agent has had its, is working on the behalf of a user.

**[5:35]** So that's another piece that we lose into this.

**[5:39]** And at the end of this, because of this if we leave this whole last mile challenge alone what happens is what's left unguarded then is that we break zero trust.

**[5:50]** First thing we do is we lose our ability to have zero trust because we now have lost everything from the left to the right behind and now we don't have zero of trust. The other thing...

**[6:06]** that happens, if we leave this alone, is it allows agents actually to chain tools.

**[6:12]** And what this really says is that, now that these are just connected through kind of you know, traditional connections.

**[6:22]** An agent can say, I want to call this API key.

**[6:29]** I've got another one.

**[6:31]** I can just start chaining all these processes together because we don't have the context.

**[6:32]** We don't the intent.

**[6:36]** We don't have a lot of that.

**[6:37]** So now we can chain this.

**[6:38]** And ultimately, what happens is that this whole system, because of the last mile challenge, becomes a target for attackers.

**[6:39]** In other words, we could have a rogue agent, here's rogue one, and it's connecting, it's trying to infiltrate into our system, and it is actually connecting to MCP and says, hey.

**[7:00]** I am a good agent, and please connect me to these backend processes and these backend data systems.

**[7:09]** And yes, use whatever it is you need to connect.

**[7:15]** So this is ultimately what happens is we really open ourselves up to a lot of risk.

**[7:17]** All right, so now when we kind of know how what the last mile problem is, we know what the challenges are.

**[7:22]** Let's start talking about the last mile and what to do, how do we fix this?

**[7:31]** First thing that we need to do is we really need to validate.

**[7:40]** Identity.

**[7:50]** Context.

**[7:51]** And delegation.

**[7:54]** When we get to the end, we're going to need to know who the person is, what the context is, and what the delegation is.

**[7:56]** Now, you can say, okay, that's a lot easier said than done because these are systems that are operating off of a different environment and a different way of connecting.

**[8:08]** So how do we actually validate this?

**[8:12]** Well, one part of this is to use policies.

**[8:15]** Via ABAC.

**[8:22]** And PBAC.

**[8:24]** Okay, so this is attribute based access controls and this is policy based access control.

**[8:25]** So we want to actually start adding that in back here.

**[8:30]** Whatever we're connecting to...

**[8:35]** we want to make, start having our access control set up here.

**[8:39]** So they actually take the attributes.

**[8:43]** Attributes, one attributes are, is the environment.

**[8:45]** Another attribute is the subject, the user.

**[8:48]** And so we can bring that together and have policies then on our legacy systems that take into account different ways of doing access control and can start applying things that we need to understand what's the context, what's they user and how are they trying to access stuff.

**[9:05]** The next thing that we can do, and this is where this really starts bringing in how to achieve the last mile problem, is we can connect the last miles via a vault.

**[9:17]** So this is now we're going to bring into the middle here, we're gonna bring a vault.

**[9:26]** And this is a place to store and control operations.

**[9:31]** So instead of going this path, we will actually go to a vault and the vault will connect off to our tools.

**[9:35]** Now, with our vault, we can do a handful of really powerful things.

**[9:41]** One, we can we can the validation that we talked about.

**[9:46]** We can look at, so now this is really kind of part, it's kind of bridging between our agentic systems in our our legacy enterprises so we can actually know who the user is, who the audience is, what are the claims that are coming in.

**[10:00]** So we can bring this all into the vault and understand those things that we need to do to validate all this information, identity, delegation, all that stuff we can do here.

**[10:11]** The next thing is that we can make this policy-based.

**[10:16]** So we bring in these policies in into the vault and say, okay, if we understand the identity, delegation, all that, what policies can we implement then to connect to our enterprise and back-end systems?

**[10:28]** And the nice thing with this is we can actually now start issuing short-term credentials.

**[10:34]** In other words, Instead of having long-lived API keys or long-live shared credentials on the back end, we can actually start doing credential management and access management, bring those in.

**[10:52]** And do a rotational thing where we can actually now assign a new credential to access the back.

**[10:58]** These are things that enterprise systems know how to do and make them very short lived.

**[11:04]** So we bring in the user, the user says what they wanna do, we understand the context, we understand intent.

**[11:08]** That then says, the vault then says okay, I'm gonna take a credential, swap that out, so we store this with all in the vault and we swap out a short term credential then that now connects to these backend systems. And by using this, we kind of set up ourselves a little bit of an abstraction layer that, like I mentioned, bridges between the new evolving agentic world and our legacy backend system, allows us to interact and integrate with the backend while not losing many of these things, you know, the risks and challenges that we identified.

**[11:45]** The last thing that we kind of want to do then is we also want to have telemetry.

**[11:49]** That we can use to deny.

**[11:58]** Or narrow.

**[12:02]** Our permissions.

**[12:05]** In other words, we want to start collecting and storing telemetry.

**[12:07]** And this is what's happening.

**[12:14]** As users start interacting, as agents start interacting with the system.

**[12:16]** We start having our policies in place, we have the vault in place.

**[12:20]** Now we start collecting the behaviors, seeing what's actually happening, and that telemetry can then feed back into our policies.

**[12:27]** These policies feed back in to our vault so that now we can remove access or the next time somebody comes in we can actually restrict the privileges that are coming in.

**[12:38]** All right, as discussed, while many companies are currently exploring and employing these agentic systems.

**[12:41]** The last mile identity problem remains a challenge.

**[12:49]** So what kind of challenges and solutions are you looking at to solve this problem?

**[12:54]** Please comment below and thank you for watching.

---

## Plain Text

Howdy everyone. In this video we're going to investigate the agentic last mile identity problem. This is the critical gap between an AI agent's high level reasoning and its ability to reliably integrate and execute in real world fragmented systems, which open security risks. We'll look at the last mile challenge. And discuss how to address it. Before we dive into this, let's start with what is a last mile problem? One of the most traditional ones that we've have come across was actually around internet providers trying to get high speed access to people's homes. Now, they were able to build very big and fast trunk lines, which were super fast, but the challenge they had was, how do I connect this to homes that have been built years ago, if not hundreds of years ago that have existing infrastructure. They have high speed trunks. But how do I get it to an old existing infrastructure and get those high speeds in? That was the problem that internet providers were faced with. How do we get that last mile to the house to get them the high speed access that was available? And these are the kinds of things that we're looking at in the agentic world. When we think about agentic and the last mile challenge, let's start with by reviewing an AI and agentic system. Let's start with, we have a user, they're happy AI user, and they're going to connect with a chat or some application that's AI enabled, and they are going to ask questions. That's going to go off to an agent, we'll call this A1. There's likely an LLM in here that's interacting and providing reasoning and intelligence. That's getting to in turn talk to possibly an MCP server, and behind this, we're going to have either some processes that we want to run, or we're gonna have possibly data that we wanna connect to. So we're to have these connections. Now, when we think about this system, this part is where we're really emerging today. We're building these agentic systems that know how to talk, know how to reason, know how to execute, know-how to communicate, whether it's 808 or some way. This is all pretty new and we're building this out and we know how to do this. This piece that we're connecting back here, this is actually our last mile. These are systems a lot of times in companies that have been around for a long time. They're, at least in the agentic sense, legacy systems. They were not built with agentic in mind. They were built with applications trying to talk to them. So this is how do we connect this world, this emerging world of agentic to the last mile, to our systems that have been around for a long time within an enterprise. All right. So when we're thinking about this, the first thing we want to talk to, okay, so we have our last mile. Why? Is this a challenge? Alright. The first thing when we look at this whole system is that the end of this is not verifying the user. In other words, we have a person here. They come in. They log in. We know who they are. We know in the chat. We know when the agent. We know all through this flow. We know exactly who that person is. When we get to here, a lot of times these systems may be running and connecting with like an API key or they have some sort of shared credentials. In other words, you've got, traditionally, we've got two applications that are trying to talk to each other and they have their own credentials between the application and data or processes that they're trying to connect to. None of that really contains any information about who that user is. So we lose verifying at the very end who it is that's initiating the prompt into this agentic system. So that's the first thing that that we need to think about or why we have a challenge with the last mile. The next thing is that the end is not checking a certain set of things that we think about in an agentic world. So the first thing that it's not checking is the specific intent. And that really gets to, all right, we have a user and they intend to change a password or change some data at the very end. That's their intent. When we're dealing with an API key or just credentials between applications, that intent gets completely lost. The same thing is true for context. We lose the context. What is the environment that we're working in? What are the systems in this agentic system that we are talking about? That gets lost when we get down to this point. The other thing that we lose or is not available is delegation. Again, if we're dealing with our backend legacy applications and they're dealing with certain ways to connect, when we're looking at agent one has been working on behalf of the user, we've delegated our work to this agent and that's coming and doing something, we lose that. We don't know that an agent has had its, is working on the behalf of a user. So that's another piece that we lose into this. And at the end of this, because of this if we leave this whole last mile challenge alone what happens is what's left unguarded then is that we break zero trust. First thing we do is we lose our ability to have zero trust because we now have lost everything from the left to the right behind and now we don't have zero of trust. The other thing... that happens, if we leave this alone, is it allows agents actually to chain tools. And what this really says is that, now that these are just connected through kind of you know, traditional connections. An agent can say, I want to call this API key. I've got another one. I can just start chaining all these processes together because we don't have the context. We don't the intent. We don't have a lot of that. So now we can chain this. And ultimately, what happens is that this whole system, because of the last mile challenge, becomes a target for attackers. In other words, we could have a rogue agent, here's rogue one, and it's connecting, it's trying to infiltrate into our system, and it is actually connecting to MCP and says, hey. I am a good agent, and please connect me to these backend processes and these backend data systems. And yes, use whatever it is you need to connect. So this is ultimately what happens is we really open ourselves up to a lot of risk. All right, so now when we kind of know how what the last mile problem is, we know what the challenges are. Let's start talking about the last mile and what to do, how do we fix this? First thing that we need to do is we really need to validate. Identity. Context. And delegation. When we get to the end, we're going to need to know who the person is, what the context is, and what the delegation is. Now, you can say, okay, that's a lot easier said than done because these are systems that are operating off of a different environment and a different way of connecting. So how do we actually validate this? Well, one part of this is to use policies. Via ABAC. And PBAC. Okay, so this is attribute based access controls and this is policy based access control. So we want to actually start adding that in back here. Whatever we're connecting to... we want to make, start having our access control set up here. So they actually take the attributes. Attributes, one attributes are, is the environment. Another attribute is the subject, the user. And so we can bring that together and have policies then on our legacy systems that take into account different ways of doing access control and can start applying things that we need to understand what's the context, what's they user and how are they trying to access stuff. The next thing that we can do, and this is where this really starts bringing in how to achieve the last mile problem, is we can connect the last miles via a vault. So this is now we're going to bring into the middle here, we're gonna bring a vault. And this is a place to store and control operations. So instead of going this path, we will actually go to a vault and the vault will connect off to our tools. Now, with our vault, we can do a handful of really powerful things. One, we can we can the validation that we talked about. We can look at, so now this is really kind of part, it's kind of bridging between our agentic systems in our our legacy enterprises so we can actually know who the user is, who the audience is, what are the claims that are coming in. So we can bring this all into the vault and understand those things that we need to do to validate all this information, identity, delegation, all that stuff we can do here. The next thing is that we can make this policy-based. So we bring in these policies in into the vault and say, okay, if we understand the identity, delegation, all that, what policies can we implement then to connect to our enterprise and back-end systems? And the nice thing with this is we can actually now start issuing short-term credentials. In other words, Instead of having long-lived API keys or long-live shared credentials on the back end, we can actually start doing credential management and access management, bring those in. And do a rotational thing where we can actually now assign a new credential to access the back. These are things that enterprise systems know how to do and make them very short lived. So we bring in the user, the user says what they wanna do, we understand the context, we understand intent. That then says, the vault then says okay, I'm gonna take a credential, swap that out, so we store this with all in the vault and we swap out a short term credential then that now connects to these backend systems. And by using this, we kind of set up ourselves a little bit of an abstraction layer that, like I mentioned, bridges between the new evolving agentic world and our legacy backend system, allows us to interact and integrate with the backend while not losing many of these things, you know, the risks and challenges that we identified. The last thing that we kind of want to do then is we also want to have telemetry. That we can use to deny. Or narrow. Our permissions. In other words, we want to start collecting and storing telemetry. And this is what's happening. As users start interacting, as agents start interacting with the system. We start having our policies in place, we have the vault in place. Now we start collecting the behaviors, seeing what's actually happening, and that telemetry can then feed back into our policies. These policies feed back in to our vault so that now we can remove access or the next time somebody comes in we can actually restrict the privileges that are coming in. All right, as discussed, while many companies are currently exploring and employing these agentic systems. The last mile identity problem remains a challenge. So what kind of challenges and solutions are you looking at to solve this problem? Please comment below and thank you for watching.