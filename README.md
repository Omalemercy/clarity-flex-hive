# FlexHive
A decentralized marketplace for flexible gigs and short-term work opportunities on the Stacks blockchain.

## Features
- Create and manage gig listings
- Apply for gigs
- Accept/reject applications
- Release payments upon work completion
- Dispute resolution system
- Rating system for both employers and freelancers

## Setup and Installation
1. Clone the repository
2. Install Clarinet (if not already installed)
3. Run `clarinet check` to verify contracts
4. Run `clarinet test` to run the test suite

## Usage Examples
```clarity
;; Create a new gig listing
(contract-call? .flex-hive create-gig "Backend Development" u5000000 u30 "Description...")

;; Apply for a gig
(contract-call? .flex-hive apply-for-gig u1 "Cover letter...")

;; Accept an application
(contract-call? .flex-hive accept-application u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Complete work and release payment
(contract-call? .flex-hive complete-gig u1)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
