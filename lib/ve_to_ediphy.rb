class VETOEDIPHY

 def self.transpile(vish_excursion_json)
   excursion_json = JSON.parse(vish_excursion_json)
   names = self.generateNames(excursion_json)
   boxes_by_id = self.create_boxes(excursion_json, names["navs_names"], names["navs_boxes"], names["templates"], names["plugins"])
   nav_items_by_id = self.create_navitemsbyid(excursion_json, names["navs_names"], names["navs_boxes"])
   nav_items_ids = self.create_navitemsids(names["navs_names"])
   navItemSelected = names["navs_names"].values[0] # TODO Comprobar que hay al menos una slide
   view_toolbars_by_id = self.create_viewtoolbars(excursion_json, names["navs_names"])
   plugin_toolbars_by_id = self.create_plugintoolbars(excursion_json, names["navs_boxes"], names["templates"], names["plugins"])
   global_config = self.create_global_config(excursion_json)
   marks_by_id = self.create_marks(excursion_json)
   exercises = self.create_exercises(excursion_json, names["navs_boxes"])

   {
       "present" => {
           "version"=> "2",
           "lastActionDispatched" => "@@INIT",
           "globalConfig" => global_config,
           "displayMode"=> "list",
           "indexSelected"=> -1,
           "navItemsById"=> nav_items_by_id,
           "navItemsIds"=> nav_items_ids,
           "navItemSelected" => navItemSelected,
           "marksById" => marks_by_id,
           "boxesById" => boxes_by_id,
           "viewToolbarsById" => view_toolbars_by_id,
           "pluginToolbarsById" => plugin_toolbars_by_id,
           "exercises" => exercises,
           "isBusy" => "",
       }
   }.to_json
 end

 ## Global Config TODO Finish all metadata
 def self.create_global_config(excursion_json)
   {
       "title" => excursion_json["title"],
       "author" => excursion_json["author"]["name"],
       "canvasRatio" => "1.3333333333333333",
       "visorNav" => {
           "player" => true,
           "sidebar" => true,
           "keyBindings" => true
       },
       "trackProgress" => true,
       "age" => {
           "min" => 0,
           "max" => 0
       },
       "keywords" => excursion_json["tags"],
       "typicalLearningTime" => {
           "h" => 0,
           "m" => 0,
           "s" => 0
       },
       "version" => '1.0.0',
       "thumbnail" => excursion_json["avatar"],
       "status" => 'draft',
       "structure" => 'linear',
       "difficulty" => 'easy'
   }
 end

 ## Nav Items
 def self.generateNavItemName(i)
   'pa-' + Time.now.to_i.to_s + i.to_s
 end
 def self.generateBoxName(p,i)
   'bo-' + Time.now.to_i.to_s + '_'+ p.to_s + '_'+ i.to_s
 end
 def self.generateNames(excursion_json)
   navs_boxes = {}
   names = {}
   templates = {}
   plugins = {}
   excursion_json["slides"].each_with_index  do |slide, p|
     name = generateNavItemName(p)
     names[slide["id"]] = name
     navs_boxes[name] = []
     templates[name] = slide["template"]
     slide["elements"].each_with_index   do |element, i|
       box = self.generateBoxName(p,i)
       plugins[box] = {"type" => element["type"], "body" => element["body"], "style" => element["style"], "sources" => element["sources"]}
       if plugins[box]["type"]
         navs_boxes[name].push(box)
       end
     end
   end
   { "navs_boxes" => navs_boxes, "navs_names" => names, "templates" => templates, "plugins" => plugins}
 end
 def self.create_navitemsids(names)
   names.values
 end
 def self.create_navitem(id, boxes)
     {
        "id" => id,
        "isExpanded" => true,
        "parent" => 0,
        "linkedBoxes" => {},
        "children" => [],
        "boxes" => boxes,
        "level" => 1,
        "type" => "slide",
        "hidden" => false,
        "extraFiles" => {},
        "customSize" => 0
     }
 end
 def self.create_navitemsbyid(excursion_json, names, boxes_names)
   navs = {}
   names.values.each do |slide|
     boxes = boxes_names[slide]
     navs[slide] = self.create_navitem(slide, boxes)
   end
   navs["0"] = { "id"=> 0, "children"=> names.values, "boxes"=> [], "level"=> 0, "type"=> '', "hidden"=> false }
   navs
 end
 def self.create_viewtoolbar(id,number)
   {
       "id" => id,
       "viewName" => 'Slide ' + number.to_s,
       "breadcrumb" => 'hidden',
       "courseTitle" => 'hidden',
       "documentSubtitle" => 'hidden',
       "documentSubtitleContent" => '',
       "documentTitle" => 'hidden',
       "documentTitleContent" => "",
       "numPage" => 'hidden',
       "numPageContent" => '',
       "background" => "#ffffff",
       "backgroundAttr" => "",
       "aspectRatio" => ""
   }
 end
 def self.create_viewtoolbars(excursion_json, names)
   navs = {}
   names.values.each_with_index do |slide, i|
     navs[slide] = self.create_viewtoolbar(slide, i+1)
   end
   navs
 end

 def self.create_plugintoolbar(box, template_box, plugin, box_shape)
   plugin_template = self.convert_plugin(plugin)
   {
     "id" => box,
     "pluginId" => plugin_template["pluginId"],
     "state" => plugin_template["state"],
     "structure" => {
         "height" => template_box["height"],
         "width" => template_box["width"],
         "widthUnit" => "%",
         "heightUnit" => "%",
         "rotation" => 0,
         "aspectRatio" => false,
         "position" => "absolute",
     },
     "style" => { # TODO Poner solo las styles que son en cada plugin
         # "padding" => 0,
         # "backgroundColor" => "#ffffff",
         "borderWidth" => 0,
         "borderStyle" => "solid",
         "borderColor" => "#000000",
         "borderRadius" => box_shape.match("circle") ? "50%": "0",
         "opacity" => 1,
     },
     "showTextEditor" => false,

 }
 end
 def self.create_plugintoolbars(excursion_json, boxes_names, templates, plugins)
   boxes = {}
   boxes_names.each do|key, boxes_ids|
     template_slide = template(templates[key])["elements"]
     boxes_ids.each_with_index do |box, index|
       box_shape = template_slide.keys[index]
       template_box = template_slide[box_shape]
       boxes[box] = self.create_plugintoolbar(box, template_box, plugins[box], box_shape)
     end
   end
   boxes
 end
 def self.create_box(box, parent, template_box, plugin)
   {
        "id" => box,
        "parent" => parent,
        "container" => 0,
        "level" => 0,
        "col" => 0,
        "row" => 0,
        "position" => {
            "x" => template_box["x"]+"%",
            "y" => template_box["y"]+"%",
            "type" => "absolute",
        },
        "content" => { },
        "draggable" => true,
        "resizable" => true,
        "showTextEditor" => false,
        "fragment" => {},
        "children" => [],
        "sortableContainers" => {},
        "containedViews" => [ ]
   }
 end
 def self.create_boxes(excursion_json, nav_names, boxes_names, templates, plugins)
   boxes = {}
   boxes_names.each do|key, boxes_ids|
     template_slide = template(templates[key])["elements"]
     boxes_ids.each_with_index do |box, index|
       template_box = template_slide[template_slide.keys[index]]
       boxes[box] = self.create_box(box, key, template_box, plugins[box])
     end
   end
   boxes
 end

 def self.convert_px_to_em(num)
   result = num.delete("px").to_f
   default_font_base = 14
   default_width_base = 1100
   calculatedFontSize = default_font_base * (798) / default_width_base  #px/em in ViSH
   result = result / calculatedFontSize
   result.round(2).to_s + "em"
 end
 def self.convert_plugin(plugin_template)
   require 'uri'
   pluginId = ""
   state = {}
   case plugin_template["type"]
     when "image"
       pluginId = "HotspotImages"
       state = { "url" => plugin_template["body"] }
     when "text"
       pluginId = "BasicText"
       text = plugin_template["body"]
       result = text.gsub(/([0-9]\d*(\.\d+)?)px/) { |num| (self.convert_px_to_em(num))}
       state = { "__text" =>   URI::encode("<div>"+ URI::decode(result)+"</div>").gsub(/%23/,'#') }
     when "object"
       if (plugin_template["body"].match("youtube"))
         pluginId = "EnrichedPlayer"
         url = plugin_template["body"].match("src=\\\"(.+?)\\\"")
         state = { "url" => (url && url[1]) ? url[1] : "", "controls" => true}
       elsif (plugin_template["body"].match("\.pdf\\\""))
         pluginId = "EnrichedPDF"
         url = plugin_template["body"].match("src=\\\"(.+?)\\\"")
         state = { "url" => (url && url[1]) ? url[1] : "", "numPages" => nil, "pageNumber" => "1"}
       elsif (plugin_template["body"].match("scorm"))
         pluginId = "ScormPackage"
         url = plugin_template["body"].match("src=\\\"(.+?)\\\"")
         state = { "url" => (url && url[1]) ? url[1] : ""}
       elsif (plugin_template["body"].match("\\u003Cembed"))
         pluginId = "FlashObject"
         url = plugin_template["body"].match("src=\\\"(.+?)\\\"")
         state = { "url" => (url && url[1]) ? url[1] : ""}
       else
         pluginId = "Webpage"
         url = plugin_template["body"].match("src=\\\"(.+?)\\\"")
         state = { "url" => (url && url[1]) ? url[1] : "" }
       end
     when "audio"
       pluginId = "EnrichedAudio"
       url = plugin_template["sources"].match("src\\\":\\\"(.*?)\\\"")
       state = { "url" => (url && url[1]) ? url[1] : "", "auoplay" => false, "controls" => true, "waves" => true, "barWidth" => 2, "progressColor" => "#ccc", "waveColor" => "#178582", "scroll" => false}
     when "video"
       pluginId = "EnrichedPlayer"
       url = plugin_template["sources"].match("src\\\":\\\"(.*?)\\\"")
       state = { "url" => (url && url[1]) ? url[1] : "", "controls" => true}
     else
       pluginId = "HotspotImages"
       state = { "url" => "https://via.placeholder.com/350x150" }
     end
     { "pluginId" => pluginId, "state" => state }
 end

 ## Rich plugins & contained views
 def self.create_marks(excursion_json)
  {}
 end
 def self.create_containedviews(excursion_json)
  {}
 end

 ## Exercises
 def self.create_exercises(excursion_json, boxes_names)
   exercises = {}
   boxes_names.each do|key, boxes|
     exercises[key] =  {
         "id" => key,
         "submitButton" => true,
         "trackProgress" => false,
         "attempted" => false,
         "weight" => 10,
         "minForPass" => 50,
         "exercises" => {},
         "score" => 0,
     }
   end
   exercises
 end
  def self.template(id)
    templates = {
        "t1" => {
            "elements" => {
                "left" => {
                    "x" => "20",
                    "y" => "5",
                    "width" => "60",
                    "height" => "66"
                },
                "header" => {
                    "x" => "20",
                    "y" => "74",
                    "width" => "60",
                    "height" => "13"
                },
                "subheader" => {
                    "x" => "20",
                    "y" => "89.5",
                    "width" => "60",
                    "height" => "5.5"
                },
            }
        },
        "t2" => {
            "elements" => {
                "left" => {
                    "x" => "5",
                    "y" => "5",
                    "width" => "90",
                    "height" => "90"
                },
            }
        },
        "t3" => {
            "elements" => {
                "header" => {
                    "x" => "5",
                    "y" => "5",
                    "width" => "90",
                    "height" => "9",
                },
                "left" => {
                    "x" => "5",
                    "y" => "16",
                    "width" => "90",
                    "height" => "78",
                },

            }
        },
        "t4" => {
            "elements" => {
                "header" => {
                    "x" => "5",
                    "y" => "5",
                    "width" => "90",
                    "height" => "9",
                },
                "left" => {
                    "x" => "5",
                    "y" => "16",
                    "width" => "90",
                    "height" => "59",
                },
                "right" => {
                    "x" => "5",
                    "y" => "77",
                    "width" => "90",
                    "height" => "21.2",
                }
            }
        },
        "t5" => {
            "elements" => {
                "header" => {
                    "x" => "5",
                    "y" => "5",
                    "width" => "90",
                    "height" => "9",
                },
                "left" => {
                    "x" => "5",
                    "y" => "16",
                    "width" => "44",
                    "height" => "78",
                },
                "right" => {
                    "x" => "50.5",
                    "y" => "16",
                    "width" => "44",
                    "height" => "78",
                },
            }
        },
        "t17" => {
            "elements" => {
                "header" => {
                    "x" => "5",
                    "y" => "5",
                    "width" => "90",
                    "height" => "9",
                },
                "left" => {
                    "x" => "5",
                    "y" => "16",
                    "width" => "56.6",
                    "height" => "78",
                },
                "right" => {
                    "x" => "64",
                    "y" => "16",
                    "width" => "31",
                    "height" => "78",
                },
            }
        },
        "t16" => {
            "elements" => {
                "header" => {
                    "x" => "5",
                    "y" => "5",
                    "width" => "90",
                    "height" => "9",
                },
                "left" => {
                    "x" => "5",
                    "y" => "16",
                    "width" => "30",
                    "height" => "78",
                },
                "right" => {
                    "x" => "36.5",
                    "y" => "16",
                    "width" => "58.5",
                    "height" => "78",
                },
            }
        },
        "t20" => {
            "elements" => {
                "header" => {
                    "x" => "5",
                    "y" => "5",
                    "width" => "90",
                    "height" => "9",
                },
                "left" => {
                    "x" => "5",
                    "y" => "16",
                    "width" => "58",
                    "height" => "78",
                },
                "right1" => {
                    "x" => "65",
                    "y" => "16",
                    "width" => "30",
                    "height" => "37",
                },
                "right2" => {
                    "x" => "65",
                    "y" => "55",
                    "width" => "30",
                    "height" => "37",
                },
            }
        },
        "t8" => {
            "elements" => {
                "header" => {
                    "x" => "5",
                    "y" => "5",
                    "width" => "90",
                    "height" => "9",
                },
                "left" => {
                    "x" => "5",
                    "y" => "16",
                    "width" => "30",
                    "height" => "37",
                },
                "center" => {
                    "x" => "5",
                    "y" => "55",
                    "width" => "30",
                    "height" => "41.8",
                },
                "right" => {
                    "x" => "37",
                    "y" => "16",
                    "width" => "58",
                    "height" => "81.2",
                },
            }
        },
        "t7" => {
            "elements" => {
                "header" => {
                    "x" => "5",
                    "y" => "5",
                    "width" => "90",
                    "height" => "9",
                },
                "left" => {
                    "x" => "5",
                    "y" => "16",
                    "width" => "30",
                    "height" => "81.2",
                },
                "center" => {
                    "x" => "38",
                    "y" => "16",
                    "width" => "57",
                    "height" => "67",
                },
                "subheader" => {
                    "x" => "38",
                    "y" => "86",
                    "width" => "57",
                    "height" => "11",
                },
            }
        },
        "t6" => {
            "elements" => {
                "header" => {
                    "x" => "5",
                    "y" => "5",
                    "width" => "90",
                    "height" => "9",
                },
                "left" => {
                    "x" => "5",
                    "y" => "16",
                    "width" => "28",
                    "height" => "80",
                },
                "center" => {
                    "x" => "34.5",
                    "y" => "16",
                    "width" => "30.5",
                    "height" => "80",
                },
                "right" => {
                    "x" => "67",
                    "y" => "16",
                    "width" => "28",
                    "height" => "80",
                },
            }
        },
        "t9" => {
            "elements" => {
                "header" => {
                    "x" => "5",
                    "y" => "5",
                    "width" => "90",
                    "height" => "9",
                },
                "left" => {
                    "x" => "5",
                    "y" => "16",
                    "width" => "56",
                    "height" => "37",
                },
                "center" => {
                    "x" => "63.3",
                    "y" => "16",
                    "width" => "30.5",
                    "height" => "80",
                },
                "right" => {
                    "x" => "5",
                    "y" => "55.35",
                    "width" => "56",
                    "height" => "41.5",
                },
            }
        },
        "t12" => {
            "elements" => {
                "left1" => {
                    "x" => "3",
                    "y" => "5",
                    "width" => "45",
                    "height" => "43",
                },
                "right1" => {
                    "x" => "51",
                    "y" => "5",
                    "width" => "45",
                    "height" => "43",
                },
                "left2" => {
                    "x" => "3",
                    "y" => "52",
                    "width" => "45",
                    "height" => "43",
                },
                "right2" => {
                    "x" => "51",
                    "y" => "52",
                    "width" => "45",
                    "height" => "43",
                },
            }
        },
        "t15" => {
            "elements" => {
                "left" => {
                    "x" => "5",
                    "y" => "4",
                    "width" => "27",
                    "height" => "32",
                },
                "center" => {
                    "x" => "36",
                    "y" => "4",
                    "width" => "28",
                    "height" => "32",
                },
                "right" => {
                    "x" => "67",
                    "y" => "4",
                    "width" => "28",
                    "height" =>"32",
                },
                "center2" => {
                    "x" => "5",
                    "y" => "40",
                    "width" => "90",
                    "height" => "55",
                },
            }
        },
        "t11" => {
            "elements" => {
                "center1" => {
                    "x" => "5",
                    "y" => "4",
                    "width" => "90",
                    "height" => "28.4",
                },
                "center2" => {
                    "x" => "5",
                    "y" => "36",
                    "width" => "90",
                    "height" => "28.4",
                },
                "center3" => {
                    "x" => "5",
                    "y" => "68",
                    "width" => "90",
                    "height" => "28.4",
                },
            }
        },
        "t14" => {
            "elements" => {
                "circle1" => {
                    "x" => "5",
                    "y" => "6.35",
                    "width" => "19.8",
                    "height" => "26.4",
                },
                "right1" => {
                    "x" => "29.6",
                    "y" => "6.35",
                    "width" => "64",
                    "height" => "25.7",
                },
                "circle2" => {
                    "x" => "5",
                    "y" => "38.5",
                    "width" => "19.8",
                    "height" => "26.4",
                },
                "right2" => {
                    "x" => "29.6",
                    "y" => "38.5",
                    "width" => "64",
                    "height" => "25.7",
                },
                "circle3" => {
                    "x" => "5",
                    "y" => "70.5",
                    "width" => "19.8",
                    "height" => "26.4",
                },
                "right3" => {
                    "x" => "29.6",
                    "y" => "70.5",
                    "width" => "64",
                    "height" => "25.7",
                },
            }
        },
        "t13" => {
            "elements" => {
                "header" => {
                    "x" => "5",
                    "y" => "4",
                    "width" => "90",
                    "height" => "9.2",
                },
                "circle" => { # TODO De aquí en adelante
                    "x" => "5",
                    "y" => "17",
                    "width" => "43",
                    "height" => "56",
                },
                "left" => {
                    "x" => "52",
                    "y" => "17",
                    "width" => "43.2",
                    "height" => "79",
                },
                "right" => {
                    "x" => "5",
                    "y" => "82.8",
                    "width" => "43.2",
                    "height" => "13.7",
                },
            }
        },
        "t10" => {
            "elements" => {
                "center" => {
                    "x" => "0",
                    "y" => "0",
                    "width" => "100",
                    "height" => "100",
                },
            }
        },
        "t18" => {
            "elements" => {
                "header" => {
                    "x" => "0",
                    "y" => "0",
                    "width" => "100",
                    "height" => "6.35",
                },
                "center" => {
                    "x" => "0",
                    "y" => "6.35",
                    "width" => "100",
                    "height" => "93.65",
                },
            }
        },
        "t19" => {
            "elements" => {
                "header" => {
                    "x" => "0",
                    "y" => "0",
                    "width" => "100",
                    "height" => "6.35",
                },
                "center" => {
                    "x" => "0",
                    "y" => "6.35",
                    "width" => "100",
                    "height" => "87.65",
                },
                "bottom" => {
                    "x" => "0",
                    "y" => "94",
                    "width" =>"100",
                    "height" => "6",
                },
            }
        },

    }

    templates[id]
  end
end