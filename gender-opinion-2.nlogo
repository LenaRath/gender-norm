extensions [matrix nw]

globals[
  num-links
  unemployed-f     ;percent of women who are unemployed
  unemployed-m     ;percent of men who are unemployed
  mean-work-f      ;mean time per day in paid work: female agents
  mean-work-m      ;mean time per day in paid work: male agents
  mean-care-f      ;mean care work time per day: female
  mean-care-m      ;mean care work time per day: male
  history-length-norm    ; number of historic identity values that are considered at time = t
  history-length-work    ; number of historic work values
  history-length-care    ; number of historic care values
  th-work-change         ; threshold for when the difference between gender identity and work division is to high
]



turtles-own[
  systemic?            ;woman in this household works in systemic branch, man in short-time or unemployed
  rev-systemic?        ;man in this household works in systemic occupation, woman is at home
  gender-identity      ; ;describes in the opinion of this household the optimal division of care work   (0...man should do everything, 1..woman should do everything)
  fix?                 ;some do not change their gender identity
  care-f-m             ;a tuple that stores the hours spend for care work for f and m
  work-f-m             ;a tuple that stores the hours spend for paid work for f and m
  unemployed-f-m?      ;a tuple that stores wheter the woman or the man of this houshold is unemployed
  lockdown-work-f-m    ;a tuple that stores the hours for paid work for f and m
  care-history         ;save care-division
  identity-history     ;matrix with historical identity values in two columns: f and m
  work-history         ;matrix with historical identity values in two columns: f and m
  work-div             ;share of  paid work hours done by woman                                      (1...man single earner, 0 ... woman single earner)
  household-care        ;overall care work workload in this houshold
  lockdown-household-care
  potential-care-f-m       ;tuple that stores the hours left potentially for care work: hours - work-f-m
  friends
  eps
  n                   ;social norm of social group (friends)
  lockdown-hours      ;sum of hours care work and paid work during lockdown (increases hours by random value)
  ;hours               ;sum of hours care work and paid work during normal times (random value from normal distr. for each household)
  paygap              ;how much in relation to the man does the woman of this household earn
  income              ;income of this household
]


to setup
  clear-all
  random-seed seed
  set-initial-values
  set lockdown? false
  set-default-shape turtles "circle"
  create-turtles number-of-nodes [setup-nodes]
  ; setup systemic nodes
  ask n-of (number-of-systemic * count turtles / 100 ) turtles
  [
    set systemic? true
  ]
  ask n-of (15 * count turtles / 100 ) turtles with [not systemic?]       ;15% of households: the woman is at home and the man works outside the home
  [
    set rev-systemic? true
  ]
  ask n-of (fix * count turtles / 100 ) turtles
  [
    set fix? true
  ]
    set num-links (average-node-degree * number-of-nodes) / 2
   ;chose network type
  if network-type = "spatially clustered" [setup-spatially-clustered-network]
  if network-type = "random" [setup-random-network]
  if network-type = "small world" [setup-small-world-network]
  if network-type = "preferential attachment" [setup-preferential-attachment-network]
  set c a
  set d b
  reset-ticks
  if output-agents = true
  [
    file-close-all
    ;file-delete "agents.csv"
    file-open "agents.csv"
    file-print "agentid,initialid,care-f,care-m,work-f,work-m,period,id,"
    print_agents
  ]
end

to set-initial-values
  set-general-parameters
  (ifelse initial-values = "de" [
    set unemployed-f 5.2
    set unemployed-m 4.7
    set mean-work-f 4.43
    set mean-work-m 5.58
    set mean-care-f 3.8
    set mean-care-m 2.4
    ]
    initial-values = "us" [
     set unemployed-f 3.8
     set unemployed-m 3.7
     set mean-work-f 7.8
     set mean-work-m 8.65
     set mean-care-f 1.21
     set mean-care-m 2.4
    ]
  )
end

to set-general-parameters
  set history-length-norm 5
  set history-length-care 3
  set history-length-work 3
  set th-work-change 0.2
end

