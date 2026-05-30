# Transcript: Is this the only skill left?

- **Channel:** Hak
- **URL:** https://www.youtube.com/watch?v=7zCsfe57tpU
- **Duration:** 22:08
- **Fetched:** 2026-05-30 19:00:30
- **Segments:** 202

---

**[0:00]** It's a skill that all senior devs built by 
accident over years. And it looks like it's   the whole job now. That skill is systems thinking. 
These days in a world where AI generates code you   didn't write, you kind of need it on day one. 
That's the actual shift. If you're new here,   welcome. I'm Hak. I'm a product engineer turn 
founder and I've been building software for   over 20 years, writing code the old way and now 
building with AI daily. I run AgentiveStack,   a product studio where we build software that 
runs itself and where we explore this new wave   of agentic products and AI building. This channel 
is about that exploration, what actually works   and what's breaking quietly sometimes along 
the way. Now, let's get into it. In 1985,   a Danish computer scientist by the name of Peter 
Naur wrote a paper called Programming as Theory   Building. That paper touched on a simple but 
very interesting argument. That the code isn't   the program. The program is what lives inside 
the programmer's head. How the pieces connect,  

**[1:02]** why they connect in the ways they connect and 
what happens if you pull one out. That's the   program. The code is just the shadow of it, as 
Peter Naur puts it. Fourty years later, today we   have AI coding agents that generate that shadow 
on demand for us. But the program isn't gone. We   just stopped building the theory of it because 
these new tools that we have at our disposal   makes us confuse the two. Last week, I put out 
a video on comprehension debt or cognitive debt,   as a lot of you pointed out in the comments. The 
tax we pay when we ship AI generated code we don't   understand. Now, the video got a lot of traction, 
I have to say. Thousands of views and hundreds of   comments. But one question kept surfacing, coming 
from some of the juniors and people early in their   career asking "if AI writes the code, how do 
we build the judgment to evaluate it? Should I   still learn code these days?" That's a very fair 
question and it's a question everyone building  

**[2:05]** software with AI should be asking. I think we've 
been focused on the wrong skill because when   the code got cheap... no. Cheap is not the right 
word here... Easy. When code got easy to produce,   to generate, everyone doubled down on 
prompting. Better prompts, better models,   better tools. The prompting is the easy layer now 
and it's only getting easier, because new models   promise to understand user intent better without 
too much context. Although the output is still   disputable. But as we move forward with this new 
way of building software, there's one skill that   still matters and it will continue to matter for 
a good while. That skill is systems thinking or   systems design and architectural thinking if we 
spread it wider. It's a skill that all senior devs   built by accident over years. And it looks like 
it's the whole job now. We're moving up a layer   beyond mere code. So, let's do a quick definition 
because we can throw words around loosely. A  

**[3:12]** system is not just a bunch of parts put together. 
A system is a pattern of how those parts affect   each other over time. Change one and the others 
react. Miss a connection and the pattern breaks.  

**[3:27]** These come from systems dynamics. Let's think 
of it like an orchestra. Code is the instrument.  

**[3:33]** The system is the music. AI can play any 
instrument on demand. Violin, drums, brass,   often better than a human can. Now, music people, 
please don't backlash on this. I'm using it as an   analogy only. AI cannot replace you. But someone 
still has to conduct. Someone still has to know   how the parts fit together, when the strings 
should hold back, when the brass should come in.  

**[4:01]** That's the conductor. Now, that's you. No matter 
if you're a senior, junior, or non-technical, you   need to know how to conduct the orchestra. AI is 
the orchestra, but it will never be the conductor.

**[4:13]** And let's be honest about where we are right now, 
cuz we're not going back. That's for sure. Agentic   engineering is here to stay. The giants and the 
incumbents all push for it. The old ways are   pretty much gone. Spec-driven workflows, coding 
agents, AI pair programmers, agent harnesses.  

**[4:36]** That's the stack now. But the accumulated 
experience still applies more than we like   to admit. We just need to adapt to this new way. 
The job description of a developer has already   changed. It just hasn't updated in most people's 
head yet. Harvard researchers coined the term   jagged frontier, which describes the fact that the 
tech is sharp in some places and surprisingly dull   in others, sometimes in the same session. Knowing 
where those edges sit, like what the model nails   or what it quietly gets wrong, that's now a core 
developer skill. It's part of the new literacy.  

