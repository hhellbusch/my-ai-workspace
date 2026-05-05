# Adaptive Questioning Guide

## Question Templates by Purpose

When "Ask me 4 more targeted questions" is selected, generate questions based on the purpose(s) selected in Step 0.

### For API Integration

- Which specific endpoints/resources? (e.g., for Stripe: payments, customers, subscriptions)
- Read-only, write access, or both?
- Any specific use cases to prioritize?
- Authentication scope needed?

### For Database Access

- Which database system? (PostgreSQL, MySQL, MongoDB, etc.)
- What operations? (SELECT only, full CRUD, complex queries)
- Specific tables/collections?
- Migration management needed?

### For File Operations

- What file types? (JSON, CSV, images, etc.)
- Read, write, or both?
- Batch processing or single files?
- Directory traversal needed?

### For Custom Tools

- What calculations/transformations?
- Input/output data types?
- Real-time or batch processing?
- Any external dependencies?

## Usage

1. Select relevant template based on purpose from Step 0
2. Generate 4 questions using AskUserQuestion tool
3. After receiving answers, analyze for gaps
4. Present decision gate again
5. Repeat until user selects "Proceed to API research"
