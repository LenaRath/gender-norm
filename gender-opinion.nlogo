extensions [matrix nw]

breed [women woman]
breed [men man]

globals[
  num-links
  random-network-prob
  watts-strogatz-neighbors
  watts-strogatz-rewiring
  preferential-attachment-min-degree
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
  jobs
]



turtles-own[
  spouse               ; turtles spouse
  gender-identity      ; ;describes in the opinion of this household the optimal division of care work   (0...man should do everything, 1..woman should do everything)
  fix?                 ;some do not change their gender identity
  care            ;a tuple that stores the hours spend for care work for f and m
  work            ;a tuple that stores the hours spend for paid work for f and m
  unemployed?      ;a tuple that stores wheter the woman or the man of this houshold is unemployed
  lockdown-work    ;a tuple that stores the hours for paid work for f and m
  care-history         ;save care-division
  identity-history     ;matrix with historical identity values in two columns: f and m
  work-history         ;matrix with historical identity values in two columns: f and m
  work-div             ;share of  paid work hours done by woman                                      (1...man single earner, 0 ... woman single earner)
  household-care        ;overall care work workload in this houshold
  lockdown-household-care
  hh-income            ;; household-income
  eps
  n                   ;social norm of social group (friends)
  lockdown-hours      ;sum of hours care work and paid work during lockdown (increases hours by random value)
  ;paygap              ;how much in relation to the man does the woman of this household earn
  income              ;income of this household
  friends
]


to setup
  clear-all
  if use-random-seed? [random-seed seed]
  set-initial-values
  set lockdown? false
  set-default-shape turtles "circle"

   ;create and link women with other women, men with other men
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
  if network-structure = "preferential-attachment"
  [
    nw:generate-preferential-attachment men links number-of-households preferential-attachment-min-degree
    nw:generate-preferential-attachment women links number-of-households preferential-attachment-min-degree
  ]

  layout-circle men 15
  layout-circle women 15

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
  ask turtles [
    set household-care care + [care] of spouse
    set lockdown-household-care household-care + add-care
    set lockdown-hours hours
  ]
 set jobs 0

  ask n-of (fix * count turtles / 100 ) turtles
  [
    set fix? true
  ]

  if equal-conv-param? [
    set b a
    set c a
    set d a
  ]

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

to setup-women
  set shape "triangle"
  set xcor xcor - 15
  set-confidence-bounds

  ;gender identity
  set gender-identity in-bounds(random-normal initial-identity 0.2)
  set identity-history n-values history-length-norm [gender-identity]

  set income 1 ;max list 0 random-normal mean-paygap 0.2                      ;income trotz unemployed?????????

  ;work
  set work in-work(random-normal mean-work-f 5)
  set unemployed? false
  if (random-float 100 < unemployed-f) [
    set unemployed? true
    set work 0
  ]
  set work-history n-values history-length-work [work]

  ;care
  set care in-hours(random-normal (mean-care-f) 5)
  set care-history n-values history-length-care [care]

end

to setup-men
  set shape "square"
  set xcor xcor + 15
  set-confidence-bounds

  ; gender identity
   set gender-identity in-bounds(random-normal initial-identity 0.2)
  set identity-history n-values history-length-norm [gender-identity]
;  set gender-identity [gender-identity] of spouse
;  set identity-history n-values history-length-norm [gender-identity]

  set income 1

  ;work
  set work in-work(random-normal mean-work-m 5)
  set unemployed? false
  if (random-float 100 < unemployed-m) [
    set unemployed? true
    set work 0
  ]
  set work-history n-values history-length-work [work]

  ;care
  set care in-hours(random-normal (mean-care-m) 5)
  set care-history n-values history-length-care [care]

end

