
[1mFrom:[0m /home/slp/vish/lib/ve_to_ediphy.rb @ line 538 VETOEDIPHY.create_exercises:

    [1;34m535[0m: [32mdef[0m [1;36mself[0m.[1;34mcreate_exercises[0m(excursion_json, nav_names, cv_names, plugin_toolbars_by_id, answers)
    [1;34m536[0m:   exercises = {}
    [1;34m537[0m:    views = nav_names.merge(cv_names)
 => [1;34m538[0m:    binding.pry
    [1;34m539[0m:    views.each [32mdo[0m|key, boxes|
    [1;34m540[0m:     ex_boxes = {}
    [1;34m541[0m:     boxes.each [32mdo[0m |box|
    [1;34m542[0m:       [32mif[0m !box.nil?
    [1;34m543[0m:        plugin = plugin_toolbars_by_id[box]
    [1;34m544[0m:        [32mif[0m  [[31m[1;31m"[0m[31mMultipleChoice[1;31m"[0m[31m[0m, [31m[1;31m"[0m[31mMultipleAnswer[1;31m"[0m[31m[0m, [31m[1;31m"[0m[31mInputText[1;31m"[0m[31m[0m, [31m[1;31m"[0m[31mOrdering[1;31m"[0m[31m[0m, [31m[1;31m"[0m[31mScormPackage[1;31m"[0m[31m[0m, [31m[1;31m"[0m[31mFreeResponse[1;31m"[0m[31m[0m, [31m[1;31m"[0m[31mTrueFalse[1;31m"[0m[31m[0m].include? plugin[[31m[1;31m"[0m[31mpluginId[1;31m"[0m[31m[0m]
    [1;34m545[0m:          ex_boxes[box] = create_exercise( plugin[[31m[1;31m"[0m[31mpluginId[1;31m"[0m[31m[0m], box, answers[box] )
    [1;34m546[0m:        [32mend[0m
    [1;34m547[0m:       [32mend[0m
    [1;34m548[0m:     [32mend[0m
    [1;34m549[0m:     exercises[key] =  {
    [1;34m550[0m:         [31m[1;31m"[0m[31mid[1;31m"[0m[31m[0m => key,
    [1;34m551[0m:         [31m[1;31m"[0m[31msubmitButton[1;31m"[0m[31m[0m => [1;36mtrue[0m,
    [1;34m552[0m:         [31m[1;31m"[0m[31mtrackProgress[1;31m"[0m[31m[0m => [1;36mfalse[0m,
    [1;34m553[0m:         [31m[1;31m"[0m[31mattempted[1;31m"[0m[31m[0m => [1;36mfalse[0m,
    [1;34m554[0m:         [31m[1;31m"[0m[31mweight[1;31m"[0m[31m[0m => [1;34m10[0m,
    [1;34m555[0m:         [31m[1;31m"[0m[31mminForPass[1;31m"[0m[31m[0m => [1;34m50[0m,
    [1;34m556[0m:         [31m[1;31m"[0m[31mexercises[1;31m"[0m[31m[0m => ex_boxes,
    [1;34m557[0m:         [31m[1;31m"[0m[31mscore[1;31m"[0m[31m[0m => [1;34m0[0m,
    [1;34m558[0m:     }
    [1;34m559[0m:   [32mend[0m
    [1;34m560[0m:   exercises
    [1;34m561[0m: [32mend[0m

