extensions [nw profiler csv]

breed [women woman]
breed [men man]

globals[
  num-links
  random-network-prob
  watts-strogatz-neighbors
  watts-strogatz-rewiring
  preferential-attachment-min-degree
  mean-work-f      ;mean time per day in paid work: female agents
  sd-work-f
  mean-work-m      ;mean time per day in paid work: male agents
  sd-work-m
  mean-care-f      ;mean care work time per day: female
  sd-care-f
  mean-care-m      ;mean care work time per day: male
  sd-care-m
  mean-care        ;mean household-care
  jobs
  employed-women
  employed-men

  ;;;;;;;; variables for parameter estimation and calibration
  measurers        ;agentset of agents to track
  file-name
  ticks-list       ; ticks where agents are tracked
  end-run
  measure-ticks
  estimated
  results
]



turtles-own[
  spouse               ; agent´s spouse
  gender-identity      ; describes in the opinion of this household the optimal division of care work   (0...man should do everything, 1..woman should do everything)
  care                 ; hours spent with care work
  work                 ; hours spent with paid work
  work-pre             ; stores hours work before lockdown
  unemployed?          ; is the agent unemployed?
  stw?                 ; is this person in short time work?
  work-div             ; share of  paid work hours done by man (1...man single earner, 0 ... woman single earner)
  care-div             ; share of care work done by woman (1...woman does all the care work, 0...man does all the care work)
  household-care       ; overall care demand in this household
  lockdown-household-care ; household care demand during a lockdown
  hh-income            ; household-income
  hh-work              ; total paid work hours of the household
  n-care               ; perceived norm in terms of care division
  n-work               ; perceived norm in terms of paid work division
  lockdown-hours       ; sum of hours care work and paid work during lockdown
  income               ; income of the agent
  friends              ; agent´s social group
  friend-hh-income     ; household income of one agent in the social group, with wich agent compares her own income
  diff-work            ; difference between agent´s work before and during lockdown
  new-work
  new-care
  new-gender-identity
]


to setup
  clear-all
  if use-random-seed? [random-seed seed]

  set-initial-values
  set lockdown? false
  set-default-shape turtles "circle"


  ;link women with other women, men with other men
  if network-structure = "random"
  [
    nw:generate-random men links number-of-households random-network-prob
    nw:generate-random women links number-of-households random-network-prob
  ]
  if network-structure = "small world"
  [
    nw:generate-watts-strogatz men links number-of-households watts-strogatz-neighbors watts-strogatz-rewiring
    nw:generate-watts-strogatz women links number-of-households watts-strogatz-neighbors watts-strogatz-rewiring
  ]
  if network-structure = "preferential attachment"
  [
    nw:generate-preferential-attachment men links number-of-households preferential-attachment-min-degree
    nw:generate-preferential-attachment women links number-of-households preferential-attachment-min-degree
  ]
  if network-structure = "no"
  [
    create-women number-of-households
    create-men number-of-households
  ]

  ;layout-circle men 15
  ;layout-circle women 15

  if (hours < max-work) [set max-work hours]

  ;link spouses
  ask women
  [
    setup-women
    set spouse one-of men with [spouse = 0]
    ask spouse
    [
      set spouse myself
      setup-men
    ]
  ]
  ; set household properties
  ask turtles [
    set hh-work work + [work] of spouse
    set hh-income (income * work) + [income * work] of spouse
    set household-care care + [care] of spouse
    if (breed = women)[
      set lockdown-household-care household-care + random-normal add-care sd-add
      ask spouse [set lockdown-household-care [lockdown-household-care] of myself]
    ]
    set care-div ifelse-value (care + [care] of spouse > 0) [care / (care + [care] of spouse)][gender-identity]
    set work-div ifelse-value (hh-work = 0)[1 - gender-identity][work / hh-work]
    set lockdown-hours hours
  ]

  set jobs 0

  if equal-conv-param? [
    set b a
    set c a
  ]

  reset-ticks

  if output-agents = true
  [ set measurers n-of number-of-hh-to-measure women
    file-close-all
    set file-name ( word "agents_work_a02.csv")
    if (file-exists? file-name) [file-delete file-name]
    file-open file-name
    file-print "agent-id, breed, a, care, [care] of spouse , work, [work] of spouse, income , [income] of spouse , identity, unemployed , [unemployed] of spouse, run , ticks, hhcare, ldcare, friend-hh-income "
    print_agents
  ]
end

to setup-women
  set shape "triangle"
  set xcor xcor - 15

  set income max list 0 (random-normal mean-rel-income sd_income)

  ;work
  set work in-work(random-normal mean-work-f sd-work)
  set unemployed? false
  set stw? false

  ;care
  set care random-normal mean-care-f sd-care
  set care in-hours care work

  ;gender identity
  set gender-identity in-bounds( random-normal mean-id sd-id)

  set friends ifelse-value (network-structure = "no") [other women][link-neighbors]
