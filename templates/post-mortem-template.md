# Incident Post-Mortem Template

**Incident Date**: YYYY-MM-DD  
**Authors**:  
**Status**: Complete / Under Review  

## Summary
Brief 2-3 sentence overview of what went wrong, the user impact, and how it was resolved.

## Impact
- **Services Affected**: 
- **Duration / Outage Window**: 
- **User Impact / Error Rate**: 
- **SLO / Error Budget Burned**: 

## Timeline (UTC)
- `HH:MM` - Anomaly triggered (alert fired).
- `HH:MM` - Incident response acknowledged.
- `HH:MM` - Root cause diagnosed.
- `HH:MM` - Mitigation applied.
- `HH:MM` - Service restored to normal baseline.

## Root Cause Analysis (5 Whys)
1. Why did the service fail?
2. Why?
3. Why?
4. Why?
5. Why?

## Action Items (Toil Reduction & Prevention)
| Action Item | Type (Prevent / Mitigate / Detect) | Owner | Priority |
| :--- | :--- | :--- | :--- |
| e.g., Add readiness probe delay | Mitigate | SRE Team | P1 |
| e.g., Set up alert on memory leak | Detect | Observability | P2 |
