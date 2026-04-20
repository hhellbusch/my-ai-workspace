<objective>
Create a clear, professional disclosure notice that transparently communicates to readers that the majority of content in this workspace was created with AI assistance (Claude Code) and should be reviewed with appropriate scrutiny.

This notice serves to:
- Maintain transparency about content authorship
- Set appropriate expectations for content verification
- Demonstrate professional integrity in AI-assisted work
</objective>

<context>
This is a technical workspace containing examples, documentation, and troubleshooting guides for:
- Ansible playbooks and automation
- ArgoCD and GitOps patterns
- OpenShift/Kubernetes troubleshooting
- CoreOS configuration

The content was created with substantial AI assistance and should be validated before use in production environments.
</context>

<requirements>
1. Create a prominent AI disclosure notice that:
   - Clearly states that most content was AI-generated
   - Explains why additional scrutiny is appropriate
   - Maintains a professional, transparent tone
   - Avoids being defensive or apologetic
   - Provides guidance on how to approach the content

2. Place the notice in an appropriate location:
   - Add a prominent section to the main README.md
   - Consider also creating a dedicated NOTICE.md or AI-DISCLOSURE.md file
   - Ensure visibility without being intrusive

3. Use clear, professional language that:
   - Is honest and direct
   - Explains the benefits AND limitations of AI assistance
   - Encourages verification and testing
   - Maintains credibility of the workspace
</requirements>

<implementation>
1. Read the existing ./README.md to understand current structure
2. Add an "AI-Generated Content Notice" section near the top (after title/intro, before main content)
3. Include:
   - Clear statement of AI involvement
   - Explanation of what "additional scrutiny" means
   - Guidance on validation (test in non-production, verify examples, etc.)
   - Positive framing: AI-assisted content as starting points, not final authority
4. Keep the tone professional and matter-of-fact, not apologetic

Why this approach matters:
- Transparency builds trust with users of this workspace
- Setting appropriate expectations prevents misuse of untested AI-generated code
- Professional disclosure demonstrates engineering integrity
- Users can make informed decisions about content verification needs
</implementation>

<output>
Modify the existing file:
- `./README.md` - Add "AI-Generated Content Notice" section

Optionally create:
- `./AI-DISCLOSURE.md` - Detailed disclosure with best practices for using AI-generated content
</output>

<success_criteria>
- README.md contains a clear, visible AI disclosure section
- Notice explains both AI contribution and verification needs
- Tone is professional, transparent, and non-defensive
- Guidance is provided on appropriate use and validation
- Users can make informed decisions about content trustworthiness
</success_criteria>

<verification>
Before declaring complete:
- Read the modified README.md to ensure disclosure is clear and prominent
- Verify the tone is professional and transparent
- Confirm guidance is practical and actionable
- Check that the notice doesn't undermine the value of the content, but sets appropriate expectations
</verification>