end

to setup-men
  set shape "square"
  set xcor xcor + 15

  set income max list 0 (random-normal 1 sd_income)

  ;work
  set work in-work(random-normal mean-work-m sd-work)
  set unemployed? false
  set stw? false

  ;care
  set care random-normal mean-care-m sd-care
  set care in-hours care work

  ;gender identity
  set gender-identity in-bounds(random-normal ( 1 - mean-id ) sd-id)

  set friends ifelse-value (network-structure = "no") [other men][link-neighbors]
end


to set-initial-values
  set random-network-prob 0.012 ;0.012
  set watts-strogatz-neighbors 6
  set watts-strogatz-rewiring 0.1
  set preferential-attachment-min-degree 6

  (ifelse initial-values = "de" [
    set mean-care-f 3.8
    set mean-care-m 2.4
    set mean-work-f 4.43
    set mean-work-m 5.58
    set unemployed-f 0
    set unemployed-m 0
    ]
    initial-values = "us" [
     set mean-care-m 1.21
     set mean-care-f 2.4
     set mean-work-f 7.8
     set mean-work-m 8.65
    ]
    initial-values = "aut" [
    set mean-care-f 6.1
    set mean-care-m 2.2
    set mean-work-f 3.4
    set mean-work-m 7.5

    ]
    initial-values = "equal" [
    set mean-care-f 3
    set mean-care-m 3
    set mean-work-f 5
    set mean-work-m 5

    ]
     initial-values = "unequal" [
    set mean-care-f 10
    set mean-care-m 0
    set mean-work-f 0
    set mean-work-m 10
    ]
     initial-values = "sensitivity" [
     set mean-care-f total-initial-care * initial-div
     set mean-care-m total-initial-care * (1 - initial-div)
     set mean-work-f total-initial-work * (1 - initial-div)
     set mean-work-m total-initial-work * initial-div
      if (add-care = 0)[set sd-add 0]
    ]
  )
end


to go
  if (stop-condition =  "file" and member? ticks ticks-list)[
    set results lput (list ticks a b c th-work-change perc-stw-f perc-stw-m unemployed-f unemployed-m (mean [care] of men) (mean [care] of women) (mean [work] of men) (mean [work] of women)) results
    if (ticks = end-run) [
      ;    ;csv:to-file "results.csv" results
      ;    file-open file_results
      ;    foreach (results) [
      ;      [line] -> file-print csv:to-row line
      ;    ]
      file-close
      stop
    ]
  ]

  ; lockdown start and end
  if (ticks >= ld-start and ticks <= ld-end)
   [set lockdown? true ]
  if (ticks = ld-start)
   [start-lockdown]
  if (ticks = ld-end)
   [set lockdown? false
    end-lockdown
   ]

  ask turtles
  [
    update-care
    update-identity
    if(unemployed? = false)[
      update-work
      update-work-friends
    ]
    update-variables
  ]

  if output-agents = true
  [
    print_agents
  ]
  tick
end

to start-lockdown
  ask turtles [set work-pre work]
  ask women [
    if (random-float 100 < unemployed-f and not unemployed?)[
      set diff-work work
      set work 0
      set unemployed? true
    ]
  ]
  ask men [
    if (random-float 100 < unemployed-m and not unemployed?)[
    set diff-work work
    set work 0
    set unemployed? true
    ]
  ]
  ask women [
    if (random-float 100 < perc-stw-f and not unemployed?)[
     let work-new max list 0 (work - random-float hours) ;random-float work ;??????
     set diff-work work
     set work 0 ;max list 0 work-new
     set stw? true
    ]
  ]
  ask men [
    if (random-float 100 < perc-stw-m and not unemployed?)[
     let work-new max list 0 (work - random-float hours)
     set diff-work work
     set work 0 ;max list 0 work-new
     set stw? true
    ]
  ]
  ask turtles [ set hh-work work + [work] of spouse
   set work-div ifelse-value (hh-work = 0)[1 - gender-identity][work / hh-work]]
end

to end-lockdown
  ask turtles with [unemployed?][
    set jobs jobs + diff-work
    set unemployed? false
  ]
  ask turtles with [stw?][
    set jobs jobs + diff-work
    set work available-jobs work-pre work
    set stw? false
  ]
end

to update-variables
  set care in-hours new-care work
  set gender-identity in-bounds(new-gender-identity)
  set care-div ifelse-value (care + [care] of spouse > 0) [care / (care + [care] of spouse)][gender-identity]
end