to setup-nodes
  setxy random-xcor random-ycor
  set lockdown-hours hours + add-care
  set gender-identity in-bounds(random-normal initial-identity 0.2)
  set paygap random-normal min list 0 mean-paygap 0.2
  set unemployed-f-m? list false false
  if (random-float 100 < unemployed-m) [set unemployed-f-m? replace-item 1 unemployed-f-m? true] ;US 3.7 D: 5.2
  if (random-float 100 < unemployed-f) [set unemployed-f-m? replace-item 0 unemployed-f-m? true] ;US 3.8 D: 4.7
  set identity-history n-values history-length-norm [gender-identity]  ; correct values, dist, deviance,.....
  set work-f-m [0 0]
  let work-f in-work(random-normal mean-work-f 5)    ;wegen random-seed!!!! ;US: 7.8 D: 4.43 (only employed noch suchen!)
  if (not item 0 unemployed-f-m?) [set work-f-m list work-f 0]  ; average working hours employed women 7.8/day  ;what distribution/ deviation,...... ?
  let work-m in-work(random-normal mean-work-m 5) ; US: 6.2 D: 5.58
  if (not item 1 unemployed-f-m?) [set work-f-m replace-item 1 work-f-m work-m]          ; average working hours employed men 8.65/day
  set work-history matrix:from-row-list (n-values history-length-work [work-f-m])
  set income ((item 1 work-f-m) + (item 0 work-f-m) * paygap)
  set care-f-m list in-hours(random-normal (mean-care-f) 5) in-hours(random-normal (mean-care-m) 5) ;distribution, deviation...? ;f 8.45/Woche? m 6.97/Woche US: 1.2/1 D:3.8/2.4
  set care-history matrix:from-row-list (n-values history-length-care [care-f-m])
  set lockdown-work-f-m [ 0 0 ]
  set household-care sum care-f-m  ;distribution, deviation, average.......
  if (household-care < 0) [set household-care 0]
  set lockdown-household-care household-care + max list 0 (min list (random-normal add-care 2) lockdown-hours)  ;(*2 weil per person????)
  set color scale-color red gender-identity 0 1
  set systemic? false
  set rev-systemic? false
  set fix? false
  set n 0.5
  if (sum care-f-m > 0) [set n (item 0 care-f-m / sum care-f-m)]
  set friends link-neighbors
end


to setup-random-network
  while [count links < num-links]
  [
    ask one-of turtles [create-link-with one-of other turtles]
  ]
  repeat 10
  [
    layout-spring turtles links 0.1 (world-width / (sqrt number-of-nodes)) 2
  ]
end


to setup-preferential-attachment-network
  ask one-of turtles [create-link-with one-of other turtles]
  while [count links < num-links] [
    ask one-of links [ask one-of both-ends [create-link-with one-of other turtles with [not link-neighbor? myself]]]
  ]
  repeat 10
  [
    layout-spring turtles links 0.1 (world-width / (sqrt number-of-nodes)) 1
  ]
end

to setup-small-world-network                             ; sets up a Watts-Strogatz-network
  layout-circle (sort turtles) (world-width / 2) * 0.8
  let neighbor-degree 1
  while [count links < num-links ] [
    let x 0
    while [ x < count turtles and count links < num-links] [
      ; make edges with the next two neighbors
      ask (turtle x) [create-link-with turtle ((x + neighbor-degree) mod count turtles)]
      set x x + 1
    ]
    set neighbor-degree neighbor-degree + 1
  ]
  ;; rewiring links
  ask links [
    if (random 100 < 0.2 * 100) [             ;rewiring probability 0.2
      ask one-of both-ends [create-link-with one-of other turtles with [not link-neighbor? myself]]
      die
    ]
  ]
;  repeat 10
;  [
;    layout-spring turtles links 0.1 (world-width / (sqrt number-of-nodes)) 1
;  ]
end


to setup-spatially-clustered-network                         ; links randomly chosen node with nearest node wich is not link neighbor
  create-turtles number-of-nodes [setup-nodes]
  while [count links < num-links ]
  [
    ask one-of turtles
    [
      let choice (min-one-of (other turtles with [not link-neighbor? myself])
                   [distance myself])
      if choice != nobody [ create-link-with choice ]
    ]
  ]
  ; make the network look a little prettier
  repeat 10
  [
    layout-spring turtles links 0.3 (world-width / (sqrt number-of-nodes)) 1
  ]