to set-initial-values
  set random-network-prob 0.02
  set watts-strogatz-neighbors 2
  set watts-strogatz-rewiring 0.04
  set preferential-attachment-min-degree 2

  (ifelse initial-values = "de" [
    set mean-care-f 3.8 * 7
    set mean-care-m 2.4 * 7
    set mean-work-f 4.43 * 7
    set mean-work-m 5.58 * 7
    set unemployed-f 5.2
    set unemployed-m 4.7
    ]
    initial-values = "us" [
      set mean-care-f 1.21 * 7
    set mean-care-m 2.4 * 7
    set mean-work-f 7.8 * 7
    set mean-work-m 8.65 * 7
      set unemployed-f 3.8
      set unemployed-m 3.7
    ]
    initial-values = "equal" [
    set mean-care-f 3 * 7
    set mean-care-m 3 * 7
    set mean-work-f 5 * 7
    set mean-work-m 5 * 7
    set unemployed-f 4.5
    set unemployed-m 4.5
    set mean-paygap 1
    ]
  )
  set history-length-norm 1
  set history-length-care 3
  set history-length-work 3
  set th-work-change 0.2
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
    update-norm-new
    set-care-new
    update-work-new
    update-work-friends-new
    update-colors
  ]

  if output-agents = true
  [
    print_agents
  ]
  tick
end

to-report difference   ;squared differences -> least squares problem  --> normieren auf 1 (sonst wirken parameter mit größerem wertebereich stärker)
  report mean (list (mean [work] of women - mean-work-f)(mean [care] of women - mean-care-f)(mean [work] of men - mean-work-m)(mean [care] of men - mean-care-m))

end

to set-confidence-bounds
    let x random-gamma 2.6 1
    set eps ( x / ( x + random-gamma 1.8 1) ) ;; set eps a random number from division Beta(alpha,beta) (between 0 and 1)
    set eps 0 + (eps * (0.18 - 0)) ;; scale and shift eps to lie between min_eps and max_eps: set eps eps min_eps + (eps * (max_eps - min_eps))
end


to start-lockdown
  ask n-of (count women * 0.15) women
    [set jobs jobs - work
     set work 0
  ]
  ask n-of (count men * (percent-men-home / 100)) men [
    set jobs jobs - work
    set work 0
  ]
end

to update-work-new
  let old-work mean work-history
  set work-div 0.5
  let potential work
  let hh-work work + [work] of spouse
  let ideal-work ifelse-value (breed = women) [hh-work * ( 1 - gender-identity)][hh-work * gender-identity]
  let n-work ideal-work
   ifelse (count friends > 0)
      [ set n-work (mean [work] of friends) ]
      [ set n-work old-work ]
  set hh-income (income * work) + ([income * work] of spouse)
  if (hh-work > 0) [set work-div ifelse-value (breed = women) [[work] of spouse / hh-work][ work / hh-work]] ;1 -> man single earner, 0 -> woman single earner
  ifelse(lockdown?)
    [
      set potential in-work(lockdown-hours - (lockdown-household-care - mean [care-history] of spouse))
    ][
      set potential in-work(hours - (household-care - mean [care-history] of spouse))
    ]
  set potential in-hours( potential - a * (potential - n-work) - b * (potential - ideal-work) )
  let potential-income  ((potential * income)  + [work * income] of spouse)         ;what the household may earn if they choose the new division
  let potential-div 0.5
  if (potential + [work] of spouse > 0) [set potential-div ifelse-value (breed = women) [ [work] of spouse / ([work] of spouse + potential) ][potential / (potential + [work] of spouse) ]]
  ;; check deviation of potential work division from gender idenity and prevent income loss:
  if(abs(potential-div - mean identity-history) < abs(work-div - mean identity-history) and potential-income >= income * 0.9 )[
   set work available-jobs potential work
    ]
  set work-history lput work butfirst work-history
end


to update-work-friends-new
   ;;; someone from social group has higher income
  if(count friends > 0)[
    let n-income mean  [hh-income] of friends
    let potential work
    if (n-income > 1.2 * hh-income) [
      if (income > [income] of spouse)[
         ifelse(lockdown?)
         [
           set potential in-work(work + random-float (lockdown-hours - (lockdown-household-care - mean [care-history] of spouse) - work))
         ][
           set potential in-work(work + random-float (hours - (household-care - mean [care-history] of spouse) - work))
         ]
             set work available-jobs potential work
      ]
;        [
;        ask spouse [
;          let potential in-work(work + random-float (hours - care))
;          set work available-jobs potential work
;        ]
;      ]
    ]
  ]
end

to-report available-jobs [potential current-work]
   let diff current-work - potential  ; (negativ wenn studen erhöht, also von jobs  abziehen; positiv wenn stunden frei werden also zu jobs dazu zählen)
      ifelse(diff >= 0)
      [ ;; stunden reduziert; neue jobs frei
        set jobs jobs + diff
        report potential
      ]
      [ ;; diff < 0 --> stunden erhöht, weniger freie jobs
        ifelse (jobs > (- diff))
        [ ;; es gibt genug jobs
          set jobs jobs + diff
          report potential
        ] ;; es sind nicht genug jobs
        [let remaining jobs
         set jobs 0
         report current-work + remaining
         ]
      ]