**[5:16]** So, let's make this more concrete. For builders, 
systems thinking comes down to three questions   you should be able to answer without running 
the code. One, where does state live? Meaning,   who owns the truth in the system? If two pieces 
each think they own it, you already have a bug.  

**[5:36]** You have an issue. You just haven't triggered it 
yet. Two, where does feedback live? What tells   you the system is working or not? How do you know? 
logs, metrics, errors, all bubbling up somewhere.  

**[5:48]** If nothing tells you that, the system isn't 
working. Probably is pretending to work. Three,   what breaks if I delete this? Can you trace 
the blast radius of any component or part of   the system in your head before you touch it? 
That's the theory Naur was talking about. Now,   I've been auditing AI built apps over the 
past few months, and the most recent one was   a Lovable-based product built by a non-technical 
founder. The product was already live for a few   weeks with real pay customers and quite a handful 
of third party integrations, which was impressive,   I have to say. That's what we want, after all, as 
builders. We want people using our products. But   the code base was a mess. There was this one file 
which was 7,000 lines long with several user flows   and business logic all tied up into one. Logs 
were empty. There was no rate limiting, no proper  

**[6:49]** error handling, but the app was apparently working 
until it didn't. Every single failure mode in   there was a systems thinking failure, not a coding 
one. Where does state live? Well, everywhere all   at once. Where does feedback live? Nowhere. We're 
blind. What breaks if I delete this? Never asked,   never cared. The system was incoherent. My audit 
report had a lot of critical stuff that needed to   be addressed ASAP before adding more customers or 
this thing will crumble as a house of card. Now,   we haven't touched base ever since, but it looks 
like they decided to rebuild it from scratch,   which was probably a good decision. So AI can 
write any individual piece and still have the   whole thing be nonsense if not done correctly. 
Now I need to address something because in the   last video the main push back in the comments 
was around how AI is just the next abstraction   layer. And just like we move from assembly 
to C to Python AI is the next step. Yes,  

**[7:52]** I agree. Thank god we don't write assembly 
anymore. And I get the argument, but I also think   it's wrong. Here's why. When you write Python 
code and the compiler produces machine code,   that translation is deterministic. For your input, 
you get the same output, provably correct. You   don't need to understand what the compiler did 
behind the scenes because the compiler guarantees   it did the right thing. That's what makes it a 
trustworthy abstraction. An LLM is not that. It's   just a probabilistic translator. It's stochastic 
by nature. For the same input, you get different   outputs almost each time. No guarantees. This 
compiler could introduce a security vulnerability,   a race condition, or a wrong business rule without 
you knowing. A compiler is a layer you can trust   without understanding. An LLM is a collaborator 
you can only trust by understanding what it did.  

**[8:51]** They're not the same kind of tool. The abstraction 
argument only works when the layer below you   is verifiable. This one is not, not in the 
traditional way. Now, systems thinking was always   critical. It just used to be something engineers 
build up over years. These days, in a world where   AI generates code you didn't write, you kind of 
need it on day one. That's the actual shift. One   more thing, because this matters. If you're a 
junior watching this, I don't want you thinking   you're the problem. You're not. The reason senior 
devs have this skill is that they suffered through   it. We had to. Every senior I know, me included, 
built this systems thinking skill by failing   publicly on systems we designed wrong in the 
first place. And yeah, we had users shouting   and stakeholders, PMs, product owners breathing 
down our necks. Sadly, that part hasn't changed   much. If anything, it's worse now from what I 
see around. The pressure only went up. Faster  

**[9:56]** shipping, higher expectations, less patience. 
What changed is the escape hatch. Back then,   when you hit a wall, the only way was through 
the wall. You had to sit with the code until   you actually understood what you ship. AI didn't 
take the pressure away. It took the wrestle away.  