end

to go
  if (ticks >= ld-start and ticks <= ld-end)
  [set lockdown? true ]
  if (ticks = ld-start)
  [start-lockdown]
  if (ticks = ld-end)
  [set lockdown? false]
  ask turtles
  [
    set-confidence-bounds
    update-norm-new
    set-care-new
    update-work-friends-new
    update-work-new
    ;lose-job
  ]
  ;update-paygap
  if output-agents = true
  [
    print_agents
  ]
  tick
end


to set-confidence-bounds
    let x random-gamma 2.6 1
    set eps ( x / ( x + random-gamma 1.8 1) ) ;; set eps a random number from division Beta(alpha,beta) (between 0 and 1)
    set eps 0 + (eps * (0.18 - 0)) ;; scale and shift eps to lie between min_eps and max_eps: set eps eps min_eps + (eps * (max_eps - min_eps))
end


to start-lockdown
  ask turtles with [systemic? = false and rev-systemic? = false]
    [set lockdown-work-f-m list (item 0 work-f-m * (random-float lockdown-percent-f)) (item 1 work-f-m * random-float lockdown-percent-m)]
  ask turtles with [systemic? = true]
    [
      set lockdown-work-f-m list item 0 work-f-m  0
    ]
  ask turtles with [rev-systemic? = true]
    [
      set lockdown-work-f-m list 0 item 1 work-f-m
    ]
end

to update-work-new
  set work-div 0.5
  set income ((item 1 work-f-m) + (item 0 work-f-m) * paygap )
  if (not (sum work-f-m = 0)) [set work-div (item 1 work-f-m / sum work-f-m)] ;1 -> man single earner, 0 -> woman single earner
  if (abs(work-div - mean identity-history) > th-work-change)[
    let potential-m 0
    let potential-f 0
    ifelse(lockdown?)
      [
        set potential-f in-work(lockdown-hours - (lockdown-household-care - mean (matrix:get-column care-history 1)))
        set potential-m in-work(lockdown-hours - (lockdown-household-care - mean (matrix:get-column care-history 0)))
      ][
        set potential-f in-work(hours - (household-care - mean (matrix:get-column care-history 1)))
        set potential-m in-work(hours - (household-care - mean (matrix:get-column care-history 0)))
      ]
    let potential-income  ((potential-m)  + (potential-f) * paygap )         ;what the household may earn if they choose the new division
    let potential-div 0.5
    if (potential-f + potential-m > 0) [set potential-div (potential-m / (potential-f + potential-m))]
    if(abs(potential-div - mean identity-history) < abs(work-div - mean identity-history) and potential-income >= income * 0.9)
        [; if((hours * 2 - sum work-f-m - household-care) >= 0)[         ;household care needs to be done
          set work-f-m list in-work(mean list matrix:get-column work-history 0 potential-f) in-work(mean list matrix:get-column work-history 1 potential-m)
      ;   ]
        ]
   ]
  ;if(random-float 1 < 0.05) [set work-f-m list in-work(random-normal 2.19 2) 0]  ; average working hours employed women 7.8/day  ;what distribution/ deviation,...... ?
  ;if (random-float 1 < 0.05) [set work-f-m replace-item 1 work-f-m in-work(random-normal 6.02 1)]
  set work-history matrix:copy (matrix:submatrix work-history 1 0 history-length-work 2) ;add new row at the last position of matrix without the first row
  set work-history matrix:from-row-list (lput work-f-m (matrix:to-row-list work-history))
end


to update-work-friends-new
   ;;; someone from social group has higher income
  if(not (friends = 0))[
    let friend one-of friends with [income >= 1.3 * [income] of myself]
    if (friend != NOBODY)[
      let work-f 0
      let work-m 0
      ifelse (paygap < 1)[ ; paygap < 1 --> man earns more in this household
        ifelse(lockdown?)
           [set work-m in-work(max list (lockdown-hours - (lockdown-household-care - mean (matrix:get-column care-history 0))) (mean matrix:get-column work-history 1 * 1.2))]
           [set work-m in-work(max list (hours - (household-care - mean (matrix:get-column care-history 0))) (mean matrix:get-column work-history 0 * 1.2))]
      ][ ; paygap > 1 --> woman earns more
       ifelse(lockdown?)
        [set work-f in-work(max list (lockdown-hours - (lockdown-household-care - mean (matrix:get-column care-history 1))) (mean matrix:get-column work-history 0 * 1.2))]
        [set work-f in-work(max list (hours - (household-care - mean (matrix:get-column care-history 1))) (mean matrix:get-column work-history 0 * 1.2))]
      ]
      set work-f-m list mean (list matrix:get-column work-history 0 work-f) mean (list matrix:get-column work-history 1 work-m)
    ]
  ]