to update-work
   set new-work work
   set hh-work work + [work] of spouse
   set work-div ifelse-value (hh-work = 0)[1 - gender-identity][work / hh-work]
   set hh-income (income * work) + ([income * work] of spouse)
   let ideal-work hh-work * ( 1 - gender-identity )
   ifelse (count friends > 0)
       [ set n-work mean [work] of friends ]
       [ set n-work work ]
  let work-pot ifelse-value (lockdown?) [ hours - (lockdown-household-care - [care] of spouse )][ hours - ( household-care - [care] of spouse)]
   set new-work in-work(new-work - a * (new-work - n-work) - b * (new-work - ideal-work) - c * (new-work - work-pot))
   set work available-jobs in-work(new-work) work
  set hh-work work + [work] of spouse
  set work-div ifelse-value (hh-work > 0) [work / (work + [work] of spouse)][1 - gender-identity]
end


to update-work-friends
  ;;; if someone from social group has higher income, agents try to increase their hosuehold income
  set hh-income (income * work) + ([income * work] of spouse)
  set hh-work work + [work] of spouse
  if(count friends > 0)[
    let friend one-of friends
    set friend-hh-income [hh-income] of friend
    if (friend-hh-income > th-work-change * hh-income)[
      let pot-div [work-div] of friend
      let pot-work in-work (hh-work * pot-div)
      let pot-work-spouse ifelse-value ([unemployed?] of spouse) [0][in-work (hh-work - pot-work)]
      let pot-hh-income (pot-work * income) + (pot-work-spouse * [income] of spouse)
      if (pot-hh-income > hh-income)[
        set work available-jobs pot-work work
        ask spouse [set work available-jobs [pot-work-spouse] of myself work]
      ]
    ]
  ]
end


to-report available-jobs [pot current-work]
  let diff current-work - pot
      ifelse(diff >= 0)
      [ ; agent reduces hours in paid work --> available jobs increase
        set jobs jobs + diff
        report pot
      ]
      [ ; agent tries to increase hours in paid work --> check if available jobs
        ifelse (jobs > (- diff))
        [ ;; es gibt genug jobs
          set jobs jobs + diff
          report pot
        ]
        [let remaining jobs
         set jobs 0
         report current-work + remaining
         ]
      ]
end


to update-care
  ; calculate shares of care work by man and woman
  set care-div ifelse-value (care + [care] of spouse > 0) [care / (care + [care] of spouse)][gender-identity]
  ; care division according to gender identity
  let ideal ifelse-value (lockdown?) [lockdown-household-care * gender-identity][household-care * gender-identity]
  ; perceived norm of care division
  set n-care ideal
  if count friends > 0 [
    set n-care ifelse-value (lockdown?) [(mean [care-div] of friends) * lockdown-household-care][(mean [care-div] of friends) * household-care]
  ]
  let care-pot care
  ifelse (hh-work = 0)
    [set care-pot hours]
    [set care-pot household-care * (1 - work-div)]
  set new-care (care - a * (care - n-care) - b * (care - ideal) - c * (care - care-pot))
end


to update-identity
   set care-div ifelse-value (care + [care] of spouse > 0) [care / (care + [care] of spouse)][gender-identity]
   let cogn-diss (gender-identity - care-div)
   let n 0.5
   ifelse (count friends > 0)
      [ set n (mean [care-div] of friends) ]
      [ set n gender-identity ]
   set new-gender-identity in-bounds( gender-identity - a * (gender-identity - n) - b * cogn-diss)
end


to update-colors
  set color scale-color red gender-identity 0 1
end