**[10:15]** That suffering was the curriculum back in the 
day. The Harvard study by Hosseini and Lichtinger,   and I'm probably butchering the names, had pulled 
resume data from 62 million workers across 285,000   US firms and they found that after first quarter 
of 2023 companies adopting generative AI cut   junior hiring sharply while senior employment 
kept rising and they named it seniority-biased   technological change. The industry cut the path 
that used to turn juniors into seniors. But plot   twist, early 2026, the pendulum started swinging 
back. Software engineer postings on Indeed are up   11% year-over-year. Now IBM just announced it's 
tripling its entry level hiring in the US. Intuit   is expanding junior recruitment. Salesforce, whose 
CEO said last year they'd stop hiring engineers,   is back to hiring. The industry is figuring out 
quietly that AI is not the shortcut they thought  

**[11:20]** it was. They still need people who can oversee 
these agents only architecture and catch what they   models quietly get wrong. They broke the pipeline. 
Now they're realizing they can't live without it.  

**[11:33]** So they're back scrambling to rebuild what they 
just broke. And next time a CTO complains there   are no good mid-level engineers, remember the 
industry stopped letting anyone be a junior and   now they need them back. So if you're a junior, 
you're not behind. You just got robbed of the   forcing function, which means you have to build 
one on purpose. And that's the rest of this video.

**[11:57]** So here's how I think about it. AI coding is 
the fast food of our craft. It's cheap and   fast. Again, we need a better term. Cheap is not 
the right term, but it's genuinely useful when   you already know what a real meal tastes like. 
Senior devs had to cook every meal themselves for   years before AI showed up. So, they know what the 
real thing tastes like. They also know when the   fast food is off. Juniors today don't have that 
baseline. Their first 100 meals might come out of   a drive-thru. And that raises a real concern. If 
nobody cooks anymore, who becomes the chef? Will   we end up with a generation that never learned 
the craft? Honestly, I've been sitting with this   one. And I think yes, there will be fewer, but the 
ones who will make it will be more valuable than   any senior before them if they build the right 
discipline for it. Let's think about fitness for  

**[13:02]** a second because it's very relatable. A 100 years 
ago, everyone was fit because manual labor forced   it. Today, the average person is less fit because 
the environment does less of the work. But the   elite athletes today are the fittest humans who 
have ever existed. Because deliberate training is   a thing now in a way that it wasn't then. Coding 
is going down the same path. The average junior in   2026 will probably be less systems fluent than 
the average junior in 2010. But the junior who   deliberately trains, who chooses to cook or to 
lift, will be more differentiated than any junior   I came up with so far. The industry churns and the 
disciplined minority will compound. You just need   to pick which side of that you're on. And one 
more real change worth naming quickly which is   very relatable to me also. AI is collapsing these 
traditional silos of backend, frontend, dev-ops,  

**[14:05]** database. A dev who used to be pure backend can 
now ship full stack features without spending   6 months memorizing React conventions. The tools 
handle pattern matching and the developer handles   the judgment calls. Personally, I love the craft. 
I love building things from scratch. Software has   been my way of expressing that for the past 
two decades. I love sketching the idea. I love   putting pieces together, thinking about visuals, 
the user journeys, how someone actually interacts   with my product, nitpicking on the details, the 
micro interactions. But I also love the plumbing   behind it, the architecture, the networking, the 
services, how they all fit together. I could never   stay in one lane. Not frontend, not backend, not 
devops or whatever roles there were back then.  

**[14:54]** If I had to pick one, I'd probably pick frontend, 
but I knew that I would miss parts of the backend   and devops that I love. And that shape used to 
be a problem for me, at least. I've worked with   a lot of other engineers throughout the years 
who were a lot smarter than me and each one of   them was specialized, deep in their own lane. 
Now that shape flipped and AI handles the depth   of any of those lanes. What it can't do yet is 
hold the entire thing in its head, see the big   picture and decide what actually matters. That's 
the generalist's home base. That's their turf.  

**[15:33]** That's systems thinking. So this new way where 
generalists can work cross-stack more easily,   it fits perfectly. At least for me. I can finally 
focus on what I love the most, the craft. But that   only works if the judgment is there. And 
that judgment is again, systems thinking.