end

to update-norm-new
   let old-gender-identity mean identity-history
   set friends link-neighbors with [(abs (gender-identity - [gender-identity] of myself) < eps)]  ; confidence bound
   let cogn-diss 0
   let household-work work + [work] of spouse
   if breed = women [
    ifelse (household-care > 0)[
      ifelse(household-work > 0)
      [set cogn-diss old-gender-identity - mean list (care / household-care)([work] of spouse / household-work)]
      [set cogn-diss old-gender-identity - mean list (care / household-care)(0.5)]      ;both do not work: share work hours equally
    ][
      ifelse(household-work > 0)
      [set cogn-diss old-gender-identity - mean list 0.5 ([work] of spouse / household-work)]
      [set cogn-diss old-gender-identity - 0.5]
    ]
    ifelse (count friends > 0)
      [ set n (mean [gender-identity] of friends) ]
      [ set n old-gender-identity ]
      set old-gender-identity in-bounds( old-gender-identity - a * (old-gender-identity - n) - b * cogn-diss)
                                                           ; social control                   ; cognitive dissonance
      set gender-identity mean list mean identity-history old-gender-identity
   set identity-history lput old-gender-identity butfirst identity-history
  ]
   ;ask spouse [set gender-identity [gender-identity] of myself]
  if breed = men [
    ifelse (household-care > 0)[
      ifelse(household-work > 0)
      [set cogn-diss old-gender-identity - mean list ([care] of spouse / household-care)(work / household-work)]
      [set cogn-diss old-gender-identity - mean list ([care] of spouse / household-care)(0.5)]      ;both do not work: share work hours equally
    ][
      ifelse(household-work > 0)
      [set cogn-diss old-gender-identity - mean list 0.5 (work / household-work)]
      [set cogn-diss old-gender-identity - 0.5]
    ]
    ifelse (count friends > 0)
      [ set n (mean [gender-identity] of friends) ]
      [ set n old-gender-identity ]
      set old-gender-identity in-bounds( old-gender-identity - a * (old-gender-identity - n) - b * cogn-diss)
                                                           ; social control                   ; cognitive dissonance
      set gender-identity mean list mean identity-history old-gender-identity
   set identity-history lput old-gender-identity butfirst identity-history
  ]
end

to set-care-new
  set care mean care-history
  let ideal hours
  ifelse lockdown? [
    set ideal ifelse-value (breed = women) [(lockdown-household-care * gender-identity)][(lockdown-household-care * (1 - gender-identity))] ;care division according to gender identity
  ][
    set ideal ifelse-value (breed = women) [(household-care * gender-identity)][(household-care * (1 - gender-identity))]
  ]
  set n ideal
  if count friends > 0 [
    set n (mean [care] of friends)
  ]
  set care in-hours( care - a * (care - n) - b * (care - ideal) )
  set care-history lput care butfirst care-history
end

to update-colors
  set color scale-color red gender-identity 0 1
  if (work < 0.5 and [work] of spouse > 1) [set color yellow]
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
  [ set unemployed? true
    report 0]
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
    file-print (word who "," breed "," initial-identity "," care " ,"work "," gender-identity "," ticks ",")
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
1021
10
1798
410
-1
-1
12.613
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
227
117
number-of-households
number-of-households
1
1000
440.0
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
"n-f" 0.01 1 -16777216 true "" "histogram [gender-identity] of women"
"n-m" 0.01 1 -1184463 true "" "histogram [gender-identity] of men"
"div" 0.01 1 -7500403 true "" "histogram [care / household-care ] of women"

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
"care f" 1.0 0 -16050907 true "" "plot mean([care] of women)"
"work f" 1.0 0 -10899396 true "" "plot mean([work] of women)"
"care m" 1.0 0 -1184463 true "" "plot mean([care] of men)"
"work m" 1.0 0 -5825686 true "" "plot mean ([work] of men)"

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
-10.0
50.0
0.0
15.0
true
true
"set-histogram-num-bars 100" ""
PENS
"care f" 0.1 1 -16777216 true "" "histogram [care] of women"
"care m" 0.1 1 -1184463 true "" "histogram [care] of men"