end

to lose-job
  if (item 0 work-f-m > 0 and random-float 100 < unemployed-f) [
      set work-f-m replace-item 0 work-f-m 0
    ]
  if (item 1 work-f-m > 0 and random-float 100 < unemployed-m) [
      set work-f-m replace-item 1 work-f-m 0
    ]
end

to update-norm
  if (not fix?)[
    set friends link-neighbors with [(abs (gender-identity - [gender-identity] of myself) < eps)]  ; confidence bound
    let cogn-diss gender-identity - 0.5  ;if no care work needs to be done
    ;let work-ratio 0.5
    if (sum care-f-m > 0)[
      ifelse(sum work-f-m > 0)
      [set cogn-diss gender-identity - mean list (item 0 care-f-m / sum care-f-m)(item 1 work-f-m / sum work-f-m)]
      [set cogn-diss gender-identity - mean list (item 0 care-f-m / sum care-f-m)(0.5)]      ;both do not work: share work hours equally
    ]
    ifelse (count friends > 0)
    [ ifelse(sum [work-f-m] of friends > 0)
      [set n (mean list (mean [item 0 care-f-m / sum care-f-m] of friends)(mean [item 1 work-f-m] of friends / sum [work-f-m] of friends))]
      [set n (mean list (mean [item 0 care-f-m / sum care-f-m] of friends) 0.5)]
      set gender-identity in-bounds( gender-identity - a * (gender-identity - n) - b * cogn-diss)
                                                           ; social control                   ; cognitive dissonance
    ]
    [
      set gender-identity  in-bounds (gender-identity - b * cogn-diss)
                                                            ; cognitive dissonance
    ]
    set gender-identity in-bounds(mean list gender-identity mean identity-history)
    set identity-history lput gender-identity butfirst identity-history
    ]
  set color scale-color red gender-identity 0 1
end

to update-norm-new
  if (not fix?)[
    set gender-identity mean identity-history
    set friends link-neighbors with [(abs (gender-identity - [gender-identity] of myself) < eps)]  ; confidence bound
    let cogn-diss gender-identity - 0.5  ;if no care work needs to be done
    let care sum care-f-m ;(ifelse-value lockdown? [lockdown-household-care][household-care])
    if (care > 0)[
      ifelse(sum work-f-m > 0)
      [set cogn-diss gender-identity - mean list (item 0 care-f-m / care)(item 1 work-f-m / sum work-f-m)]
      [set cogn-diss gender-identity - mean list (item 0 care-f-m / care)(0.5)]      ;both do not work: share work hours equally
    ]
    ifelse (count friends > 0)
      [ set n (mean [gender-identity] of friends) ]
      [ set n gender-identity ]
      set gender-identity in-bounds( gender-identity - a * (gender-identity - n) - b * cogn-diss)
                                                           ; social control                   ; cognitive dissonance
    set identity-history lput gender-identity butfirst identity-history
    ]
  set color scale-color red gender-identity 0 1
end