**[15:53]** And one more thing (I know I said that before). 
This skill is something we all need to build up   and use. Every builder touching these tools, not 
just the juniors or seniors. It's the same skill,   but depending on where you're standing, 
the move changes. If you're a junior,   don't stop using AI. Embrace it. You have access 
to tools I used to think as sci-fi when I was   at your stage. But use them as learning 
tools, not like a shortcut. AI can be a   great learning partner if you use it correctly. 
Yes, prompt, generate, but then study what comes   back. Treat the AI like an infinitely patient 
senior dev and ask it "why this approach? What   breaks if we did the other way? What are the 
alternatives?" Then maybe rewrite something by   hand every week from memory. This forces you 
to think slower while you write so you can   build up those mental models. Lines-of-code 
is a vanity metric, especially these days.  

**[16:56]** The next generation of seniors will be juniors 
who use AI to understand better and faster,   not the ones who ship the most code. If you're 
a mid or senior, well, embrace these tools,   my friends. They're not going anywhere. Don't be 
the person proudly saying, "I still write every   line by hand." That ship has sailed. But you have 
more important skills than just typing. You always   had. Your edge is the theory you already have. The 
scar tissue from systems you designed wrong. Use   AI to amplify that, not substitute for it. Let the 
agents handle the boilerplate, the grunt work and   you stay on the architecture, the big picture, the 
push packs and on the tough calls only experience   makes. And if you're a non-tech founder, operator, 
or PM shipping with these tools like Lovable,   Bolt, or Cursor, know this. What you're doing is 
real. Non-tech builders are shipping in weeks now   what used to teams 6 months. But remember the 
audits I mentioned earlier built by non tech  

**[18:02]** founders? Well, they did nothing wrong. They just 
didn't know what to look for. Maybe you don't need   to learn to code anymore, but you still need 
to learn thinking systems. And maybe learn the   language of software here and there. Ask those 
three questions before you ship. And know when   to bring someone who does speak code. Knowing 
when is also part of this new skill. Like I said,   different moves, same skill. Quick note, if 
this is your world, we're putting together a   community called Agentive Build backed by 
our product studio and it's for builders,   experienced and new, technical and non-technical 
that want to ship AI-built products that actually   last. Inside we'll touch in more details on things 
like architecture, scaling, cost patterns, design   systems, and other parts that vibe-coding skips. 
Link below if you want to get on the wait list.

**[19:01]** So, how do you actually train systems thinking 
when nothing is forcing you? How do you stay   disciplined when AI is doing the typing? Well, 
I have four unsexy moves for you that compound   on each other. Design before you prompt. Take one 
page and just draw boxes for components and arrow   for data flows. Mark where state lives. Mark 
where failures surface. If you can't draw it,   you don't really understand it and the AI 
is going to build whatever you didn't draw,   which is usually the wrong thing. 10 minutes 
can reshape the entire conversation with AI.  

**[19:40]** Even with all these tools at my disposal these 
days, I deliberately slow down and start with pen   and paper to brain dump complex features before I 
get into building. Use specs as scaffolding. Write   the what and why before the AI writes the how. 
Even a short spec where you define a problem,   the constraints, the success criteria, failure 
modes. It's the safest vehicle we have right now   for working with this coding agents. I'll 
do a full video on spec-driven development   where it thrives and where it can break, from my 
experience. But for now, it's the best scaffold   we have for thinking in systems with this AI 
agents. Run the deletion test. Pick one component,   any component that you shipped recently, and ask, 
"If I delete this, what breaks and how badly?" If   the answer is, "I don't know." That's your new 
homework. That's your study list. That's how you  

**[20:41]** rebuild the theory. Study the generated code. 
Don't just accept it. In each meaningful PR,   push back on your AI agent. "Walk me through 
this. What alternatives did you consider?"   I said this before. Once a week, try to rewrite 
something AI generated by hand. That's how you   keep those code-reading muscles alive. So, here's 
where I land. The people who panic that AI is   going to replace developers, they're looking at 
the wrong layer. AI is replacing typing. It's not   replacing thinking in systems. Nothing replaces 
that. At least not in this generation of models.  