SLIDER
11
185
183
218
a
a
0
0.5
0.25
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
0.25
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
0.25
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
0.25
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
344
167
516
200
percent-men-home
percent-men-home
0
100
0.0
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
"work-f" 0.1 1 -16777216 true "" "histogram [work] of women"
"work-m" 0.1 1 -1184463 true "" "histogram [work] of men"

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
"gender-identity" 1.0 0 -2674135 true "" "plot mean  [gender-identity] of women"
"work-division (only employed)" 1.0 0 -14439633 true "" "plot mean [work / ( work + [work] of spouse )] of men with [not unemployed?]"
"care-division" 1.0 0 -14070903 true "" "plot mean [care / (care + [care] of spouse )] of women\n"

OUTPUT
1293
572
1710
721
11

CHOOSER
210
14
390
59
network-structure
network-structure
"random" "preferential attachment" "small world"
0

MONITOR
759
330
977
375
NIL
mean [work] of men
17
1
11

PLOT
1644
562
1809
686
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
"average income" 1.0 0 -16777216 true "" "plot mean [income * work] of turtles"

SLIDER
8
399
180
432
initial-identity
initial-identity
0
1
0.5
0.05
1
NIL
HORIZONTAL

PLOT
1645
431
1805
551
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
"default" 1.0 0 -16777216 true "" "plot sum [care] of turtles"

SLIDER
43
456
215
489
fix
fix
0
100
0.0
1
1
%
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
69.0
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
500.0
1
0
Number

INPUTBOX
438
253
488
313
ld-end
700.0
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
30
13.6
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
45.0
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
200.0
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
1.0
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
44
125
184
158
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
196
125
334
170
initial-values
initial-values
"de" "us" "equal"
2

PLOT
524
369
724
519
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

PLOT
759
382
959
532
Jobs
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
"default" 1.0 0 -16777216 true "" "plot jobs + sum [work] of turtles"

MONITOR
1009
434
1351
479
NIL
count women with [work < 0.5 and [work] of spouse > 0.5]
17
1
11

MONITOR
1010
488
1336
533
NIL
count men with [work < 0.5 and [work] of spouse > 0.5]
17
1
11

SWITCH
363
62
511
95
use-random-seed?
use-random-seed?
0
1
-1000

SWITCH
363
104
512
137
equal-conv-param?
equal-conv-param?
0
1
-1000

MONITOR
788
378
939
423
NIL
mean [work] of women
17
1
11

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
  <experiment name="experiment-where are the results" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="499"/>
    <metric>difference</metric>
    <metric>mean [care] of women</metric>
    <metric>mean [care] of men</metric>
    <metric>mean [work] of women</metric>
    <metric>mean [work] of men</metric>
    <enumeratedValueSet variable="ld-start">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-identity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <steppedValueSet variable="max-work" first="30" step="1" last="45"/>
    <steppedValueSet variable="seed" first="1" step="1" last="10"/>
    <enumeratedValueSet variable="initial-values">
      <value value="&quot;us&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a">
      <value value="0.07"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-paygap">
      <value value="0.83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b">
      <value value="0.12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="output-agents">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.09"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-end">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d">
      <value value="0.28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockdown?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-structure">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-households">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fix">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="add-care">
      <value value="13.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-men-home">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="hours" first="30" step="5" last="70"/>
  </experiment>
  <experiment name="experiment-equal-ic" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="400"/>
    <metric>mean [care] of women</metric>
    <metric>mean [care] of men</metric>
    <metric>mean [work] of women</metric>
    <metric>mean [work] of men</metric>
    <enumeratedValueSet variable="ld-start">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-identity">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-work">
      <value value="45"/>
    </enumeratedValueSet>
    <steppedValueSet variable="seed" first="100" step="1" last="200"/>
    <enumeratedValueSet variable="initial-values">
      <value value="&quot;equal&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="a" first="0.05" step="0.05" last="0.4"/>
    <enumeratedValueSet variable="use-random-seed?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-paygap">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="output-agents">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ld-end">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d">
      <value value="0.37"/>
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
    <enumeratedValueSet variable="fix">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="add-care">
      <value value="13.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-men-home">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hours">
      <value value="69"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="equal-conv-param?">
      <value value="true"/>
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