to-report in-hours [x w]
  ifelse(not lockdown?)[
   ifelse (x > 0)
     [ifelse (x + w < hours)
       [report x]
       [report (hours - w)]
    ]
    [report 0]
  ]
  [
  ifelse (x > 0)
     [ifelse (x + w < lockdown-hours)
       [report x]
       [report lockdown-hours - w]
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
  [ report 0]
end

to-report in-bounds [x]
  ifelse (x > 0)
  [ifelse (x < 1)
    [report x]
    [report 1]
  ]
  [report 0]
end

to read-ticks-to-measure
  ;file-close-all ; Close any files open from last run
  set measure-ticks csv:from-file "measure_ticks.csv"
  set ticks-list []
  foreach butfirst(measure-ticks) [
    [line] ->
    run (word "set ticks-list lput " item 0 line " ticks-list")
  ]
  set end-run ( max ticks-list + 1)
end

to print_agents
  ask measurers
  [
    file-print  (word who "," breed "," a "," care "," [care] of spouse "," work "," [work] of spouse "," income "," [income] of spouse "," gender-identity "," unemployed? "," [unemployed?] of spouse "," behaviorspace-run-number "," ticks "," household-care "," lockdown-household-care "," friend-hh-income)
  ]
end

to set-estimated-parameter
  set estimated csv:from-file "fit_semiauto_abc.csv"
  ;loop over list with index i set parameters and interval per line!
  foreach butfirst(estimated) [
    [line] ->
    run (word "set " item 1 line " " item 2 line)
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
1252
34
1772
303
-1
-1
8.4
1
10
1
1
1
0
0
0
1
-30
30
-15
15
0
0
1
ticks
30.0

BUTTON
574
294
637
327
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
11
174
192
207
number-of-households
number-of-households
1
1000
1000.0
1
1
NIL
HORIZONTAL

PLOT
782
14
982
164
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
"n-care" 0.01 1 -16777216 true "" "histogram [gender-identity] of women"

BUTTON
658
294
721
327
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
707
352
1086
543
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
"care f" 1.0 0 -16050907 true "" "plot mean([care] of women)"
"work f" 1.0 0 -10899396 true "" "plot mean([work] of women)"
"care m" 1.0 0 -1184463 true "" "plot mean([care] of men)"
"work m" 1.0 0 -5825686 true "" "plot mean ([work] of men)"

SWITCH
635
155
747
188
lockdown?
lockdown?
1
1
-1000

PLOT
997
180
1223
329
care work
NIL
NIL
0.0
16.0
0.0
15.0
true
true
"set-histogram-num-bars 100" ""
PENS
"care f" 1.0 1 -16777216 true "" "histogram [care] of women"
"care m" 0.1 1 -1184463 true "" "histogram [care] of men"

SLIDER
13
276
185
309
a
a
0
1
0.2
0.01
1
NIL
HORIZONTAL

SLIDER
12
326
184
359
b
b
0
1
0.2
0.01
1
NIL
HORIZONTAL

TEXTBOX
16
309
166
327
social influence
11
0.0
1

TEXTBOX
15
359
165
387
cognitive dissonance\n\n
11
0.0
1

PLOT
996
13
1221
163
work distribution
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"set-histogram-num-bars 100" ""
PENS
"work-f" 1.0 1 -16777216 true "" "histogram [work] of women"
"work-m" 0.1 1 -1184463 true "" "histogram [work] of men"

PLOT
1103
353
1508
541
mean gender identity
NIL
NIL
0.0
10.0
0.6
0.7
true
true
"" ""
PENS
"gender-identity-f" 1.0 0 -2674135 true "" "plot mean  [gender-identity] of women\n"
"work-division" 1.0 0 -14439633 true "" "plot mean [work] of men / (mean [work] of men + mean [work] of women)\n"
"care-div-f" 1.0 0 -13345367 true "" "plot mean [ care] of women / (mean [care] of women + mean [care] of men) "

OUTPUT
1522
361
2033
535
11

CHOOSER
11
218
191
263
network-structure
network-structure
"random" "preferential attachment" "small world" "no"
0

INPUTBOX
637
193
687
253
ld-start
500.0
1
0
Number

INPUTBOX
696
194
746
254
ld-end
500.0
1
0
Number

SLIDER
576
20
748
53
seed
seed
0
10000
4841.0
1
1
NIL
HORIZONTAL

SLIDER
205
425
377
458
mean-rel-income
mean-rel-income
0
2
0.816
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
51
162
84
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
169
48
307
93
initial-values
initial-values
"de" "us" "aut" "equal" "unequal" "sensitivity"
5

PLOT
782
178
982
328
intra-household paygap
NIL
NIL
-0.5
1.5
0.0
10.0
true
false
"" ""
PENS
"default" 0.1 1 -16777216 true "" "histogram [income] of women"

SWITCH
392
65
541
98
equal-conv-param?
equal-conv-param?
1
1
-1000

INPUTBOX
389
301
455
361
sd_income
0.2
1
0
Number

TEXTBOX
207
460
377
488
income of women / income of men\n
11
0.0
1

SLIDER
208
124
380
157
max-work
max-work
0
10
8.0
0.1
1
NIL
HORIZONTAL

SLIDER
208
174
380
207
hours
hours
0
112
16.0
1
1
NIL
HORIZONTAL

INPUTBOX
389
229
453
291
sd-care
2.0
1
0
Number

INPUTBOX
467
231
529
291
sd-work
2.0
1
0
Number

SLIDER
482
463
654
496
add-care
add-care
-10
12
2.5
0.5
1
NIL
HORIZONTAL

TEXTBOX
483
498
700
526
mean additional care per household per day
11
0.0
1

SLIDER
482
595
654
628
perc-stw-m
perc-stw-m
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
482
635
654
668
perc-stw-f
perc-stw-f
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
481
517
653
550
unemployed-f
unemployed-f
0
100
6.5
1
1
NIL
HORIZONTAL

SLIDER
482
557
654
590
unemployed-m
unemployed-m
0
100
6.0
1
1
NIL
HORIZONTAL

SLIDER
205
486
377
519
th-work-change
th-work-change
0
2
1.2
0.01
1
NIL
HORIZONTAL

SLIDER
12
378
183
411
c
c
0
1
0.2
0.01
1
NIL
HORIZONTAL

TEXTBOX
13
411
163
429
work-care balance\n
11
0.0
1

BUTTON
9
12
163
45
NIL
read-ticks-to-measure
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
586
61
744
94
use-random-seed?
use-random-seed?
1
1
-1000

BUTTON
8
89
162
122
NIL
set-estimated-parameter\n
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
393
106
485
151
stop-condition
stop-condition
"file" "user-limit"
1

INPUTBOX
499
106
571
166
time-limit
600.0
1
0
Number

INPUTBOX
471
304
525
364
sd-add
0.0
1
0
Number

SLIDER
203
374
375
407
mean-id
mean-id
0
1
0.6
0.1
1
NIL
HORIZONTAL

INPUTBOX
392
376
442
436
sd-id
0.1
1
0
Number

SLIDER
204
324
376
357
initial-div
initial-div
0
1
0.715
0.1
1
NIL
HORIZONTAL

SLIDER
205
227
344
260
total-initial-care
total-initial-care
0
32
8.3
1
1
NIL
HORIZONTAL

SLIDER
205
277
346
310
total-initial-work
total-initial-work
0
20
10.1
1
1
NIL
HORIZONTAL

SLIDER
169
10
344
43
number-of-hh-to-measure
number-of-hh-to-measure
0
1000
520.0
1
1
NIL
HORIZONTAL

TEXTBOX
206
261
356
279
mean household care demand
11
0.0
1

TEXTBOX
207
310
357
328
mean initial household work\n
11
0.0
1

TEXTBOX
206
358
356
376
initial division of labor\n
11
0.0
1

TEXTBOX
205
409
355
427
mean initial gender identiy\n
11
0.0
1

TEXTBOX
491
440
641
458
Lockdown Parameter
14
0.0
1

TEXTBOX
212
209
362
227
max. hours total\n
11
0.0
1

TEXTBOX
210
159
360
177
max. hours paid work\n
11
0.0
1

@#$#@#$#@
## WHAT IS IT?
This agent-based model simulates how household care and paid work are divided between men and women, particularly under changing social and economic conditions such as a lockdown. The model represents households as male-female pairs who allocate their time based on internal preferences, social norms, and labor market constraints. The goal is to explore the dynamics of gendered work and care patterns and how these evolve due to peer influence, personal attitudes, and external shocks.

## HOW IT WORKS
Each agent (man or woman) is initialized with characteristics like income, gender identity (reflecting beliefs about care division), and time allocated to paid and unpaid work. Households are formed by pairing men and women. Agents are embedded in social networks (random, small-world, preferential attachment, or none) and adjust their behaviors based on:

   - Their own and their spouse's gender identity and constraints.

   - Social norms derived from their peer networks.

   - Labor market availability and household care needs. During a simulated lockdown, some agents lose their jobs or go into short-time work, affecting household income and prompting adjustments in work and care duties.

## HOW TO USE IT

1. Choose initial values (e.g., "de", "us", "aut", "equal", "unequal", or "sensitivity") for gendered work and care norms. Or set initial values manually with the sliders.

2. Set the network structure: "random", "small world", "preferential attachment", or "no" (no social network).

3. Configure sliders and parameters such as:

    - a, b, c: influence weights for peer norms, ideal division, and available time.

    - perc-stw-f, perc-stw-m: percentage of women/men in short-time work during lockdown.

    - unemployed-f, unemployed-m: unemployment rates by gender.

    - hours, max-work, add-care: total daily hours available, maximum paid work, and extra care during lockdown.

4. Click Setup to initialize the simulation.

5. Click Go to run the model.

## THINGS TO NOTICE

How do care and work responsibilities shift during and after a lockdown?

Observe how agents’ gender identities evolve over time due to cognitive dissonance and peer influence.

Watch how the presence or absence of a social network influences convergence toward shared norms.

Track how short-time work or unemployment disrupts previous household divisions of labor.

## THINGS TO TRY

- Compare outcomes across different initial-values (e.g., "equal" vs. "unequal").

- Modify network-structure to see how social connectivity affects behavioral change.

- Increase add-care to simulate a more demanding lockdown scenario.

- Set a, b, or c to zero to isolate the influence of norms, ideals, or constraints

## EXTENDING THE MODEL

- add children explicitly to the households
- implement more detailed labor market dynamics

## CREDITS AND REFERENCES

This model is part of a research project examining gender roles, labor division, and the social dynamics of care.
For more information or to cite this model, please refer to: magdalena.rath@uni-graz.at

Credits to Magdalena Rath for development.

Inspired by related literature on gender norms, agent-based modeling, and crisis-induced labor change.
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
NetLogo 6.4.0
@#$#@#$#@
need-to-manually-make-preview-for-this-model
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment-a" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>mean [care] of women</metric>
    <metric>mean [care] of men</metric>
    <metric>mean [work] of women</metric>
    <metric>mean [work] of men</metric>
    <metric>mean [gender-identity] of women</metric>
    <enumeratedValueSet variable="total-initial-care">
      <value value="8.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-initial-work">
      <value value="10.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-div">
      <value value="0.715"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-id">
      <value value="0.715"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-start">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-add">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-values">
      <value value="&quot;sensitivity&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="a" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="sd_income">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-care">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="equal-conv-param?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-condition">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-work">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-work">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-random-seed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="output-agents">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-historical-norm">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-end">
      <value value="380"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-structure">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-households">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-rel-income">
      <value value="0.816"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="add-care">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="th-work-change">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-limit">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hours">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-hist-norm">
      <value value="0.2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-convergence" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>mean [care] of women</metric>
    <metric>mean [care] of men</metric>
    <metric>mean [work] of women</metric>
    <metric>mean [work] of men</metric>
    <metric>mean [gender-identity] of women</metric>
    <enumeratedValueSet variable="total-initial-care">
      <value value="8.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-initial-work">
      <value value="10.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-div">
      <value value="0.715"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-id">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-start">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-add">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-values">
      <value value="&quot;sensitivity&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="a" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="sd_income">
      <value value="0.2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="b" first="0" step="0.1" last="1"/>
    <steppedValueSet variable="c" first="0" step="0.05" last="1"/>
    <enumeratedValueSet variable="unemployed-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-care">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="equal-conv-param?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-condition">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-work">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-work">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-random-seed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="output-agents">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-historical-norm">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-end">
      <value value="380"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-structure">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-households">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-rel-income">
      <value value="0.816"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="add-care">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="th-work-change">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-limit">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hours">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-hist-norm">
      <value value="0.2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-b" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>mean [care] of women</metric>
    <metric>mean [care] of men</metric>
    <metric>mean [work] of women</metric>
    <metric>mean [work] of men</metric>
    <metric>mean [gender-identity] of women</metric>
    <enumeratedValueSet variable="total-initial-care">
      <value value="8.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-initial-work">
      <value value="10.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-div">
      <value value="0.715"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-id">
      <value value="0.715"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-start">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-add">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-values">
      <value value="&quot;sensitivity&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd_income">
      <value value="0.2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="b" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="c">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-care">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="equal-conv-param?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-condition">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-work">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-work">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-random-seed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="output-agents">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-historical-norm">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-end">
      <value value="380"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-structure">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-households">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-rel-income">
      <value value="0.816"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="add-care">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="th-work-change">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-limit">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hours">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-hist-norm">
      <value value="0.2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-c" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>mean [care] of women</metric>
    <metric>mean [care] of men</metric>
    <metric>mean [work] of women</metric>
    <metric>mean [work] of men</metric>
    <metric>mean [gender-identity] of women</metric>
    <enumeratedValueSet variable="total-initial-care">
      <value value="8.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-initial-work">
      <value value="10.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-div">
      <value value="0.715"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-id">
      <value value="0.715"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-start">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-add">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-values">
      <value value="&quot;sensitivity&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd_income">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-care">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="equal-conv-param?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-condition">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-work">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-work">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-random-seed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="output-agents">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-historical-norm">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-end">
      <value value="380"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-structure">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-households">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-rel-income">
      <value value="0.816"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="add-care">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="th-work-change">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-limit">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hours">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-hist-norm">
      <value value="0.2"/>
    </enumeratedValueSet>
    <subExperiment>
      <steppedValueSet variable="c" first="0.1" step="0.1" last="1"/>
    </subExperiment>
    <subExperiment>
      <steppedValueSet variable="c" first="0" step="0.02" last="0.1"/>
    </subExperiment>
  </experiment>
  <experiment name="experiment-th" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>mean [care] of women</metric>
    <metric>mean [care] of men</metric>
    <metric>mean [work] of women</metric>
    <metric>mean [work] of men</metric>
    <metric>mean [gender-identity] of women</metric>
    <enumeratedValueSet variable="total-initial-care">
      <value value="8.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-initial-work">
      <value value="10.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-div">
      <value value="0.715"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-id">
      <value value="0.715"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-start">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-add">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-values">
      <value value="&quot;sensitivity&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd_income">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-care">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="equal-conv-param?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-condition">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-work">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-work">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-random-seed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="output-agents">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-historical-norm">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-end">
      <value value="380"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-structure">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-households">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-rel-income">
      <value value="0.816"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="add-care">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="th-work-change" first="0.5" step="0.1" last="2"/>
    <enumeratedValueSet variable="time-limit">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hours">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-hist-norm">
      <value value="0.2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-maxwork" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>mean [care] of women</metric>
    <metric>mean [care] of men</metric>
    <metric>mean [work] of women</metric>
    <metric>mean [work] of men</metric>
    <metric>mean [gender-identity] of women</metric>
    <enumeratedValueSet variable="total-initial-care">
      <value value="8.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-initial-work">
      <value value="10.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-div">
      <value value="0.715"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-id">
      <value value="0.715"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-start">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-add">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-values">
      <value value="&quot;sensitivity&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd_income">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-care">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="equal-conv-param?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-condition">
      <value value="300"/>
    </enumeratedValueSet>
    <steppedValueSet variable="max-work" first="5" step="1" last="15"/>
    <enumeratedValueSet variable="perc-stw-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-work">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-random-seed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="output-agents">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-historical-norm">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-end">
      <value value="380"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-structure">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-households">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-rel-income">
      <value value="0.816"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="add-care">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="th-work-change">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-limit">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hours">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-hist-norm">
      <value value="0.2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-id" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>mean [care] of women</metric>
    <metric>mean [care] of men</metric>
    <metric>mean [work] of women</metric>
    <metric>mean [work] of men</metric>
    <metric>mean [gender-identity] of women</metric>
    <metric>mean [gender-identity] of men</metric>
    <enumeratedValueSet variable="total-initial-care">
      <value value="8.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-initial-work">
      <value value="10.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-div">
      <value value="0.715"/>
    </enumeratedValueSet>
    <steppedValueSet variable="mean-id" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="ld-start">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-add">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-values">
      <value value="&quot;sensitivity&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd_income">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-care">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="equal-conv-param?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-condition">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-work">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-work">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-random-seed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="output-agents">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-historical-norm">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-end">
      <value value="380"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-structure">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-households">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-rel-income">
      <value value="0.816"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="add-care">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="th-work-change">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-limit">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hours">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-hist-norm">
      <value value="0.2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-income" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>mean [care] of women</metric>
    <metric>mean [care] of men</metric>
    <metric>mean [work] of women</metric>
    <metric>mean [work] of men</metric>
    <metric>mean [gender-identity] of women</metric>
    <enumeratedValueSet variable="total-initial-care">
      <value value="8.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-initial-work">
      <value value="10.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-div">
      <value value="0.715"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-id">
      <value value="0.715"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-start">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-add">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-values">
      <value value="&quot;sensitivity&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd_income">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-care">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="equal-conv-param?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-condition">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-work">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-work">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-random-seed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="output-agents">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-historical-norm">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-end">
      <value value="380"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-structure">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-households">
      <value value="1000"/>
    </enumeratedValueSet>
    <steppedValueSet variable="mean-rel-income" first="0" step="0.2" last="2"/>
    <enumeratedValueSet variable="add-care">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="th-work-change">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-limit">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hours">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-hist-norm">
      <value value="0.2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="scenario_work" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="400"/>
    <metric>mean [care] of women</metric>
    <metric>mean [care] of men</metric>
    <metric>mean [work] of women</metric>
    <metric>mean [work] of men</metric>
    <metric>mean [gender-identity] of women</metric>
    <enumeratedValueSet variable="total-initial-care">
      <value value="8.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-initial-work">
      <value value="10.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-div">
      <value value="0.715"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-start">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-add">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-values">
      <value value="&quot;sensitivity&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a">
      <value value="0"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd_income">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-m">
      <value value="0"/>
      <value value="3"/>
      <value value="6"/>
      <value value="10"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-care">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-id">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="equal-conv-param?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-condition">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-work">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-work">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-id">
      <value value="0.715"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-random-seed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="output-agents">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-f">
      <value value="0"/>
      <value value="3"/>
      <value value="6.5"/>
      <value value="10"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-end">
      <value value="280"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-historical-norm">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-structure">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-households">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-rel-income">
      <value value="0.816"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="add-care">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="th-work-change">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-limit">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hours">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-hist-norm">
      <value value="0.2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="scenario_addcare" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="400"/>
    <metric>mean [care] of women</metric>
    <metric>mean [care] of men</metric>
    <metric>mean [work] of women</metric>
    <metric>mean [work] of men</metric>
    <metric>mean [gender-identity] of women</metric>
    <enumeratedValueSet variable="total-initial-care">
      <value value="8.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-initial-work">
      <value value="10.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-div">
      <value value="0.715"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-start">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-add">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-values">
      <value value="&quot;sensitivity&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a">
      <value value="0"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd_income">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-care">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-id">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="equal-conv-param?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-condition">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-work">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-work">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-id">
      <value value="0.715"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-random-seed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="output-agents">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-end">
      <value value="280"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-historical-norm">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-structure">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-households">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-rel-income">
      <value value="0.816"/>
    </enumeratedValueSet>
    <steppedValueSet variable="add-care" first="0" step="1" last="10"/>
    <enumeratedValueSet variable="th-work-change">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-limit">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hours">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-hist-norm">
      <value value="0.2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-initial-div" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>mean [care] of women</metric>
    <metric>mean [care] of men</metric>
    <metric>mean [work] of women</metric>
    <metric>mean [work] of men</metric>
    <metric>mean [gender-identity] of women</metric>
    <enumeratedValueSet variable="total-initial-care">
      <value value="8.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-initial-work">
      <value value="10.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-id">
      <value value="0.715"/>
    </enumeratedValueSet>
    <steppedValueSet variable="initial-div" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="ld-start">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-add">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-values">
      <value value="&quot;sensitivity&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd_income">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-care">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="equal-conv-param?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-condition">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-work">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-work">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-random-seed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="output-agents">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-historical-norm">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-end">
      <value value="380"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-structure">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-households">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-rel-income">
      <value value="0.816"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="add-care">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="th-work-change">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-limit">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hours">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-hist-norm">
      <value value="0.2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="single" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="310"/>
    <enumeratedValueSet variable="initial-div">
      <value value="0.715"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-start">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-add">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-values">
      <value value="&quot;sensitivity&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a">
      <value value="0"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd_income">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-care">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-id">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="equal-conv-param?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-condition">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-work">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-work">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-id">
      <value value="0.715"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-random-seed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="output-agents">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-end">
      <value value="280"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-historical-norm">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-structure">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-households">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-rel-income">
      <value value="0.816"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="add-care">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="th-work-change">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-limit">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hours">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-hist-norm">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-hh-to-measure">
      <value value="1000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="scenario_combination" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="400"/>
    <metric>mean [care] of women</metric>
    <metric>mean [care] of men</metric>
    <metric>mean [work] of women</metric>
    <metric>mean [work] of men</metric>
    <metric>mean [gender-identity] of women</metric>
    <enumeratedValueSet variable="total-initial-care">
      <value value="8.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-initial-work">
      <value value="10.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-div">
      <value value="0.715"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-start">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-add">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-values">
      <value value="&quot;sensitivity&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a">
      <value value="0"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd_income">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-m">
      <value value="0"/>
      <value value="3"/>
      <value value="6"/>
      <value value="10"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-care">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-id">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="equal-conv-param?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-condition">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-work">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-work">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-id">
      <value value="0.715"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-random-seed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="output-agents">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-f">
      <value value="0"/>
      <value value="3"/>
      <value value="6.5"/>
      <value value="10"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-end">
      <value value="280"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-historical-norm">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-structure">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-households">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-rel-income">
      <value value="0.816"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="add-care">
      <value value="7.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="th-work-change">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-limit">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hours">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-hist-norm">
      <value value="0.2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="scenario_combination_compare" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>mean [care] of women</metric>
    <metric>mean [care] of men</metric>
    <metric>mean [work] of women</metric>
    <metric>mean [work] of men</metric>
    <metric>mean [gender-identity] of women</metric>
    <metric>mean [friend-hh-income] of women</metric>
    <metric>mean [friend-hh-income] of men</metric>
    <enumeratedValueSet variable="total-initial-care">
      <value value="8.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-initial-work">
      <value value="10.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-div">
      <value value="0.715"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-start">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-add">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-values">
      <value value="&quot;sensitivity&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd_income">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-m">
      <value value="0"/>
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-care">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-id">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="equal-conv-param?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-condition">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-work">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-work">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-id">
      <value value="0.715"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-random-seed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="output-agents">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-f">
      <value value="0"/>
      <value value="6.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-end">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-historical-norm">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-structure">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-households">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-rel-income">
      <value value="0.816"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="add-care">
      <value value="0"/>
      <value value="7.27"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="th-work-change">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-limit">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hours">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-hist-norm">
      <value value="0.2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="scenario_work_equal" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="400"/>
    <metric>mean [care] of women</metric>
    <metric>mean [care] of men</metric>
    <metric>mean [work] of women</metric>
    <metric>mean [work] of men</metric>
    <metric>mean [gender-identity] of women</metric>
    <enumeratedValueSet variable="total-initial-care">
      <value value="8.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-initial-work">
      <value value="10.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-div">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-start">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-add">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-values">
      <value value="&quot;sensitivity&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a">
      <value value="0"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd_income">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-m">
      <value value="0"/>
      <value value="3"/>
      <value value="6"/>
      <value value="10"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-care">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-id">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="equal-conv-param?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-condition">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-work">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-work">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-id">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-random-seed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="output-agents">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-f">
      <value value="0"/>
      <value value="3"/>
      <value value="6.5"/>
      <value value="10"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-end">
      <value value="280"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-historical-norm">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-structure">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-households">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-rel-income">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="add-care">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="th-work-change">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-limit">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hours">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-hist-norm">
      <value value="0.2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="scenario_addcare_equal" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mean [care] of women</metric>
    <metric>mean [care] of men</metric>
    <metric>mean [work] of women</metric>
    <metric>mean [work] of men</metric>
    <metric>mean [gender-identity] of women</metric>
    <enumeratedValueSet variable="total-initial-care">
      <value value="8.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-initial-work">
      <value value="10.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-div">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-start">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-add">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-values">
      <value value="&quot;sensitivity&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a">
      <value value="0"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd_income">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-care">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-id">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="equal-conv-param?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-condition">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-work">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-stw-m">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-work">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-id">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-random-seed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="output-agents">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemployed-f">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-end">
      <value value="280"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-historical-norm">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-structure">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-households">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-rel-income">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="add-care" first="0" step="1" last="10"/>
    <enumeratedValueSet variable="th-work-change">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-limit">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hours">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-hist-norm">
      <value value="0"/>
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