**[21:18]** Probably not the next one either. But there's 
also an uncomfortable part. AI amplifies you   if you have this skill and exposes you if you 
don't have it. Juniors who lean on AI without   building the theory underneath, they move fast 
right now, but in 5 years they'll be the people   who nobody wants them on the team. Non-dev people 
shipping with Lovable and Bolt will keep shipping   houses of cards until one of them falls on 
paying customers, which I've seen real cases.  

**[21:50]** The skill is learnable. It's just not promptable. 
Draw the system, build the theory. That's the   new curriculum now. Thanks for watching. 
I'm Hak. See you in the next one. Cheers.

---

## Plain Text

It's a skill that all senior devs built by 
accident over years. And it looks like it's   the whole job now. That skill is systems thinking. 
These days in a world where AI generates code you   didn't write, you kind of need it on day one. 
That's the actual shift. If you're new here,   welcome. I'm Hak. I'm a product engineer turn 
founder and I've been building software for   over 20 years, writing code the old way and now 
building with AI daily. I run AgentiveStack,   a product studio where we build software that 
runs itself and where we explore this new wave   of agentic products and AI building. This channel 
is about that exploration, what actually works   and what's breaking quietly sometimes along 
the way. Now, let's get into it. In 1985,   a Danish computer scientist by the name of Peter 
Naur wrote a paper called Programming as Theory   Building. That paper touched on a simple but 
very interesting argument. That the code isn't   the program. The program is what lives inside 
the programmer's head. How the pieces connect,   why they connect in the ways they connect and 
what happens if you pull one out. That's the   program. The code is just the shadow of it, as 
Peter Naur puts it. Fourty years later, today we   have AI coding agents that generate that shadow 
on demand for us. But the program isn't gone. We   just stopped building the theory of it because 
these new tools that we have at our disposal   makes us confuse the two. Last week, I put out 
a video on comprehension debt or cognitive debt,   as a lot of you pointed out in the comments. The 
tax we pay when we ship AI generated code we don't   understand. Now, the video got a lot of traction, 
I have to say. Thousands of views and hundreds of   comments. But one question kept surfacing, coming 
from some of the juniors and people early in their   career asking "if AI writes the code, how do 
we build the judgment to evaluate it? Should I   still learn code these days?" That's a very fair 
question and it's a question everyone building   software with AI should be asking. I think we've 
been focused on the wrong skill because when   the code got cheap... no. Cheap is not the right 
word here... Easy. When code got easy to produce,   to generate, everyone doubled down on 
prompting. Better prompts, better models,   better tools. The prompting is the easy layer now 
and it's only getting easier, because new models   promise to understand user intent better without 
too much context. Although the output is still   disputable. But as we move forward with this new 
way of building software, there's one skill that   still matters and it will continue to matter for 
a good while. That skill is systems thinking or   systems design and architectural thinking if we 
spread it wider. It's a skill that all senior devs   built by accident over years. And it looks like 
it's the whole job now. We're moving up a layer   beyond mere code. So, let's do a quick definition 
because we can throw words around loosely. A   system is not just a bunch of parts put together. 
A system is a pattern of how those parts affect   each other over time. Change one and the others 
react. Miss a connection and the pattern breaks.   These come from systems dynamics. Let's think 
of it like an orchestra. Code is the instrument.   The system is the music. AI can play any 
instrument on demand. Violin, drums, brass,   often better than a human can. Now, music people, 
please don't backlash on this. I'm using it as an   analogy only. AI cannot replace you. But someone 
still has to conduct. Someone still has to know   how the parts fit together, when the strings 
should hold back, when the brass should come in.   That's the conductor. Now, that's you. No matter 
if you're a senior, junior, or non-technical, you   need to know how to conduct the orchestra. AI is 
the orchestra, but it will never be the conductor. And let's be honest about where we are right now, 
cuz we're not going back. That's for sure. Agentic   engineering is here to stay. The giants and the 
incumbents all push for it. The old ways are   pretty much gone. Spec-driven workflows, coding 
agents, AI pair programmers, agent harnesses.   That's the stack now. But the accumulated 
experience still applies more than we like   to admit. We just need to adapt to this new way. 
The job description of a developer has already   changed. It just hasn't updated in most people's 
head yet. Harvard researchers coined the term   jagged frontier, which describes the fact that the 
tech is sharp in some places and surprisingly dull   in others, sometimes in the same session. Knowing 
where those edges sit, like what the model nails   or what it quietly gets wrong, that's now a core 
developer skill. It's part of the new literacy.   So, let's make this more concrete. For builders, 
systems thinking comes down to three questions   you should be able to answer without running 
the code. One, where does state live? Meaning,   who owns the truth in the system? If two pieces 
each think they own it, you already have a bug.   You have an issue. You just haven't triggered it 
yet. Two, where does feedback live? What tells   you the system is working or not? How do you know? 
logs, metrics, errors, all bubbling up somewhere.   If nothing tells you that, the system isn't 
working. Probably is pretending to work. Three,   what breaks if I delete this? Can you trace 
the blast radius of any component or part of   the system in your head before you touch it? 
That's the theory Naur was talking about. Now,   I've been auditing AI built apps over the 
past few months, and the most recent one was   a Lovable-based product built by a non-technical 
founder. The product was already live for a few   weeks with real pay customers and quite a handful 
of third party integrations, which was impressive,   I have to say. That's what we want, after all, as 
builders. We want people using our products. But   the code base was a mess. There was this one file 
which was 7,000 lines long with several user flows   and business logic all tied up into one. Logs 
were empty. There was no rate limiting, no proper   error handling, but the app was apparently working 
until it didn't. Every single failure mode in   there was a systems thinking failure, not a coding 
one. Where does state live? Well, everywhere all   at once. Where does feedback live? Nowhere. We're 
blind. What breaks if I delete this? Never asked,   never cared. The system was incoherent. My audit 
report had a lot of critical stuff that needed to   be addressed ASAP before adding more customers or 
this thing will crumble as a house of card. Now,   we haven't touched base ever since, but it looks 
like they decided to rebuild it from scratch,   which was probably a good decision. So AI can 
write any individual piece and still have the   whole thing be nonsense if not done correctly. 
Now I need to address something because in the   last video the main push back in the comments 
was around how AI is just the next abstraction   layer. And just like we move from assembly 
to C to Python AI is the next step. Yes,   I agree. Thank god we don't write assembly 
anymore. And I get the argument, but I also think   it's wrong. Here's why. When you write Python 
code and the compiler produces machine code,   that translation is deterministic. For your input, 
you get the same output, provably correct. You   don't need to understand what the compiler did 
behind the scenes because the compiler guarantees   it did the right thing. That's what makes it a 
trustworthy abstraction. An LLM is not that. It's   just a probabilistic translator. It's stochastic 
by nature. For the same input, you get different   outputs almost each time. No guarantees. This 
compiler could introduce a security vulnerability,   a race condition, or a wrong business rule without 
you knowing. A compiler is a layer you can trust   without understanding. An LLM is a collaborator 
you can only trust by understanding what it did.   They're not the same kind of tool. The abstraction 
argument only works when the layer below you   is verifiable. This one is not, not in the 
traditional way. Now, systems thinking was always   critical. It just used to be something engineers 
build up over years. These days, in a world where   AI generates code you didn't write, you kind of 
need it on day one. That's the actual shift. One   more thing, because this matters. If you're a 
junior watching this, I don't want you thinking   you're the problem. You're not. The reason senior 
devs have this skill is that they suffered through   it. We had to. Every senior I know, me included, 
built this systems thinking skill by failing   publicly on systems we designed wrong in the 
first place. And yeah, we had users shouting   and stakeholders, PMs, product owners breathing 
down our necks. Sadly, that part hasn't changed   much. If anything, it's worse now from what I 
see around. The pressure only went up. Faster   shipping, higher expectations, less patience. 
What changed is the escape hatch. Back then,   when you hit a wall, the only way was through 
the wall. You had to sit with the code until   you actually understood what you ship. AI didn't 
take the pressure away. It took the wrestle away.   That suffering was the curriculum back in the 
day. The Harvard study by Hosseini and Lichtinger,   and I'm probably butchering the names, had pulled 
resume data from 62 million workers across 285,000   US firms and they found that after first quarter 
of 2023 companies adopting generative AI cut   junior hiring sharply while senior employment 
kept rising and they named it seniority-biased   technological change. The industry cut the path 
that used to turn juniors into seniors. But plot   twist, early 2026, the pendulum started swinging 
back. Software engineer postings on Indeed are up   11% year-over-year. Now IBM just announced it's 
tripling its entry level hiring in the US. Intuit   is expanding junior recruitment. Salesforce, whose 
CEO said last year they'd stop hiring engineers,   is back to hiring. The industry is figuring out 
quietly that AI is not the shortcut they thought   it was. They still need people who can oversee 
these agents only architecture and catch what they   models quietly get wrong. They broke the pipeline. 
Now they're realizing they can't live without it.   So they're back scrambling to rebuild what they 
just broke. And next time a CTO complains there   are no good mid-level engineers, remember the 
industry stopped letting anyone be a junior and   now they need them back. So if you're a junior, 
you're not behind. You just got robbed of the   forcing function, which means you have to build 
one on purpose. And that's the rest of this video. So here's how I think about it. AI coding is 
the fast food of our craft. It's cheap and   fast. Again, we need a better term. Cheap is not 
the right term, but it's genuinely useful when   you already know what a real meal tastes like. 
Senior devs had to cook every meal themselves for   years before AI showed up. So, they know what the 
real thing tastes like. They also know when the   fast food is off. Juniors today don't have that 
baseline. Their first 100 meals might come out of   a drive-thru. And that raises a real concern. If 
nobody cooks anymore, who becomes the chef? Will   we end up with a generation that never learned 
the craft? Honestly, I've been sitting with this   one. And I think yes, there will be fewer, but the 
ones who will make it will be more valuable than   any senior before them if they build the right 
discipline for it. Let's think about fitness for   a second because it's very relatable. A 100 years 
ago, everyone was fit because manual labor forced   it. Today, the average person is less fit because 
the environment does less of the work. But the   elite athletes today are the fittest humans who 
have ever existed. Because deliberate training is   a thing now in a way that it wasn't then. Coding 
is going down the same path. The average junior in   2026 will probably be less systems fluent than 
the average junior in 2010. But the junior who   deliberately trains, who chooses to cook or to 
lift, will be more differentiated than any junior   I came up with so far. The industry churns and the 
disciplined minority will compound. You just need   to pick which side of that you're on. And one 
more real change worth naming quickly which is   very relatable to me also. AI is collapsing these 
traditional silos of backend, frontend, dev-ops,   database. A dev who used to be pure backend can 
now ship full stack features without spending   6 months memorizing React conventions. The tools 
handle pattern matching and the developer handles   the judgment calls. Personally, I love the craft. 
I love building things from scratch. Software has   been my way of expressing that for the past 
two decades. I love sketching the idea. I love   putting pieces together, thinking about visuals, 
the user journeys, how someone actually interacts   with my product, nitpicking on the details, the 
micro interactions. But I also love the plumbing   behind it, the architecture, the networking, the 
services, how they all fit together. I could never   stay in one lane. Not frontend, not backend, not 
devops or whatever roles there were back then.   If I had to pick one, I'd probably pick frontend, 
but I knew that I would miss parts of the backend   and devops that I love. And that shape used to 
be a problem for me, at least. I've worked with   a lot of other engineers throughout the years 
who were a lot smarter than me and each one of   them was specialized, deep in their own lane. 
Now that shape flipped and AI handles the depth   of any of those lanes. What it can't do yet is 
hold the entire thing in its head, see the big   picture and decide what actually matters. That's 
the generalist's home base. That's their turf.   That's systems thinking. So this new way where 
generalists can work cross-stack more easily,   it fits perfectly. At least for me. I can finally 
focus on what I love the most, the craft. But that   only works if the judgment is there. And 
that judgment is again, systems thinking. And one more thing (I know I said that before). 
This skill is something we all need to build up   and use. Every builder touching these tools, not 
just the juniors or seniors. It's the same skill,   but depending on where you're standing, 
the move changes. If you're a junior,   don't stop using AI. Embrace it. You have access 
to tools I used to think as sci-fi when I was   at your stage. But use them as learning 
tools, not like a shortcut. AI can be a   great learning partner if you use it correctly. 
Yes, prompt, generate, but then study what comes   back. Treat the AI like an infinitely patient 
senior dev and ask it "why this approach? What   breaks if we did the other way? What are the 
alternatives?" Then maybe rewrite something by   hand every week from memory. This forces you 
to think slower while you write so you can   build up those mental models. Lines-of-code 
is a vanity metric, especially these days.   The next generation of seniors will be juniors 
who use AI to understand better and faster,   not the ones who ship the most code. If you're 
a mid or senior, well, embrace these tools,   my friends. They're not going anywhere. Don't be 
the person proudly saying, "I still write every   line by hand." That ship has sailed. But you have 
more important skills than just typing. You always   had. Your edge is the theory you already have. The 
scar tissue from systems you designed wrong. Use   AI to amplify that, not substitute for it. Let the 
agents handle the boilerplate, the grunt work and   you stay on the architecture, the big picture, the 
push packs and on the tough calls only experience   makes. And if you're a non-tech founder, operator, 
or PM shipping with these tools like Lovable,   Bolt, or Cursor, know this. What you're doing is 
real. Non-tech builders are shipping in weeks now   what used to teams 6 months. But remember the 
audits I mentioned earlier built by non tech   founders? Well, they did nothing wrong. They just 
didn't know what to look for. Maybe you don't need   to learn to code anymore, but you still need 
to learn thinking systems. And maybe learn the   language of software here and there. Ask those 
three questions before you ship. And know when   to bring someone who does speak code. Knowing 
when is also part of this new skill. Like I said,   different moves, same skill. Quick note, if 
this is your world, we're putting together a   community called Agentive Build backed by 
our product studio and it's for builders,   experienced and new, technical and non-technical 
that want to ship AI-built products that actually   last. Inside we'll touch in more details on things 
like architecture, scaling, cost patterns, design   systems, and other parts that vibe-coding skips. 
Link below if you want to get on the wait list. So, how do you actually train systems thinking 
when nothing is forcing you? How do you stay   disciplined when AI is doing the typing? Well, 
I have four unsexy moves for you that compound   on each other. Design before you prompt. Take one 
page and just draw boxes for components and arrow   for data flows. Mark where state lives. Mark 
where failures surface. If you can't draw it,   you don't really understand it and the AI 
is going to build whatever you didn't draw,   which is usually the wrong thing. 10 minutes 
can reshape the entire conversation with AI.   Even with all these tools at my disposal these 
days, I deliberately slow down and start with pen   and paper to brain dump complex features before I 
get into building. Use specs as scaffolding. Write   the what and why before the AI writes the how. 
Even a short spec where you define a problem,   the constraints, the success criteria, failure 
modes. It's the safest vehicle we have right now   for working with this coding agents. I'll 
do a full video on spec-driven development   where it thrives and where it can break, from my 
experience. But for now, it's the best scaffold   we have for thinking in systems with this AI 
agents. Run the deletion test. Pick one component,   any component that you shipped recently, and ask, 
"If I delete this, what breaks and how badly?" If   the answer is, "I don't know." That's your new 
homework. That's your study list. That's how you   rebuild the theory. Study the generated code. 
Don't just accept it. In each meaningful PR,   push back on your AI agent. "Walk me through 
this. What alternatives did you consider?"   I said this before. Once a week, try to rewrite 
something AI generated by hand. That's how you   keep those code-reading muscles alive. So, here's 
where I land. The people who panic that AI is   going to replace developers, they're looking at 
the wrong layer. AI is replacing typing. It's not   replacing thinking in systems. Nothing replaces 
that. At least not in this generation of models.   Probably not the next one either. But there's 
also an uncomfortable part. AI amplifies you   if you have this skill and exposes you if you 
don't have it. Juniors who lean on AI without   building the theory underneath, they move fast 
right now, but in 5 years they'll be the people   who nobody wants them on the team. Non-dev people 
shipping with Lovable and Bolt will keep shipping   houses of cards until one of them falls on 
paying customers, which I've seen real cases.   The skill is learnable. It's just not promptable. 
Draw the system, build the theory. That's the   new curriculum now. Thanks for watching. 
I'm Hak. See you in the next one. Cheers.