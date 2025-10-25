PTT Coupon (Clarity v3)

Overview
Adds a new independent coupon contract enabling each user to issue and redeem a one-time travel coupon. No cross-contract calls or traits. Uses explicit error constants and safe types.

Technical Implementation
- New contract: contracts/ptt-coupon.clar
- Storage: (define-map user-coupons { user: principal } -> { issued-at: uint, used: bool })
- Public entrypoints:
  - (issue-coupon): self-issue one coupon per user (errors if already issued)
  - (redeem-coupon): mark coupon used (errors if none or already used)
- Read-only:
  - (get-coupon user): returns coupon data or error

Testing & Validation
â€¢ âœ… Contract passes clarinet check
â€¢ âœ… All npm tests successful
â€¢ âœ… CI/CD pipeline configured
â€¢ âœ… Clarity v3 compliant with proper error handling