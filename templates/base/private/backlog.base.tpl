filters:
  and:
    - file.inFolder("private/backlog")
    - '!file.name.startsWith("Untitled")'
    - file.name != "_template"
formulas:
  status_rank: |-
    if(note.status == "in_progress", 1,
      if(note.status == "open", 2,
        if(note.status == "blocked", 3, 99)))
  tier_rank: |-
    if(note.tier == "XS", 1,
      if(note.tier == "S", 2,
        if(note.tier == "M", 3,
          if(note.tier == "L", 4,
            if(note.tier == "XL", 5, 99)))))
properties:
  note.id:
    displayName: ID
  note.title:
    displayName: Title
  note.status:
    displayName: Status
  note.priority:
    displayName: P
  note.tier:
    displayName: T
  note.created:
    displayName: Created
  note.closed:
    displayName: Closed
  note.tags:
    displayName: Tags
  note.refs:
    displayName: Refs
  note.blocked_by:
    displayName: Blocked by
  formula.status_rank:
    displayName: SR
  formula.tier_rank:
    displayName: TR
views:
  - type: table
    name: Active
    filters:
      and:
        - note.status != "done"
        - note.status != "archived"
    order:
      - id
      - title
      - file.name
      - status
      - priority
      - tier
      - tags
      - created
    sort:
      - property: formula.status_rank
        direction: ASC
      - property: priority
        direction: ASC
      - property: formula.tier_rank
        direction: ASC
    columnSize:
      note.id: 84
      note.title: 460
  - type: table
    name: Archived
    filters:
      and:
        - or:
            - note.status == "archived"
            - note.status == "done"
    order:
      - title
      - file.name
      - id
      - status
      - closed
      - tags
    sort:
      - property: closed
        direction: DESC
      - property: created
        direction: DESC
  - type: cards
    name: Cards
    filters:
      and:
        - note.status != "done"
        - note.status != "archived"
    sort:
      - property: formula.status_rank
        direction: ASC
      - property: priority
        direction: ASC
      - property: formula.tier_rank
        direction: ASC
    cardSize: 250