to set-care-new
  let ratio 0.5
  let x list 0 0
  let ideal-f-m list 0 0
  ;let pot-f-m list 0 0
  ifelse(lockdown?)
  [
    if (not (sum lockdown-work-f-m = 0))[set ratio (item 0 lockdown-work-f-m) / (sum lockdown-work-f-m)]  ;division of care work following the working hour division
    ;set pot-f-m list (lockdown-household-care * (1 - ratio))(lockdown-household-care * ratio)       ;division of care work following the working hours division
    set ideal-f-m list (lockdown-household-care * gender-identity)(lockdown-household-care * (1 - gender-identity)) ;care division according to gender identity
  ]
  [
    if (not (sum work-f-m = 0))[set ratio (item 0 work-f-m) / (sum work-f-m)]
    ;set pot-f-m list (household-care * (1 - ratio))(household-care * ratio)
    set ideal-f-m list (household-care * gender-identity)(household-care * (1 - gender-identity)) ;care division according to gender identity
  ]
  set n gender-identity
  if count friends > 0 [
    ifelse sum [care-f-m ] of friends > 0
    [set n (mean [item 0 care-f-m / sum care-f-m] of friends)]
    [set n 0.5]
  ]
  let hist list mean matrix:get-column care-history 0 mean matrix:get-column care-history 1
  let care-m max list 0 (item 1 hist - c * (item 1 hist - (1 - n) * household-care) - d * (item 1 hist - item 1 ideal-f-m))
  let care-f max list 0 (item 0 hist - c * (item 0 hist - n * household-care) - d * (item 0 hist - item 0 ideal-f-m))
  set care-f-m list (mean list mean (matrix:get-column care-history 0) care-f)(mean list mean (matrix:get-column care-history 1) care-m)
  set care-history matrix:copy (matrix:submatrix care-history 1 0 history-length-care 2) ;add new row at the last position of matrix without the first row
  set care-history matrix:from-row-list (lput care-f-m (matrix:to-row-list care-history))
end

to set-care
  let ratio 0.5
  let x list 0 0
  let ideal-f-m list 0 0
  let pot-f-m list 0 0
  ifelse(lockdown?)
  [
    if (not (sum lockdown-work-f-m = 0))[set ratio (item 0 lockdown-work-f-m) / (sum lockdown-work-f-m)]  ;division of care work following the working hour division
    set pot-f-m list (lockdown-household-care * (1 - ratio))(lockdown-household-care * ratio) ;(lockdown-hours - item 0 lockdown-work-f-m)(lockdown-hours - item 1 lockdown-work-f-m)       ;division of care work following the working hours division
    set ideal-f-m list (lockdown-household-care * gender-identity)(lockdown-household-care * (1 - gender-identity)) ;care division according to gender identity
  ]
  [
    if (not (sum work-f-m = 0))[set ratio (item 0 work-f-m) / (sum work-f-m)]
    set pot-f-m list (household-care * (1 - ratio))(household-care * ratio)   ;list (hours - item 0 work-f-m)(hours - item 1 work-f-m)
    set ideal-f-m list (household-care * gender-identity)(household-care * (1 - gender-identity)) ;care division according to gender identity
  ]
  ;let hist list mean matrix:get-column care-history 0 mean matrix:get-column care-history 1
  let care-m max list 0 (item 1 pot-f-m - c * (item 1 pot-f-m - (1 - n) * household-care) - d * (item 1 pot-f-m - item 1 ideal-f-m))
  let care-f max list 0 (item 0 pot-f-m - c * (item 0 pot-f-m - n * household-care) - d * (item 0 pot-f-m - item 0 ideal-f-m))
  set care-f-m list (mean list mean (matrix:get-column care-history 0) care-f)(mean list mean (matrix:get-column care-history 1) care-m)
  set care-history matrix:copy (matrix:submatrix care-history 1 0 history-length-care 2) ;add new row at the last position of matrix without the first row
  set care-history matrix:from-row-list (lput care-f-m (matrix:to-row-list care-history))
end

to-report in-hours [x]
  ifelse(not lockdown?)[
   ifelse (x > 0)
     [ifelse (x < hours)
       [report x]
       [report hours]
    ]
    [report 0]
  ]
  [
  ifelse (x > 0)
     [ifelse (x < lockdown-hours)
       [report x]
       [report lockdown-hours]
    ]
    [report 0]
  ]
end

to-report in-work [x]
  ifelse (x > 0)
  [ifelse (x < max-work)
    [report x]
    [report max-work]
  ]
  [report 0]
end

to-report in-bounds [x]
  ifelse (x > 0)
  [ifelse (x < 1)
    [report x]
    [report 1]
  ]
  [report 0]
end

to print_agents
  ask turtles
  [
    file-print (word who "," initial-identity "," item 0 care-f-m "," item 1 care-f-m "," item 0 work-f-m "," item 1 work-f-m "," gender-identity "," ticks ",")
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
995
10
1432
448
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
46
39
109
72
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
46
84
218
117
number-of-nodes
number-of-nodes
0
1000
500.0
1
1
NIL
HORIZONTAL

SLIDER
47
122
219
155
average-node-degree
average-node-degree
0
number-of-nodes - 1
13.0
1
1
NIL
HORIZONTAL

PLOT
520
10
720
160
histogram gender identiy
NIL
NIL
0.0
1.0
0.0
10.0
true
true
"set-histogram-num-bars 100" "set-histogram-num-bars 100"
PENS
"n" 0.01 1 -16777216 true "" "histogram [gender-identity] of turtles"

BUTTON
130
40
193
73
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
515
539
843
730
Social norm
NIL
NIL
0.0
55.0
0.0
1.0
true
true
"" ""
PENS
"gender identity" 1.0 0 -2674135 true "" "plot mean ([gender-identity] of turtles)"
"care f" 1.0 0 -16050907 true "" "plot mean([item 0 care-f-m] of turtles)"
"work f" 1.0 0 -10899396 true "" "plot mean([item 0 work-f-m] of turtles)"
"care m" 1.0 0 -1184463 true "" "plot mean([item 1 care-f-m] of turtles)"
"work m" 1.0 0 -5825686 true "" "plot mean ([item 1 work-f-m] of turtles)"

SWITCH
244
63
356
96
lockdown?
lockdown?
1
1
-1000

PLOT
747
171
971
318
care work
NIL
NIL
0.0
45.0
0.0
15.0
false
true
"set-histogram-num-bars 100" ""
PENS
"care f" 0.1 1 -16777216 true "" "histogram [item 0 care-f-m] of turtles"
"care m" 0.1 1 -1184463 true "" "histogram [item 1 care-f-m] of turtles"

SLIDER
11
185
183
218
a
a
0
0.5
0.3
0.01
1
NIL
HORIZONTAL

SLIDER
11
228
183
261
b
b
0
0.7
0.3
0.01
1
NIL
HORIZONTAL

SLIDER
11
269
183
302
c
c
0
0.5
0.3
0.01
1
NIL
HORIZONTAL

SLIDER
10
311
182
344
d
d
0
0.7
0.3
0.01
1
NIL
HORIZONTAL

TEXTBOX
189
194
339
212
adapt gender identity -> n
11
0.0
1

TEXTBOX
189
235
339
263
adapt gender identity -> care distribution\n
11
0.0
1

TEXTBOX
188
311
338
339
adapt care distribution -> gender identity\n
11
0.0
1

TEXTBOX
191
279
341
297
adapt care distribution -> n
11
0.0
1

SLIDER
365
62
509
95
number-of-systemic
number-of-systemic
0
100
15.0
1
1
%
HORIZONTAL

PLOT
746
13
971
163
work distribution
NIL
NIL
0.0
45.0
0.0
10.0
true
true
"set-histogram-num-bars 100" ""
PENS
"work-f" 0.1 1 -16777216 true "" "histogram [item 0 work-f-m] of turtles"
"work-m" 0.1 1 -1184463 true "" "histogram [item 1 work-f-m] of turtles"

PLOT
862
540
1267
728
mean gender identity
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"gender-identity" 1.0 0 -2674135 true "" "plot mean  [gender-identity] of turtles"
"work-division (only employed)" 1.0 0 -14439633 true "" "plot mean [item 1 work-f-m / sum work-f-m] of turtles with [sum work-f-m > 0]"
"care-division" 1.0 0 -14070903 true "" "plot mean [item 0 care-f-m / sum care-f-m] of turtles"

OUTPUT
1445
464
1698
579
11

CHOOSER
210
14
390
59
network-type
network-type
"random" "spatially clustered" "preferential attachment" "small world"
0

MONITOR
759
330
977
375
NIL
count turtles with [sum care-f-m = 0]
17
1
11

PLOT
1665
10
1865
160
average income per household
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"average income" 1.0 0 -16777216 true "" "plot mean [income] of turtles"

SLIDER
8
399
180
432
initial-identity
initial-identity
0
1
0.7
0.05
1
NIL
HORIZONTAL

PLOT
1447
10
1647
160
care total
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot sum [sum care-f-m] of turtles"

SLIDER
43
456
215
489
fix
fix
0
100
10.0
1
1
%
HORIZONTAL

SLIDER
40
502
212
535
lockdown-percent-f
lockdown-percent-f
0
1
0.8
0.1
1
NIL
HORIZONTAL

SLIDER
40
540
212
573
lockdown-percent-m
lockdown-percent-m
0
1
0.8
0.1
1
NIL
HORIZONTAL

SLIDER
345
207
517
240
hours
hours
0
100
63.0
0.5
1
NIL
HORIZONTAL

INPUTBOX
363
253
413
313
ld-start
100.0
1
0
Number

INPUTBOX
438
253
488
313
ld-end
125.0
1
0
Number

SLIDER
554
316
726
349
add-care
add-care
0
1030
20.0
0.1
1
NIL
HORIZONTAL

SLIDER
530
209
702
242
max-work
max-work
0
50
40.0
0.1
1
NIL
HORIZONTAL

SLIDER
530
166
702
199
seed
seed
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
550
272
722
305
mean-paygap
mean-paygap
0
1
0.83
0.01
1
NIL
HORIZONTAL

SWITCH
395
20
514
53
output-agents
output-agents
1
1
-1000

BUTTON
9
581
149
614
NIL
set-initial-values
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
223
583
361
628
initial-values
initial-values
"de" "us"
1

@#$#@#$#@
## WHAT IS IT?

social norm n is calculated as mean from care distribution of all turtles and the social norm of friends (link neighbors within confidence bounds). representing that we observe the care distribution of all housholds around us, zb fathers at playground with the children,... and also through media, more caring fathers in media 

work distribution is set to mean of work-history and actual care-distribution, when the difference of mean workhistory and mean care-history exceed a certain threshold

## WHAT IS NEW?

- random-seed
- alle parameter als variable im interface
- update-work-friends wenn ein befreundeter haushalt mehr verdient, wir die arbeitszeit von demjenigen erhöht, der mehr verdient (auch frauen können mehr arbeiten, wenn sie höheres einkommen haben)
- paygap als turtle variable wird aus verteilung mit mean mean-paygap gezogen

## HOW IT WORKS
(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
need-to-manually-make-preview-for-this-model
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment-a" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="900"/>
    <metric>mean [item 0 care-f-m] of turtles</metric>
    <metric>mean [item 1 care-f-m] of turtles</metric>
    <metric>mean [item 0 work-f-m] of turtles</metric>
    <metric>mean [item 1 work-f-m] of turtles</metric>
    <metric>mean [gender-identity] of turtles</metric>
    <steppedValueSet variable="seed" first="1" step="1" last="10"/>
    <enumeratedValueSet variable="probability-random-change">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-identity">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
      <value value="0.6"/>
      <value value="0.7"/>
      <value value="0.8"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nodes">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-systemic">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="history-length-work">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="average-node-degree">
      <value value="32"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a">
      <value value="0"/>
      <value value="0.01"/>
      <value value="0.02"/>
      <value value="0.03"/>
      <value value="0.04"/>
      <value value="0.05"/>
      <value value="0.06"/>
      <value value="0.07"/>
      <value value="0.08"/>
      <value value="0.09"/>
      <value value="0.1"/>
      <value value="0.11"/>
      <value value="0.12"/>
      <value value="0.13"/>
      <value value="0.14"/>
      <value value="0.15"/>
      <value value="0.16"/>
      <value value="0.17"/>
      <value value="0.18"/>
      <value value="0.19"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b">
      <value value="0.18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d">
      <value value="0.26"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fix">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="history-length-norm">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="history-length-care">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="th-work-change">
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-sysvsnon" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="900"/>
    <metric>mean [item 0 care-f-m] of turtles with [not systemic?]</metric>
    <metric>mean [item 1 care-f-m] of turtles with [not systemic?]</metric>
    <metric>mean [item 0 care-f-m] of turtles with [systemic?]</metric>
    <metric>mean [item 1 care-f-m] of turtles with [systemic?]</metric>
    <metric>mean [item 0 work-f-m] of turtles</metric>
    <metric>mean [item 1 work-f-m] of turtles</metric>
    <metric>mean [gender-identity] of turtles</metric>
    <enumeratedValueSet variable="ld-start">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-random-change">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-identity">
      <value value="0.5"/>
      <value value="0.6"/>
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-systemic">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
    </enumeratedValueSet>
    <steppedValueSet variable="seed" first="0" step="1" last="10"/>
    <enumeratedValueSet variable="history-length-work">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-work-m">
      <value value="5.8"/>
    </enumeratedValueSet>
    <steppedValueSet variable="a" first="0.1" step="0.1" last="0.3"/>
    <steppedValueSet variable="b" first="0.1" step="0.1" last="0.3"/>
    <enumeratedValueSet variable="c">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-m">
      <value value="5.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="history-length-norm">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-care-f">
      <value value="3.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown-percent-m">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nodes">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-work">
      <value value="5.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-work-f">
      <value value="4.43"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="average-node-degree">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-paygap">
      <value value="0.83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-f">
      <value value="4.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-end">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fix">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="add-care">
      <value value="2.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="history-length-care">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="th-work-change">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown-percent-f">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-care-m">
      <value value="2.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hours">
      <value value="8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="250"/>
    <metric>mean [item 0 care-f-m] of turtles</metric>
    <metric>mean [item 1 care-f-m] of turtles</metric>
    <metric>mean [item 0 work-f-m] of turtles</metric>
    <metric>mean [item 1 work-f-m] of turtles</metric>
    <metric>mean [gender-identity] of turtles</metric>
    <enumeratedValueSet variable="ld-start">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-random-change">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-identity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-systemic">
      <value value="15"/>
    </enumeratedValueSet>
    <steppedValueSet variable="seed" first="0" step="1" last="50"/>
    <enumeratedValueSet variable="history-length-work">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-work-m">
      <value value="30.42"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a">
      <value value="0.15"/>
      <value value="0.25"/>
      <value value="0.35"/>
      <value value="0.4"/>
      <value value="0.45"/>
      <value value="0.5"/>
      <value value="0.55"/>
      <value value="0.6"/>
      <value value="0.65"/>
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b">
      <value value="0.15"/>
      <value value="0.25"/>
      <value value="0.35"/>
      <value value="0.4"/>
      <value value="0.45"/>
      <value value="0.5"/>
      <value value="0.55"/>
      <value value="0.6"/>
      <value value="0.65"/>
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-m">
      <value value="3.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="history-length-norm">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-care-f">
      <value value="25.76"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown-percent-m">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nodes">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-work">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-work-f">
      <value value="20.37"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="average-node-degree">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-paygap">
      <value value="0.83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-f">
      <value value="3.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-end">
      <value value="125"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fix">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="add-care">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="history-length-care">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="th-work-change">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown-percent-f">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-care-m">
      <value value="16.24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hours">
      <value value="63"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-sysnon" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="250"/>
    <metric>mean [item 0 care-f-m] of turtles with [not systemic?]</metric>
    <metric>mean [item 1 care-f-m] of turtles with [not systemic?]</metric>
    <metric>mean [item 0 care-f-m] of turtles with [systemic?]</metric>
    <metric>mean [item 1 care-f-m] of turtles with [systemic?]</metric>
    <metric>mean [item 0 work-f-m] of turtles</metric>
    <metric>mean [item 1 work-f-m] of turtles</metric>
    <metric>mean [gender-identity] of turtles</metric>
    <enumeratedValueSet variable="ld-start">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-random-change">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-identity">
      <value value="0.5"/>
      <value value="0.6"/>
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-systemic">
      <value value="15"/>
    </enumeratedValueSet>
    <steppedValueSet variable="seed" first="0" step="1" last="50"/>
    <enumeratedValueSet variable="history-length-work">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-work-m">
      <value value="30.42"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-m">
      <value value="3.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="history-length-norm">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-care-f">
      <value value="25.76"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown-percent-m">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nodes">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-work">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-work-f">
      <value value="20.37"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="average-node-degree">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-paygap">
      <value value="0.83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-f">
      <value value="3.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-end">
      <value value="125"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fix">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="add-care">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="history-length-care">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="th-work-change">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown-percent-f">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-care-m">
      <value value="16.24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hours">
      <value value="63"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
